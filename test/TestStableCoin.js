const {
  BN, // Big Number support
  constants, // Common constants, like the zero address and largest integers
  expectEvent, // Assertions for emitted events
  expectRevert, // Assertions for transactions that should fail
} = require('@openzeppelin/test-helpers');
const { assertion } = require('@openzeppelin/test-helpers/src/expectRevert');

const Core = artifacts.require("CORE");
const BUSD = artifacts.require("IERC20");
const BUSDGenesisGroup = artifacts.require("BUSDGenesisGroup");
const IDO = artifacts.require("IDO");
const XMSRedemptionUnit = artifacts.require("XMSRedemptionUnit");
const BUSDBondingLCurve = artifacts.require("BUSDBondingLCurve");

var busdAddress = "0xEF3C6233F65952d45875c189608cfff4AE806831";
var busd;
var one = new BN("1000000000000000000");
var core;
var busdGenesisGroup;
contract("Test", (accounts) => {
  before(async () => {
    core = await Core.deployed();
    busd = await BUSD.at(busdAddress);
  });
  it("purchase", async () => {
    busdGenesisGroup = await BUSDGenesisGroup.deployed();
    busd.approve(BUSDGenesisGroup.address, new BN(100).mul(one));
    var balance = busdGenesisGroup.balanceOf(accounts[0]);
    await busdGenesisGroup.purchase(accounts[0], one);
    assert.equal(one, one.add(balance));
  });
  it("getAmount", async () => {
    var rets = await busdGenesisGroup.getAmountsToRedeem(accounts[0]);
    console.log(rets);
    rets = await retsbusdGenesisGroup.getAmountOut(one, true);
    console.log(rets);
  });
});