const {
  BN, // Big Number support
  constants, // Common constants, like the zero address and largest integers
  expectEvent, // Assertions for emitted events
  expectRevert, // Assertions for transactions that should fail
} = require('@openzeppelin/test-helpers');

var Core = artifacts.require("Core");
var XMSToken = artifacts.require("XMSToken");
var USDMToken = artifacts.require("USDMToken");
var SwapMining = artifacts.require("SwapMining");
var MarsSwapRouter = artifacts.require("MarsSwapRouter");

var one = new BN("1000000000000000000");
module.exports = function (deployer, network, accounts) {
  deployer.then(async () => {
    var core;
    var router;
    var xms;
    var usdm;
    if (network == 'mainnet') {
      core = await Core.at(process.env.MAIN_DEPLOYED_CORE);
      router = await MarsSwapRouter.at(process.env.MAIN_DEPLOYED_MARSSWAP_ROUTER);
      xms = await XMSToken.at(process.env.MAIN_DEPLOYED_XMS);
      usdm = await USDMToken.at(process.env.MAIN_DEPLOYED_USDM);
    } else if (network == 'testnet') {
      core = await Core.at(process.env.TEST_DEPLOYED_CORE);
      router = await MarsSwapRouter.at(process.env.TEST_DEPLOYED_MARSSWAP_ROUTER);
      xms = await XMSToken.at(process.env.TEST_DEPLOYED_XMS);
      usdm = await USDMToken.at(process.env.TEST_DEPLOYED_USDM);
    } else {
      core = await Core.at(process.env.DEV_DEPLOYED_CORE);
      router = await MarsSwapRouter.at(process.env.DEV_DEPLOYED_MARSSWAP_ROUTER);
      xms = await XMSToken.at(process.env.DEV_DEPLOYED_XMS);
      usdm = await USDMToken.at(process.env.DEV_DEPLOYED_USDM);
    }

    var busd;
    if (network == 'mainnet') {
      busd = process.env.MAIN_BUSD_ADDRESS;
    } else if (network == 'testnet') {
      busd = process.env.TEST_BUSD_ADDRESS;
    } else {
      busd = process.env.DEV_BUSD_ADDRESS;
    }
    await router.setSwapMining(SwapMining.address);

    var swapMining = await SwapMining.deployed();
    await swapMining.addWhitelist(xms.address);
    await swapMining.addWhitelist(usdm.address);
    await swapMining.addWhitelist(busd);
    await core.grantRole(web3.utils.keccak256("FARMS_ROLE"), swapMining.address);
  });
}