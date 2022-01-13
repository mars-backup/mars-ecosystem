const {
  BN, // Big Number support
  constants, // Common constants, like the zero address and largest integers
  expectEvent, // Assertions for emitted events
  expectRevert, // Assertions for transactions that should fail
} = require('@openzeppelin/test-helpers');

var Core = artifacts.require("Core");
var XMSToken = artifacts.require("XMSToken");
var USDMToken = artifacts.require("USDMToken");
var MarsSwapFactory = artifacts.require("MarsSwapFactory");
var LiquidityMiningMaster = artifacts.require("LiquidityMiningMaster");
var SwapMining = artifacts.require("SwapMining");
var BUSDGenesisGroup = artifacts.require("BUSDGenesisGroup");
var XMSRedemptionUnit = artifacts.require("XMSRedemptionUnit");
var SwapMiningOracle = artifacts.require("SwapMiningOracle");

var core;
var factory;
var busd;
var busd2usdm;
var xms2usdm;
var one = new BN("1000000000000000000");
var testAddress = [
  "0x9c6f45B39951BAF36e0EDDf18e1a16e25f667360", // xji
  "0x625FcCB779045945a1e84742F22bD7fF190C6882", // john
  "0xD746122dD7Dd4a292a06c2D12D0203f171b8eF7b", // john
  "0xe55908dD03cCEAf3Cd8B879e0319776e3A767B25", // sira
  "0x5719BCc81082f4D21dCF826AC5a31f808c5F8fe8", // ezra
  "0xD300504063836e7774564E58B8a17Ed50798Bed7", // xiong
  "0xb4F83CF3461E0B9E0d36fB8D41B635c8A7Fe6809", // lu
  "0x4791D2b913D58bdA228e619ce5C6E98A4E75c1aa", // rita
  "0x3360deC490E74605c65CDb8D2F87137c1C5E8345", // zhenguo
  "0x51EdcEA7C3Af77E6BB900D588D973d42C352018b", // yuechan
];
module.exports = function (deployer, network, accounts) {
  deployer.then(async () => {
    core = await Core.deployed();
    await core.grantMinter(accounts[0]);
    var usdm = await USDMToken.deployed();
    if (network == 'testnet') {
      for (var i = 0; i < testAddress.length; i++) {
        await core.allocateXMS(testAddress[i], one.mul(new BN("100000")));
        await usdm.mint(testAddress[i], one.mul(new BN("100000")));
      }
    }
    if (network != "mainnet") {
      await core.allocateXMS(accounts[0], one.mul(new BN("10000000")));
      await usdm.mint(accounts[0], one.mul(new BN("10000000")));
    }
    if (network != "mainnet") {
      if (network == 'testnet') {
        busd = process.env.TEST_BUSD_ADDRESS;
      } else {
        busd = process.env.DEV_BUSD_ADDRESS;
      }
      factory = await MarsSwapFactory.deployed();
      busd2usdm = await factory.getPair(busd, USDMToken.address);
      xms2usdm = await factory.getPair(XMSToken.address, USDMToken.address);
      var liquidityMiningMaster = await LiquidityMiningMaster.deployed();
      await liquidityMiningMaster.addPool(20, xms2usdm, true);
      await liquidityMiningMaster.addPool(20, busd2usdm, true);
      var swapMining = await SwapMining.deployed();
      await swapMining.addPool(20, xms2usdm, true);
      await swapMining.addPool(20, busd2usdm, true);
      var swapMiningOracle = await SwapMiningOracle.deployed();
      await swapMiningOracle.addPair(xms2usdm);
      await swapMiningOracle.addPair(busd2usdm);

      await core.allocateXMS(SwapMining.address, one.mul(new BN("10000000")));
      await core.allocateXMS(LiquidityMiningMaster.address, one.mul(new BN("10000000")));

      await core.allocateXMS(BUSDGenesisGroup.address, one.mul(new BN("1000000")));
      await core.allocateXMS(XMSRedemptionUnit.address, one.mul(new BN("1000000")));
    }
  });
}