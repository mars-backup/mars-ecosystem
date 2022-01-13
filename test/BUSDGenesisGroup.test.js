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

contract('BUSDGenesisGroup unit test', function(accounts) {
    const [ owner, minter, feeTo, attacker ] = accounts;
    const fromAttacker = { from: attacker };

    beforeEach(async function() {
        const c = this.contracts = await deploy(accounts);
        this.busdGenesisGroup = c.busdGenesisGroup;
        this.busd = c.busd;
    });

    describe('purchase', function() {
        it('Time not started', async function() {
            await expectRevert(
                this.busdGenesisGroup.purchase(minter, 100),
                'Time not started'
            );
        });

        it('after launch', async function() {
            const amount = one.muln(10000);
            await this.busdGenesisGroup.initGenesis();
            await this.busd.mint(owner, amount);
            await this.busd.approve(this.busdGenesisGroup.address, amount);
            await this.busdGenesisGroup.purchase(owner, amount);
            expectBnEqual(await this.busd.balanceOf(owner), zero);
            expectBnEqual(await this.busdGenesisGroup.balanceOf(owner), amount);

            await time.increase(101);
            const receipt = await this.busdGenesisGroup.launch();
            expectEvent.inLogs(receipt.logs, 'Launch', {});

            await expectRevert(
                this.busdGenesisGroup.purchase(minter, 100),
                'Timed::duringTime: Time ended.'
            );
        });

        describe('duringTime', function() {
            beforeEach(async function() {
                await this.busdGenesisGroup.initGenesis();
                await this.busd.mint(owner, one.muln(10000));
            });

            it('No need BNB', async function() {
                await expectRevert(
                    this.busdGenesisGroup.purchase(minter, 100, { value: 100 }),
                    'BUSDGenesisGroup::purchase: No need BNB'
                );
            });

            it('No value sent', async function() {
                await expectRevert(
                    this.busdGenesisGroup.purchase(minter, 0),
                    'BUSDGenesisGroup::purchase: No value sent'
                );
            });

            it('transfer amount exceeds balance.', async function() {
                const balance = await this.busd.balanceOf(owner);
                await expectRevert(
                    this.busdGenesisGroup.purchase(minter, balance.addn(1)),
                    'ERC20: transfer amount exceeds balance.'
                );
            });

            it('success', async function() {
                const balance = await this.busd.balanceOf(owner);
                await this.busd.approve(this.busdGenesisGroup.address, balance);
                const old = await this.busdGenesisGroup.balanceOf(minter);
                const receipt = await this.busdGenesisGroup.purchase(minter, balance);
                expectEvent.inLogs(receipt.logs, 'Purchase', {
                    _to: minter,
                    _value: balance
                });
                const after = await this.busdGenesisGroup.balanceOf(minter);
                expectBnEqual(after, old.add(balance));
            });
        });
    });

    describe('redeem', function() {
        const amount = one.muln(10000);
        it('postGenesis', async function() {
            await this.busdGenesisGroup.initGenesis();
            await this.busd.mint(owner, amount);
            await this.busd.approve(this.busdGenesisGroup.address, amount);
            await this.busdGenesisGroup.purchase(owner, amount);
            expectBnEqual(await this.busd.balanceOf(owner), zero);
            expectBnEqual(await this.busdGenesisGroup.balanceOf(owner), amount);

            await expectRevert(
                this.busdGenesisGroup.redeem(owner),
                "CoreRef::postGenesis: Still in genesis period."
            );
        });

        it('success', async function() {
            await this.busdGenesisGroup.initGenesis();
            await this.busd.mint(owner, amount);
            await this.busd.approve(this.busdGenesisGroup.address, amount);
            await this.busdGenesisGroup.purchase(owner, amount);
            expectBnEqual(await this.busd.balanceOf(owner), zero);
            expectBnEqual(await this.busdGenesisGroup.balanceOf(owner), amount);

            await time.increase(101);
            let receipt = await this.busdGenesisGroup.launch();
            expectEvent.inLogs(receipt.logs, 'Launch', {});

            receipt = await this.busdGenesisGroup.redeem(owner);
            expectEvent.inLogs(receipt.logs, 'Redeem', {
                _to: owner,
                _amountIn: amount
            });
        });
    });

    describe('launch', function() {
        const amount = one.muln(10000);
        beforeEach(async function() {
            await this.busdGenesisGroup.initGenesis();
            await this.busd.mint(owner, amount);
            await this.busd.approve(this.busdGenesisGroup.address, amount);
            await this.busdGenesisGroup.purchase(owner, amount);
            expectBnEqual(await this.busd.balanceOf(owner), zero);
            expectBnEqual(await this.busdGenesisGroup.balanceOf(owner), amount);
        });

        it('onlyGovernor', async function() {
            await time.increase(101);
            await expectRevert(
                this.busdGenesisGroup.launch(fromAttacker),
                "CoreRef::onlyGovernor: Caller is not a governor."
            );
        });

        it('afterTime', async function() {
            await expectRevert(
                this.busdGenesisGroup.launch(),
                "Timed::afterTime: Time not ended."
            );
        });

        it('success', async function() {
            await time.increase(101);
            const receipt = await this.busdGenesisGroup.launch();
            expectEvent.inLogs(receipt.logs, 'Launch', {});
        });
    });

    describe('emergencyExit', function() {
        beforeEach(async function() {
            await this.busdGenesisGroup.initGenesis();
        });

        it('Not in exit window', async function() {
            await expectRevert(
                this.busdGenesisGroup.emergencyExit(owner, minter),
                'BUSDGenesisGroup::emergencyExit: Not in exit window'
            );
        });

        describe('in exit window', async function() {
            const amount = one.muln(10000);
            beforeEach(async function() {
                await this.busd.mint(owner, amount);
                await this.busd.approve(this.busdGenesisGroup.address, amount);
                await this.busdGenesisGroup.purchase(owner, amount);
                expectBnEqual(await this.busd.balanceOf(owner), zero);
                expectBnEqual(await this.busdGenesisGroup.balanceOf(owner), amount);
            });

            it('Launch already happened', async function() {
                await time.increase(101);
                const receipt = await this.busdGenesisGroup.launch();
                expectEvent.inLogs(receipt.logs, 'Launch', {});
    
                await time.increase(10 * 24 * 3600);
                await expectRevert(
                    this.busdGenesisGroup.emergencyExit(owner, minter),
                    'BUSDGenesisGroup::emergencyExit: Launch already happened'
                );
            });
    
            it('No MGEN balance', async function() {
                await time.increase(10 * 24 * 3600);
                await expectRevert(
                    this.busdGenesisGroup.emergencyExit(attacker, minter),
                    'BUSDGenesisGroup::emergencyExit: No MGEN balance'
                );
            });
    
            it('Not approved for emergency withdrawal', async function() {
                await time.increase(10 * 24 * 3600);
                await expectRevert(
                    this.busdGenesisGroup.emergencyExit(owner, minter, fromAttacker),
                    'BUSDGenesisGroup::emergencyExit: Not approved for emergency withdrawal'
                );
            });
    
            it('success', async function() {
                await time.increase(10 * 24 * 3600);
                await this.busdGenesisGroup.emergencyExit(owner, minter);
                expectBnEqual(await this.busdGenesisGroup.balanceOf(owner), zero);
                expectBnEqual(await this.busd.balanceOf(minter), amount);
            });
        });
    });

    describe('getAmountsToRedeem', function() {
        it('postGenesis', async function() {
            const amount = one.muln(10000);
            await this.busdGenesisGroup.initGenesis();
            await this.busd.mint(owner, amount);
            await this.busd.approve(this.busdGenesisGroup.address, amount);
            await this.busdGenesisGroup.purchase(owner, amount);
            expectBnEqual(await this.busd.balanceOf(owner), zero);
            expectBnEqual(await this.busdGenesisGroup.balanceOf(owner), amount);

            await expectRevert(
                this.busdGenesisGroup.getAmountsToRedeem(owner),
                "CoreRef::postGenesis: Still in genesis period"
            );
        });

        it('not supersuper', async function() {
            const amount = one.muln(10000);
            await this.busdGenesisGroup.initGenesis();
            await this.busd.mint(owner, amount);
            await this.busd.approve(this.busdGenesisGroup.address, amount);
            await this.busdGenesisGroup.purchase(owner, amount);
            expectBnEqual(await this.busd.balanceOf(owner), zero);
            expectBnEqual(await this.busdGenesisGroup.balanceOf(owner), amount);

            await time.increase(101);
            const receipt = await this.busdGenesisGroup.launch();
            expectEvent.inLogs(receipt.logs, 'Launch', {});

            const { usdmAmount, genesisXMS, busdAmount } = await this.busdGenesisGroup.getAmountsToRedeem(owner);
            expectBnEqual(busdAmount, zero);
            expectBnEqual(usdmAmount, new BN('10489500000000000000000'));
            expectBnEqual(genesisXMS, new BN('1000000000000000000000000'));
        });

        it('supersuper', async function() {
            const amount = one.muln(10000000);
            await this.busdGenesisGroup.initGenesis();
            await this.busd.mint(owner, amount);
            await this.busd.approve(this.busdGenesisGroup.address, amount);
            await this.busdGenesisGroup.purchase(owner, amount);
            expectBnEqual(await this.busd.balanceOf(owner), zero);
            expectBnEqual(await this.busdGenesisGroup.balanceOf(owner), amount);

            const left = one.mul(new BN('500000000')).sub(amount);
            await this.busd.mint(attacker, left);
            await this.busd.approve(this.busdGenesisGroup.address, left, fromAttacker);
            await this.busdGenesisGroup.purchase(attacker, left, fromAttacker);

            await time.increase(101);
            const receipt = await this.busdGenesisGroup.launch();
            expectEvent.inLogs(receipt.logs, 'Launch', {});

            const totalEffectiveMGEN = one.mul(new BN('100000000'))
                .mul(new BN('100000000'))
                .div(new BN('105000000'));

            const usdm = totalEffectiveMGEN
                .mul(new BN('105000000'))
                .div(new BN('100000000'))
                .muln(9990)
                .divn(10000)
                .muln(2)
                .divn(100);

            const busd = one.mul(new BN('500000000'))
                .sub(totalEffectiveMGEN)
                .mul(amount)
                .div(one.mul(new BN('500000000')));

            const { usdmAmount, genesisXMS, busdAmount } = await this.busdGenesisGroup.getAmountsToRedeem(owner);
            expectBnWithin(busdAmount, busd, 10);
            expectBnWithin(usdmAmount, usdm, 10);
            expectBnEqual(genesisXMS, one.muln(20000));
        });
    });

    describe('getAmountOut', function() {
        const amount = one.muln(10000);
        beforeEach(async function() {
            await this.busdGenesisGroup.initGenesis();
            await this.busd.mint(owner, amount);
            await this.busd.approve(this.busdGenesisGroup.address, amount);
            await this.busdGenesisGroup.purchase(owner, amount);
            expectBnEqual(await this.busd.balanceOf(owner), zero);
            expectBnEqual(await this.busdGenesisGroup.balanceOf(owner), amount);
        });

        it('Not enough supply', async function() {
            await expectRevert(
                this.busdGenesisGroup.getAmountOut(amount.addn(1), true),
                'BUSDGenesisGroup::getAmountOut: Not enough supply'
            );
        });

        it('inclusive', async function() {
            const totalUSDM = amount
                .mul(new BN('105000000'))
                .div(new BN('100000000'))
                .muln(9990)
                .divn(10000);
            const totalXMS = one.muln(1000000);
            const { usdmAmount, xmsAmount } = await this.busdGenesisGroup.getAmountOut(amount.divn(2), true);
            expectBnEqual(usdmAmount, totalUSDM.divn(2));
            expectBnEqual(xmsAmount, totalXMS.divn(2));
        });

        it('not inclusive', async function() {
            const totalUSDM = amount
                .muln(2)
                .mul(new BN('105000000'))
                .div(new BN('100000000'))
                .muln(9990)
                .divn(10000);
            const totalXMS = one.muln(1000000);
            const { usdmAmount, xmsAmount } = await this.busdGenesisGroup.getAmountOut(amount, false);
            expectBnEqual(usdmAmount, totalUSDM.divn(2));
            expectBnEqual(xmsAmount, totalXMS.divn(2));
        });
    });
});