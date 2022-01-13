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

const XMSToken = artifacts.require('XMSToken');
const zero = new BN(0);
const one = new BN("1000000000000000000");
const PERIOD = 3 * 3600 * 24;

function expectBnEqual(a, b) {
    expect(a).to.be.bignumber.equals(b);
}

function expectBnWithin(a, b, decimals) {
    const d = new BN(10).pow(new BN(decimals));
    expect(a.sub(b).abs().lt(d)).to.be.true;
}

contract('SwapMining unit test', function(accounts) {
    const [ owner, minter, feeTo, attacker ] = accounts;
    const fromAttacker = { from: attacker };

    beforeEach(async function() {
        const c = this.contracts = await deploy(accounts);
        this.busdGenesisGroup = c.busdGenesisGroup;
        this.swapMining = c.swapMining;
        this.busd = c.busd;
        this.usdm = c.usdm;
        this.xms = c.xms;
        this.busd2usdm = c.busd2usdm;
        this.xms2usdm = c.xms2usdm;
        this.swapMiningOracle = c.swapMiningOracle;

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

        await this.swapMiningOracle.addPair(this.busd2usdm);
        await this.swapMiningOracle.addPair(c.xms2usdm);
        await this.swapMining.setRouter(owner);

        await time.increase(100);
    });

    describe('getXMSBlockReward', function() {
        it('success', async function() {
            const _lastRewardBlock = await time.latestBlock();
            await time.advanceBlockTo(_lastRewardBlock.addn(10));
            expectBnEqual(
                await this.swapMining.getXMSBlockReward(_lastRewardBlock),
                one.muln(10)
            )
        });
    });

    describe('swap', function() {
        it('onlyRouter', async function() {
            await this.swapMining.setRouter(minter);
            await expectRevert(
                this.swapMining.swap(
                    minter,
                    this.busd.address,
                    this.usdm.address,
                    one
                ),
                'SwapMining::onlyRouter: Caller is not the router'
            );
        });

        it('success', async function() {
            await this.swapMining.swap(
                minter,
                this.busd.address,
                this.usdm.address,
                one
            );

            const value = new BN('1000000000').div(new BN('30000')).muln(100).divn(105).mul(one);
            const userInfo = await this.swapMining.userInfo(1, minter);
            expectBnWithin(
                value,
                userInfo.quantity,
                20
            );
        });
    });

    describe('withdraw', function() {
        it('success', async function() {
            await this.swapMining.swap(
                minter,
                this.busd.address,
                this.usdm.address,
                one
            );

            const balance = await this.xms.balanceOf(minter);
            const receipt = await this.swapMining.withdraw({ from: minter });
            expectEvent.inLogs(receipt.logs, 'Withdraw', {
                user: minter
            });

            expect(await this.xms.balanceOf(minter)).to.be.bignumber.gt(balance);
        });
    });

    describe('getQuantity', function() {
        it('outputToken == anchorToken', async function() {
            expectBnEqual(
                await this.swapMining.getQuantity(
                    this.xms.address,
                    one,
                    this.xms.address
                ),
                one
            );
        });

        it('busd2usdm', async function() {
            expectBnWithin(
                await this.swapMining.getQuantity(
                    this.busd.address,
                    one,
                    this.usdm.address
                ),
                one.muln(105).divn(100),
                10
            );
        });

        it('xms2usdm', async function() {
            expectBnWithin(
                await this.swapMining.getQuantity(
                    this.xms.address,
                    one,
                    this.usdm.address
                ),
                one.div(new BN('1000000000').div(new BN('30000')).muln(100).divn(105)),
                11
            );
        });

        it('else', async function() {
            expectBnWithin(
                await this.swapMining.getQuantity(
                    this.busd.address,
                    one,
                    this.xms.address
                ),
                one.muln(105).divn(100).mul(new BN('1000000000').div(new BN('30000')).muln(100).divn(105)),
                20
            );
        });
    });

    describe('updateXmsPerBlock', function() {
        it('onlyGovernor', async function() {
            await expectRevert(
                this.swapMining.updateXmsPerBlock(2, fromAttacker),
                "onlyGovernor"
            );
        });

        it('success', async function() {
            const receipt = await this.swapMining.updateXmsPerBlock(2);
            expectEvent.inLogs(receipt.logs, 'UpdateXmsPerBlock', {
                user: owner,
                xmsPerBlock: new BN(2)
            });
            expectBnEqual(await this.swapMining.xmsPerBlock(), new BN(2));
        });
    });

    describe('claim', function() {
        it('zero', async function() {
            const receipt = await this.swapMining.claim();
            expectEvent.inTransaction(receipt.tx, XMSToken, 'Transfer', {
                from: this.swapMining.address,
                to: owner,
                value: zero
            });
        });

        it('success', async function() {
            const ts = await time.latest();
            const start = _.floor(ts / PERIOD) * PERIOD;
            await time.increaseTo(start + _.floor(PERIOD * 3 / 2));

            await this.swapMining.swap(
                minter,
                this.busd.address,
                this.usdm.address,
                one
            );

            await time.increaseTo(start + (PERIOD * 5 / 2));

            await this.swapMining.withdraw({ from: minter });
            const reward = await this.xms.balanceOf(minter);
            for (let i = 1; i < 60; i++) {
                await time.increaseTo(start + (PERIOD * 5 / 2) + (i * PERIOD));
                const receipt = await this.swapMining.claim({ from: minter });
                expectEvent.inTransaction(receipt.tx, XMSToken, 'Transfer', {
                    from: this.swapMining.address,
                    to: minter,
                    value: reward.subn(1)
                });
            }
        
            await time.increaseTo(start + (PERIOD * 5 / 2) + (60 * PERIOD));
            const receipt = await this.swapMining.claim({ from: minter });
            expectEvent.inTransaction(receipt.tx, XMSToken, 'Transfer', {
                from: this.swapMining.address,
                to: minter,
                value: zero
            });
        });
    });

    describe('getVestingAmount', function() {
        it('zero', async function() {
            const ret = await this.swapMining.getVestingAmount();
            expectBnEqual(ret.lockedAmount, zero);
            expectBnEqual(ret.claimableAmount, zero);
        });

        it('success', async function() {
            const ts = await time.latest();
            const start = _.floor(ts / PERIOD) * PERIOD;
            await time.increaseTo(start + _.floor(PERIOD * 3 / 2));

            await this.swapMining.swap(
                minter,
                this.busd.address,
                this.usdm.address,
                one
            );

            await time.increaseTo(start + (PERIOD * 5 / 2));

            await this.swapMining.withdraw({ from: minter });
            const reward = await this.xms.balanceOf(minter);
            const total = reward.subn(1).muln(59);
            for (let i = 1; i < 60; i++) {
                await time.increaseTo(start + (PERIOD * 5 / 2) + (i * PERIOD));
                const ret = await this.swapMining.getVestingAmount({ from: minter });
                expectBnEqual(ret.claimableAmount, reward.subn(1).muln(i));
                expectBnEqual(ret.lockedAmount, total.sub(reward.subn(1).muln(i)));
            }
        });
    });
});