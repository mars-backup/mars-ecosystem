const {
    BN,
    expectRevert,
    expectEvent,
    time,
    constants
} = require('@openzeppelin/test-helpers');
const { expect } = require('chai');
const _ = require('lodash');
const { deploy } = require('./deploy');

const zero = new BN(0);
const one = new BN("1000000000000000000");

function expectBnEqual(a, b) {
    expect(a).to.be.bignumber.equals(b);
}

function expectBnWithin(a, b, decimals) {
    const d = new BN(10).pow(new BN(decimals));
    expect(a.sub(b).abs().lt(d)).to.be.true;
}

contract('BUSDBondingLCurve unit test', function(accounts) {
    const [ owner, minter, feeTo, attacker ] = accounts;
    const fromAttacker = { from: attacker };

    beforeEach(async function() {
        const c = this.contracts = await deploy(accounts);
        this.busdGenesisGroup = c.busdGenesisGroup;
        this.busd = c.busd;
        this.busdBondingLCurve = c.busdBondingLCurve;
        this.usdm = c.usdm;
    });

    describe('getAmountOut', function() {
        it('success', async function() {
            const amountIn = one.muln(10000);
            const amountOut = amountIn
                .mul(new BN('105000000'))
                .div(new BN('100000000'))
                .muln(9990)
                .divn(10000);
            expectBnEqual(await this.busdBondingLCurve.getAmountOut(amountIn), amountOut);            
        });
    });

    describe('getAmountIn', function() {
        it('success', async function() {
            const amountOut = one.muln(10000);
            const amountIn = amountOut
                .mul(new BN('100000000'))
                .muln(10000)
                .div(new BN('105000000'))
                .divn(9990);
            expectBnWithin(
                await this.busdBondingLCurve.getAmountIn(amountOut),
                amountIn,
                10
            );
        });
    });

    describe('purchase', function() {
        const amountIn = one.muln(10000);
        it('postGenesis', async function() {
            await expectRevert(
                this.busdBondingLCurve.purchase(owner, amountIn, 0, 0),
                'CoreRef::postGenesis: Still in genesis period.'
            );
        });

        describe('after launch', function() {
            const amount = one.muln(10000);
            beforeEach(async function() {
                await this.busdGenesisGroup.initGenesis();
                await this.busd.mint(owner, amount);
                await this.busd.approve(this.busdGenesisGroup.address, amount);
                await this.busdGenesisGroup.purchase(owner, amount);
                expectBnEqual(await this.busd.balanceOf(owner), zero);
                expectBnEqual(await this.busdGenesisGroup.balanceOf(owner), amount);

                await time.increase(101);
                const receipt = await this.busdGenesisGroup.launch();
                expectEvent.inLogs(receipt.logs, 'Launch', {});
            });

            it('whenNotPaused', async function() {
                await this.busdBondingLCurve.pause();
                await this.busd.mint(owner, amount);
                await this.busd.approve(this.busdBondingLCurve.address, amount);
                const ts = Date.now();
                await expectRevert(
                    this.busdBondingLCurve.purchase(owner, amount, 0, ts + 100),
                    'Pausable: paused.'
                );
            });

            it('ensure', async function() {
                await expectRevert(
                    this.busdBondingLCurve.purchase(owner, amountIn, 0, 0),
                    'BondingLCurve::ensure: Expired.'
                );
            });
    
            it('purchase: No need BNB', async function() {
                const ts = Date.now();
                await expectRevert(
                    this.busdBondingLCurve.purchase(owner, amountIn, 0, ts + 100, { value: 1 }),
                    'BUSDBondingLCurve::purchase: No need BNB'
                );
            });
    
            it('TransferFrom failed', async function() {
                const ts = Date.now();
                await expectRevert(
                    this.busdBondingLCurve.purchase(owner, one.mul(new BN('100000000')), 0, ts + 100),
                    'ERC20: transfer amount exceeds balance.'
                );
            });
    
            it('Insufficient amount', async function() {
                await this.busd.mint(owner, amount);
                await this.busd.approve(this.busdBondingLCurve.address, amount);
                const ts = Date.now();
                await expectRevert(
                    this.busdBondingLCurve.purchase(owner, amount, one.mul(new BN('100000000')), ts + 100),
                    'BUSDBondingLCurve::purchase: Insufficient amount'
                );
            });
    
            it('success', async function() {
                await this.busd.mint(owner, amount);
                await this.busd.approve(this.busdBondingLCurve.address, amount);
                const _busdBalance = await this.busd.balanceOf(owner);
                const _usdmBalance = await this.usdm.balanceOf(owner);
                const ts = Date.now();
                const amountOut = amount
                    .mul(new BN('105000000'))
                    .div(new BN('100000000'))
                    .muln(9990)
                    .divn(10000);

                const receipt = await this.busdBondingLCurve.purchase(owner, amount, 0, ts + 100);
                expectEvent.inLogs(receipt.logs, 'Purchase', {
                    _to: owner,
                    _amountIn: amount,
                    _amountOut: amountOut
                });
                expectBnEqual(await this.busd.balanceOf(owner), _busdBalance.sub(amount));
                expectBnEqual(await this.usdm.balanceOf(owner), _usdmBalance.add(amountOut));
            });
        });
    });

    describe('allocate', function() {
        it('postGenesis', async function() {
            await expectRevert(
                this.busdBondingLCurve.allocate(),
                'CoreRef::postGenesis: Still in genesis period.'
            );
        });

        describe('after launch', function() {
            const amount = one.muln(10000);
            beforeEach(async function() {
                await this.busdGenesisGroup.initGenesis();
                await this.busd.mint(owner, amount);
                await this.busd.approve(this.busdGenesisGroup.address, amount);
                await this.busdGenesisGroup.purchase(owner, amount);
                expectBnEqual(await this.busd.balanceOf(owner), zero);
                expectBnEqual(await this.busdGenesisGroup.balanceOf(owner), amount);

                await time.increase(101);
                const receipt = await this.busdGenesisGroup.launch();
                expectEvent.inLogs(receipt.logs, 'Launch', {});

                await this.busd.mint(owner, amount);
                await this.busd.approve(this.busdBondingLCurve.address, amount);
                const ts = Date.now();
                await this.busdBondingLCurve.purchase(owner, amount, 0, ts + 100);
            });

            it('Caller is a contract', async function() {
                await expectRevert(
                    this.busdBondingLCurve.allocate({ from: this.busd.address }),
                    'BondingLCurve::allocate: Caller is a contract'
                );
            });

            it('whenNotPaused', async function() {
                await this.busdBondingLCurve.pause();
                await expectRevert(
                    this.busdBondingLCurve.allocate(),
                    'Pausable: paused.'
                );
            });

            it('success', async function() {
                const receipt = await this.busdBondingLCurve.allocate();
                expectEvent.inLogs(receipt.logs, 'Allocate', {
                    _caller: owner,
                    _amount: amount
                });
            });

            it('success with _incentivize reward', async function() {
                await time.increase(3600 * 24 + 100);
                const _usdmBalance = await this.usdm.balanceOf(owner);
                const receipt = await this.busdBondingLCurve.allocate();
                expectEvent.inLogs(receipt.logs, 'Allocate', {
                    _caller: owner,
                    _amount: amount
                });
                expectBnEqual(await this.usdm.balanceOf(owner), _usdmBalance.add(one.muln(10)));
            });
        });
    });
});