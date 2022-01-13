const {
  BN, // Big Number support
  constants, // Common constants, like the zero address and largest integers
  expectEvent, // Assertions for emitted events
  expectRevert, // Assertions for transactions that should fail
} = require('@openzeppelin/test-helpers');
require('dotenv').config();

var Core = artifacts.require("Core");
var XMSToken = artifacts.require("XMSToken");
var MarsSwapFactory = artifacts.require("MarsSwapFactory");
var MarsSwapRouter = artifacts.require("MarsSwapRouter");
var SwapMiningOracle = artifacts.require("SwapMiningOracle");
var VestingMaster = artifacts.require("VestingMaster");

var SwapMining = artifacts.require("SwapMining");

var one = new BN("1000000000000000000");
module.exports = function (deployer, network, accounts) {
  deployer.then(async () => {
    var core;
    var factory;
    var router;
    var xms;
    if (network == 'mainnet') {
      core = await Core.at(process.env.MAIN_DEPLOYED_CORE);
      factory = await MarsSwapFactory.at(process.env.MAIN_DEPLOYED_MARSSWAP_FACTORY);
      router = await MarsSwapRouter.at(process.env.MAIN_DEPLOYED_MARSSWAP_ROUTER);
      xms = await XMSToken.at(process.env.MAIN_DEPLOYED_XMS);
    } else if (network == 'testnet') {
      core = await Core.at(process.env.TEST_DEPLOYED_CORE);
      factory = await MarsSwapFactory.at(process.env.TEST_DEPLOYED_MARSSWAP_FACTORY);
      router = await MarsSwapRouter.at(process.env.TEST_DEPLOYED_MARSSWAP_ROUTER);
      xms = await XMSToken.at(process.env.TEST_DEPLOYED_XMS);
    } else {
      core = await Core.at(process.env.DEV_DEPLOYED_CORE);
      factory = await MarsSwapFactory.at(process.env.DEV_DEPLOYED_MARSSWAP_FACTORY);
      router = await MarsSwapRouter.at(process.env.DEV_DEPLOYED_MARSSWAP_ROUTER);
      xms = await XMSToken.at(process.env.DEV_DEPLOYED_XMS);
    }
    // core, vestingMaster, xms, factory, oracle, router, targetToken, xmsPerBlock, startBlock, endBlock
    await deployer.deploy(SwapMining,
      core.address,
      VestingMaster.address,
      xms.address,
      factory.address,
      SwapMiningOracle.address,
      router.address,
      xms.address,
      new BN(1).mul(one),
      0,
      39999999);
  });
}