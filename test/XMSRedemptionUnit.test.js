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

contract('XMSRedemption unit test', function(accounts) {
    const [ owner, minter, feeTo, attacker ] = accounts;
    const fromAttacker = { from: attacker };

    beforeEach(async function() {
        const c = this.contracts = await deploy(accounts);
        this.busdGenesisGroup = c.busdGenesisGroup;
        this.busd = c.busd;
        this.xmsRedemptionUnit = c.xmsRedemptionUnit;
        this.usdm = c.usdm;
        this.xms = c.xms;
    });

    describe('getCurrentPrice', function() {
        it('success', async function() {
            const [ price ] = await this.xmsRedemptionUnit.getCurrentPrice();
            expectBnEqual(new BN(price), one.muln(5));
        });
    });

    describe('getAmountOut', function() {
        it('success', async function() {
            const amountIn = one.muln(10000);
            expectBnEqual(
                await this.xmsRedemptionUnit.getAmountOut(amountIn),
                amountIn.muln(5).muln(9990).divn(10000)
            );
        });
    });

    describe('getAmountIn', function() {
        it('success', async function() {
            const amountOut = one.muln(10000);
            expectBnEqual(
                await this.xmsRedemptionUnit.getAmountIn(amountOut),
                amountOut.divn(5).muln(10000).divn(9990)
            );
        });
    });

    describe('purchase', function() {
        const amountIn = one.muln(10000);
        it('postGenesis', async function() {
            await expectRevert(
                this.xmsRedemptionUnit.purchase(owner, amountIn, 0, 0),
                "CoreRef::postGenesis: Still in genesis period."
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

                await this.usdm.mint(owner, amount);
                await this.usdm.approve(this.xmsRedemptionUnit.address, amount);
            });

            it('ensure', async function() {
                await expectRevert(
                    this.xmsRedemptionUnit.purchase(owner, amount, 0, 0),
                    'RedemptionUnit::ensure: Expired.'
                );
            });
    
            it('whenNotPaused', async function() {
                await this.xmsRedemptionUnit.pause();
                const ts = Date.now();
                await expectRevert(
                    this.xmsRedemptionUnit.purchase(owner, amount, 0, ts + 100, { value: 1 }),
                    'Pausable: paused.'
                );
            });

            it('XMSRedemptionUnit::purchase: No need BNB', async function() {
                const ts = Date.now();
                await expectRevert(
                    this.xmsRedemptionUnit.purchase(owner, amount, 0, ts + 100, { value: 1 }),
                    'XMSRedemptionUnit::purchase: No need BNB'
                );
            });
    
            it('TransferFrom failed', async function() {
                const ts = Date.now();
                await expectRevert(
                    this.xmsRedemptionUnit.purchase(owner, one.mul(new BN('100000000')), 0, ts + 100),
                    'ERC20: transfer amount exceeds balance.'
                );
            });
    
            it('Insufficient amount', async function() {
                const ts = Date.now();
                await expectRevert(
                    this.xmsRedemptionUnit.purchase(owner, amount, one.mul(new BN('100000000')), ts + 100),
                    'XMSRedemptionUnit::purchase: Insufficient amount'
                );
            });
    
            it('success', async function() {
                const _xmsBalance = await this.xms.balanceOf(owner);
                const _usdmBalance = await this.usdm.balanceOf(owner);
                const ts = Date.now();
                const amountOut = amount
                    .muln(5)
                    .muln(9990)
                    .divn(10000);

                const receipt = await this.xmsRedemptionUnit.purchase(owner, amount, 0, ts + 100);
                expectEvent.inLogs(receipt.logs, 'Purchase', {
                    _to: owner,
                    _amountIn: amount,
                    _amountOut: amountOut
                });
                expectBnEqual(await this.usdm.balanceOf(owner), _usdmBalance.sub(amount));
                expectBnEqual(await this.xms.balanceOf(owner), _xmsBalance.add(amountOut));
            });
        });
    });
});