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

contract('LiquidityMiningMaster unit test', function(accounts) {
    const [ owner, minter, feeTo, attacker ] = accounts;
    const fromAttacker = { from: attacker };

    beforeEach(async function() {
        const c = this.contracts = await deploy(accounts);
        this.lpMining = c.lpMining;
        this.xms = c.xms;
    });

    describe('deposit', function() {
        it('validatePid', async function() {
            await expectRevert(
                this.lpMining.deposit(10, 100),
                'LiquidityMiningMaster::validatePid: Not exist'
            );
        });

        it('Transfer amount exceeds spender allowance', async function() {
            const amount = one.muln(10000);
            await expectRevert(
                this.lpMining.deposit(0, amount),
                'XMSToken::transferFrom: Transfer amount exceeds spender allowance.'
            );
        });

        it('success', async function() {
            const amount = one.muln(10000);
            await this.xms.mint(owner, amount);
            await this.xms.approve(this.lpMining.address, amount);
            const _balance = await this.xms.balanceOf(owner);
            const receipt = await this.lpMining.deposit(0, amount);
            expectEvent.inLogs(receipt.logs, 'Deposit', {
                pid: zero,
                amount
            });
            expectBnEqual(await this.xms.balanceOf(owner), _balance.sub(amount));
        });

        it('success with reward', async function() {
            const amount = one.muln(10000);
            await this.xms.mint(owner, amount);
            await this.xms.approve(this.lpMining.address, amount);
            await this.lpMining.deposit(0, amount);

            await time.advanceBlock(1000);
            await this.xms.mint(owner, amount);
            await this.xms.approve(this.lpMining.address, amount);
            const _balance = await this.xms.balanceOf(owner);
            const pending = await this.lpMining.pendingXMS(0, owner);
            const receipt = await this.lpMining.deposit(0, amount);
            expectEvent.inLogs(receipt.logs, 'Deposit', {
                pid: zero,
                amount
            });

            expectBnWithin(
                await this.xms.balanceOf(owner),
                _balance.add(pending).sub(amount),
                18
            );
        });
    });

    describe('withdraw', function() {
        it('validatePid', async function() {
            await expectRevert(
                this.lpMining.withdraw(10, 100),
                'LiquidityMiningMaster::validatePid: Not exist'
            );
        });

        it('Not good', async function() {
            await expectRevert(
                this.lpMining.withdraw(0, 100),
                'LiquidityMiningMaster::withdraw: Not good'
            );
        });

        it('withdraw pending', async function() {
            const amount = one.muln(10000);
            const ts = await time.latest();
            const start = _.floor(ts / PERIOD) * PERIOD;
            await time.increaseTo(start + _.floor(PERIOD * 3 / 2));
            
            await this.xms.mint(owner, amount);
            await this.xms.approve(this.lpMining.address, amount);
            await this.lpMining.deposit(0, amount);

            await time.increaseTo(start + (PERIOD * 5 / 2));
            const block = await time.latestBlock();
            await time.advanceBlockTo(block.addn(100));

            const _balance = await this.xms.balanceOf(owner);
            const pending = await this.lpMining.pendingXMS(0, owner);
            const receipt = await this.lpMining.withdraw(0, 0);
            expectEvent.inLogs(receipt.logs, 'Withdraw', {
                pid: zero,
                amount: zero
            });
            expectBnWithin(
                await this.xms.balanceOf(owner),
                _balance.add(pending.divn(60)),
                14
            );
        });

        it('success', async function() {
            const amount = one.muln(10000);
            const ts = await time.latest();
            const start = _.floor(ts / PERIOD) * PERIOD;
            await time.increaseTo(start + _.floor(PERIOD * 3 / 2));

            await this.xms.mint(owner, amount);
            await this.xms.approve(this.lpMining.address, amount);
            await this.lpMining.deposit(0, amount);

            await time.increaseTo(start + (PERIOD * 5 / 2));
            const block = await time.latestBlock();
            await time.advanceBlockTo(block.addn(100));

            const _balance = await this.xms.balanceOf(owner);
            const pending = await this.lpMining.pendingXMS(0, owner);
            const receipt = await this.lpMining.withdraw(0, amount);
            expectEvent.inLogs(receipt.logs, 'Withdraw', {
                pid: zero,
                amount
            });
            expectBnWithin(
                await this.xms.balanceOf(owner),
                _balance.add(amount).add(pending.divn(60)),
                14
            );
        });
    });

    describe('emergencyWithdraw', function() {
        it('validatePid', async function() {
            await expectRevert(
                this.lpMining.emergencyWithdraw(10),
                'LiquidityMiningMaster::validatePid: Not exist'
            );
        });

        it('success', async function() {
            const amount = one.muln(10000);
            await this.xms.mint(owner, amount);
            await this.xms.approve(this.lpMining.address, amount);
            await this.lpMining.deposit(0, amount);

            const _balance = await this.xms.balanceOf(owner);
            const receipt = await this.lpMining.emergencyWithdraw(0);
            expectEvent.inLogs(receipt.logs, 'EmergencyWithdraw', {
                user: owner,
                pid: zero,
                amount
            });
            expectBnEqual(
                await this.xms.balanceOf(owner),
                _balance.add(amount)
            );
            expectBnEqual(await this.lpMining.pendingXMS(0, owner), zero);
        });
    });

    describe('updateXmsPerBlock', function() {
        it('onlyGovernor', async function() {
            await expectRevert(
                this.lpMining.updateXmsPerBlock(2, fromAttacker),
                "onlyGovernor"
            );
        });

        it('success', async function() {
            const receipt = await this.lpMining.updateXmsPerBlock(2);
            expectEvent.inLogs(receipt.logs, 'UpdateEmissionRate', {
                user: owner,
                xmsPerBlock: new BN(2)
            });
            expectBnEqual(await this.lpMining.xmsPerBlock(), new BN(2));
        });
    });

    describe('updateEndBlock', function() {
        it('onlyGovernor', async function() {
            const latestBlock = await time.latestBlock();
            const toBlock = latestBlock.addn(1000);
            await expectRevert(
                this.lpMining.updateEndBlock(toBlock, fromAttacker),
                "onlyGovernor"
            );
        });

        it('success', async function() {
            const latestBlock = await time.latestBlock();
            const toBlock = latestBlock.addn(1000);
            const receipt = await this.lpMining.updateEndBlock(toBlock);
            expectEvent.inLogs(receipt.logs, 'UpdateEndBlock', {
                user: owner,
                endBlock: toBlock
            });
            expectBnEqual(await this.lpMining.endBlock(), toBlock);
        });
    });

    describe('pendingXMS', function() {
        it('validatePid', async function() {
            await expectRevert(
                this.lpMining.pendingXMS(10, owner),
                'LiquidityMiningMaster::validatePid: Not exist'
            );
        });

        it('success', async function() {
            const amount = one.muln(10000);
            await this.xms.mint(owner, amount);
            await this.xms.approve(this.lpMining.address, amount);

            const latestBlock = await time.latestBlock();
            await this.lpMining.deposit(0, amount);

            await time.advanceBlockTo(latestBlock.addn(10));

            const newBlock = await time.latestBlock();
            const reward = one
                .mul(newBlock.sub(latestBlock).subn(1))
                .mul(amount)
                .muln(20)
                .divn(60)
                .div(one.muln(1000000).add(amount));

            expectBnWithin(
                await this.lpMining.pendingXMS(0, owner),
                reward,
                10
            );
        });
    });

    describe('claim', function() {
        it('zero', async function() {
            const receipt = await this.lpMining.claim();
            expectEvent.inTransaction(receipt.tx, XMSToken, 'Transfer', {
                from: this.lpMining.address,
                to: owner,
                value: zero
            });
        });

        it('success', async function () {
            const amount = one.muln(10000);
            const ts = await time.latest();
            const start = _.floor(ts / PERIOD) * PERIOD;
            await time.increaseTo(start + _.floor(PERIOD * 3 / 2));

            await this.xms.mint(owner, amount);
            await this.xms.approve(this.lpMining.address, amount);
            await this.lpMining.deposit(0, amount);

            await time.increaseTo(start + (PERIOD * 5 / 2));
            const block = await time.latestBlock();
            await time.advanceBlockTo(block.addn(100));

            await this.lpMining.withdraw(0, 0);
            const reward = await this.xms.balanceOf(owner);
            for (let i = 1; i < 60; i++) {
                await time.increaseTo(start + (PERIOD * 5 / 2) + (i * PERIOD));
                const receipt = await this.lpMining.claim();
                expectEvent.inTransaction(receipt.tx, XMSToken, 'Transfer', {
                    from: this.lpMining.address,
                    to: owner,
                    value: reward
                });
            }

            await time.increaseTo(start + (PERIOD * 5 / 2) + (60 * PERIOD));
            const receipt = await this.lpMining.claim();
            expectEvent.inTransaction(receipt.tx, XMSToken, 'Transfer', {
                from: this.lpMining.address,
                to: owner,
                value: zero
            });
        });
    });

    describe('getVestingAmount', function() {
        it('zero', async function() {
            const ret = await this.lpMining.getVestingAmount();
            expectBnEqual(ret.lockedAmount, zero);
            expectBnEqual(ret.claimableAmount, zero);
        });

        it('success', async function() {
            const amount = one.muln(10000);
            const ts = await time.latest();
            const start = _.floor(ts / PERIOD) * PERIOD;
            await time.increaseTo(start + _.floor(PERIOD * 3 / 2));

            await this.xms.mint(owner, amount);
            await this.xms.approve(this.lpMining.address, amount);
            await this.lpMining.deposit(0, amount);

            await time.increaseTo(start + (PERIOD * 5 / 2));
            const block = await time.latestBlock();
            await time.advanceBlockTo(block.addn(100));

            await this.lpMining.withdraw(0, 0);
            const reward = await this.xms.balanceOf(owner);
            const total = reward.muln(59);
            for (let i = 1; i < 60; i++) {
                await time.increaseTo(start + (PERIOD * 5 / 2) + (i * PERIOD));
                const ret = await this.lpMining.getVestingAmount();
                expectBnEqual(ret.claimableAmount, reward.muln(i));
                expectBnEqual(ret.lockedAmount, total.sub(reward.muln(i)));
            }
        });
    });
});