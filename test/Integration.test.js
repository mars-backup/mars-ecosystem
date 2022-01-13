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

const MarsSwapPair = artifacts.require('MarsSwapPair');

const zero = new BN(0);
const one = new BN("1000000000000000000");

function expectBnEqual(a, b) {
    expect(a).to.be.bignumber.equals(b);
}

function expectBnWithin(a, b, decimals) {
    const d = new BN(10).pow(new BN(decimals));
    expect(a.sub(b).abs().lt(d)).to.be.true;
}

contract('Integration test', function(accounts) {
    const [ owner, minter, feeTo, attacker, holder ] = accounts;
    const fromAttacker = { from: attacker };

    beforeEach(async function() {
        const c = this.contracts = await deploy(accounts);
        this.busdGenesisGroup = c.busdGenesisGroup;
        this.busd = c.busd;
        this.core = c.core;
        this.usdm = c.usdm;
        this.xms = c.xms;
        this.busdBondingLCurve = c.busdBondingLCurve;
        this.busdUniswapPCVDeposit = c.busdUniswapPCVDeposit;
        this.busd2usdm = await MarsSwapPair.at(c.busd2usdm);
        this.xmsRedemptionUnit = c.xmsRedemptionUnit;
        this.busdUniswapPCVController = c.busdUniswapPCVController;
        this.lpMining = c.lpMining;
        await this.core.grantPCVController(c.busdUniswapPCVController.address);
    });

    it('all', async function() {
        const amount = one.muln(10000);
        const usdmAmount = amount.muln(105).divn(100);
        await this.busdGenesisGroup.initGenesis();
        await this.busd.mint(owner, amount);
        await this.busd.approve(this.busdGenesisGroup.address, amount);
        await this.busdGenesisGroup.purchase(owner, amount);
        expectBnEqual(await this.busd.balanceOf(owner), zero);
        expectBnEqual(await this.busdGenesisGroup.balanceOf(owner), amount);

        await time.increase(101);
        const receipt = await this.busdGenesisGroup.launch();
        expectEvent.inLogs(receipt.logs, 'Launch', {});

        // check core
        expect(await this.core.hasGenesisGroupCompleted()).to.be.true;
        // check busdGenesisGroup
        expectBnEqual(await this.busdGenesisGroup.totalEffectiveMGEN(), amount);
        expectBnEqual(
            await this.busd.balanceOf(this.busdGenesisGroup.address),
            zero
        );
        expectBnEqual(
            await this.usdm.balanceOf(this.busdGenesisGroup.address),
            usdmAmount.muln(9990).divn(10000)
        );
        // check bondingLCurve
        expectBnEqual(
            await this.busd.balanceOf(this.busdBondingLCurve.address),
            zero
        );
        // check busdUniswapPCVDeposit
        expectBnEqual(
            await this.busd.balanceOf(this.busdUniswapPCVDeposit.address),
            zero
        );
        expectBnEqual(
            await this.usdm.balanceOf(this.busdUniswapPCVDeposit.address),
            zero
        );
        // const liquidity = amount.mul(usdmAmount).redSqrt().sub(1000);
        let liquidity = new BN('10246950765959598382221');
        expectBnEqual(
            await this.busd2usdm.balanceOf(this.busdUniswapPCVDeposit.address),
            liquidity
        );
        // check busd2usdm
        expectBnEqual(
            await this.busd.balanceOf(this.busd2usdm.address),
            amount
        );
        expectBnEqual(
            await this.usdm.balanceOf(this.busd2usdm.address),
            amount.muln(105).divn(100)
        );

        // redeem
        await this.busdGenesisGroup.redeem(owner);
        expectBnEqual(
            await this.usdm.balanceOf(owner),
            usdmAmount.muln(9990).divn(10000)
        );
        expectBnEqual(
            await this.xms.balanceOf(owner),
            one.mul(new BN('1000000')).divn(5)
        );
        expectBnEqual(
            await this.usdm.balanceOf(this.busdGenesisGroup.address),
            zero
        );
        expectBnEqual(
            await this.xms.balanceOf(this.busdGenesisGroup.address),
            zero
        );

        const mintAmount = one.muln(100000);
        await this.busd.mint(minter, mintAmount);
        await this.busd.approve(this.busdBondingLCurve.address, mintAmount, { from: minter });
        await this.busdBondingLCurve.purchase(minter, mintAmount, 0, one, { from: minter });
        expectBnEqual(
            await this.busd.balanceOf(minter),
            zero
        );
        expectBnEqual(
            await this.usdm.balanceOf(minter),
            mintAmount.muln(105).divn(100).muln(9990).divn(10000)
        );
        expectBnEqual(
            await this.busd.balanceOf(this.busdBondingLCurve.address),
            mintAmount
        );

        await this.busdBondingLCurve.allocate();
        expectBnEqual(
            await this.busd.balanceOf(this.busd2usdm.address),
            amount.add(mintAmount)
        );
        expectBnEqual(
            await this.usdm.balanceOf(this.busd2usdm.address),
            amount.add(mintAmount).muln(105).divn(100)
        );

        const holderAmount = one.muln(100000);
        await this.usdm.mint(holder, holderAmount);
        await this.usdm.approve(this.xmsRedemptionUnit.address, holderAmount, { from: holder });
        await this.xmsRedemptionUnit.purchase(holder, holderAmount, 0, one, { from: holder });
        expectBnEqual(
            await this.usdm.balanceOf(holder),
            zero
        );
        expectBnEqual(
            await this.xms.balanceOf(holder),
            holderAmount.muln(5).muln(9990).divn(10000)
        );
        expectBnEqual(
            await this.usdm.balanceOf(this.xmsRedemptionUnit.address),
            zero
        );

        liquidity = await this.busd2usdm.balanceOf(this.busdUniswapPCVDeposit.address);
        await this.busdUniswapPCVController.depositLpMining(liquidity);
        expectBnEqual(
            await this.busd2usdm.balanceOf(this.busdUniswapPCVDeposit.address),
            zero
        );
        expectBnEqual(
            await this.busd2usdm.balanceOf(this.lpMining.address),
            liquidity
        );

        await this.busdUniswapPCVController.withdrawLpMining(liquidity);
        expectBnEqual(
            await this.busd2usdm.balanceOf(this.busdUniswapPCVDeposit.address),
            liquidity
        );
        expectBnEqual(
            await this.busd2usdm.balanceOf(this.lpMining.address),
            zero
        );

        await this.busdUniswapPCVController.removeLiquidity(liquidity, one, one.muln(2));
        expectBnEqual(
            await this.busd2usdm.balanceOf(this.busdUniswapPCVDeposit.address),
            zero
        );
        expectBnEqual(
            await this.usdm.balanceOf(this.busdUniswapPCVDeposit.address),
            zero
        );
        expectBnWithin(
            await this.busd.balanceOf(this.busd2usdm.address),
            zero,
            new BN('10000')
        );
        expectBnWithin(
            await this.usdm.balanceOf(this.busd2usdm.address),
            zero,
            new BN('10000')
        );
    });
});