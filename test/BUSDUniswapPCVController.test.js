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

const MarsSwapPair = artifacts.require('MarsSwapPair');

function expectBnEqual(a, b) {
    expect(a).to.be.bignumber.equals(b);
}

function expectBnWithin(a, b, decimals) {
    const d = new BN(10).pow(new BN(decimals));
    expect(a.sub(b).abs().lt(d)).to.be.true;
}

contract('BUSDUniswapPCVController unit test', function(accounts) {
    const [ owner, minter, feeTo, attacker ] = accounts;
    const fromAttacker = { from: attacker };

    beforeEach(async function() {
        const c = this.contracts = await deploy(accounts);
        this.busdUniswapPCVController = c.busdUniswapPCVController;
        this.busd = c.busd;
        this.usdm = c.usdm;
        this.busd2usdm = await MarsSwapPair.at(c.busd2usdm);
        this.busdGenesisGroup = c.busdGenesisGroup;
        this.core = c.core;
        await this.core.grantPCVController(c.busdUniswapPCVController.address);

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

        this.busdUniswapPCVDeposit = c.busdUniswapPCVDeposit;
    });

    describe('depositLpMining', function() {
        it('success', async function() {
            const liquidity = await this.busd2usdm.balanceOf(this.busdUniswapPCVDeposit.address);
            await this.busdUniswapPCVController.depositLpMining(liquidity);
        });
    });

    describe('harvest', function() {
        it('success', async function() {
            const liquidity = await this.busd2usdm.balanceOf(this.busdUniswapPCVDeposit.address);
            await this.busdUniswapPCVController.depositLpMining(liquidity);
            await time.advanceBlock();
            await this.busdUniswapPCVController.harvest();
        });
    });

    describe('withdrawLpMining', function() {
        it('success', async function() {
            const liquidity = await this.busd2usdm.balanceOf(this.busdUniswapPCVDeposit.address);
            await this.busdUniswapPCVController.depositLpMining(liquidity);
            await this.busdUniswapPCVController.withdrawLpMining(liquidity);
        });
    });

    describe('removeLiquidity', function() {
        it('success', async function() {
            const liquidity = await this.busd2usdm.balanceOf(this.busdUniswapPCVDeposit.address);
            await this.busdUniswapPCVController.removeLiquidity(liquidity, one, one.muln(2));
            expectBnEqual(
                await this.busd2usdm.balanceOf(this.busdUniswapPCVDeposit.address),
                zero
            );
            expectBnEqual(
                await this.usdm.balanceOf(this.busdUniswapPCVDeposit.address),
                zero
            );
        });
    });

    describe('forceWithdraw', function() {
        it('success', async function() {
            const amount = one.muln(10000);
            await this.busd.mint(this.busdUniswapPCVDeposit.address, amount);
            await this.busdUniswapPCVController.forceWithdraw(minter);
            expectBnEqual(
                await this.busd.balanceOf(minter),
                amount
            );
        });
    });
});