const {
  BN,           // Big Number support
  constants,    // Common constants, like the zero address and largest integers
  expectEvent,  // Assertions for emitted events
  expectRevert, // Assertions for transactions that should fail
} = require('@openzeppelin/test-helpers');

const XMSToken = artifacts.require("XMSToken");
const USDMToken = artifacts.require("USDMToken");
const LiquidityMiningMaster = artifacts.require("LiquidityMiningMaster");

var one = new BN("1000000000000000000");
contract("Test", (accounts) => {
    before(async () => {

    });
    it("approve mars token", async () => {
        const xms = await XMSToken.deployed();
        const usdm = await USDMToken.deployed();
        const liquidityMiningMaster = await LiquidityMiningMaster.deployed();
        await xms.approve(liquidityMiningMaster.address, one.mul(new BN("100000000")));

        let balance = await xms.balanceOf(accounts[0]);
        console.log(balance.toString());
        let allownce = await xms.allowance(accounts[0], liquidityMiningMaster.address);
        console.log(allownce.toString());

        await liquidityMiningMaster.addPool(20, XMSToken.address, true);
        await liquidityMiningMaster.addPool(5, USDMToken.address, true);
        await liquidityMiningMaster.deposit(0, new BN("10000000000000000000000"));
        const userInfo = await liquidityMiningMaster.userInfo(0, accounts[0]);
        console.log(userInfo.amount.toString() + "/" + userInfo.rewardDebt.toString());

        balance = await xms.balanceOf(accounts[0]);
        console.log(balance.toString());
        allownce = await xms.allowance(accounts[0], liquidityMiningMaster.address);
        console.log(allownce.toString());
    });
});