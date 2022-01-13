const {
  BN, // Big Number support
  constants, // Common constants, like the zero address and largest integers
  expectEvent, // Assertions for emitted events
  expectRevert, // Assertions for transactions that should fail
} = require('@openzeppelin/test-helpers');
require('dotenv').config();

var Core = artifacts.require("Core");
var XMSToken = artifacts.require("XMSToken");
var USDMToken = artifacts.require("USDMToken");
var MarsSwapFactory = artifacts.require("MarsSwapFactory");
var MarsSwapRouter = artifacts.require("MarsSwapRouter");
var LiquidityMiningMaster = artifacts.require("LiquidityMiningMaster");

var BUSDUniswapPCVDeposit = artifacts.require("BUSDUniswapPCVDeposit");

module.exports = function (deployer, network, accounts) {
  deployer.then(async function () {
    var core;
    var xms;
    var factory;
    var router;
    var usdm;
    var liquidityMiningMaster;
    if (network == 'mainnet') {
      core = await Core.at(process.env.MAIN_DEPLOYED_CORE);
      xms = await XMSToken.at(process.env.MAIN_DEPLOYED_XMS);
      factory = await MarsSwapFactory.at(process.env.MAIN_DEPLOYED_MARSSWAP_FACTORY);
      router = await MarsSwapRouter.at(process.env.MAIN_DEPLOYED_MARSSWAP_ROUTER);
      usdm = await USDMToken.at(process.env.MAIN_DEPLOYED_USDM);
      liquidityMiningMaster = await LiquidityMiningMaster.at(process.env.MAIN_DEPLOYED_LP_MINING);
    } else if (network == 'testnet') {
      core = await Core.at(process.env.TEST_DEPLOYED_CORE);
      xms = await XMSToken.at(process.env.TEST_DEPLOYED_XMS);
      factory = await MarsSwapFactory.at(process.env.TEST_DEPLOYED_MARSSWAP_FACTORY);
      router = await MarsSwapRouter.at(process.env.TEST_DEPLOYED_MARSSWAP_ROUTER);
      usdm = await USDMToken.at(process.env.TEST_DEPLOYED_USDM);
      liquidityMiningMaster = await LiquidityMiningMaster.at(process.env.TEST_DEPLOYED_LP_MINING);
    } else {
      core = await Core.at(process.env.DEV_DEPLOYED_CORE);
      xms = await XMSToken.at(process.env.DEV_DEPLOYED_XMS);
      factory = await MarsSwapFactory.at(process.env.DEV_DEPLOYED_MARSSWAP_FACTORY);
      router = await MarsSwapRouter.at(process.env.DEV_DEPLOYED_MARSSWAP_ROUTER);
      usdm = await USDMToken.at(process.env.DEV_DEPLOYED_USDM);
      liquidityMiningMaster = await LiquidityMiningMaster.at(process.env.DEV_DEPLOYED_LP_MINING);
    }

    var busd;
    var busdLastPriceOracle;
    if (network == 'mainnet') {
      busd = process.env.MAIN_BUSD_ADDRESS;
      busdLastPriceOracle = process.env.MAIN_DEPLOYED_CHAINLINK_BUSD;
    } else if (network == 'testnet') {
      busd = process.env.TEST_BUSD_ADDRESS;
      busdLastPriceOracle = process.env.TEST_DEPLOYED_CHAINLINK_BUSD;
    } else {
      busd = process.env.DEV_BUSD_ADDRESS;
      busdLastPriceOracle = process.env.DEV_DEPLOYED_CHAINLINK_BUSD;
    }
    var busd2usdm = await factory.getPair(busd, usdm.address);
    if (busd2usdm == constants.ZERO_ADDRESS) {
      await factory.createPair(busd, usdm.address);
      busd2usdm = await factory.getPair(busd, usdm.address);
    }
    console.log("BUSD/USDM");
    console.log(busd2usdm)

    // core, chainlink, pair, router, factory, busd, lpMiningMaster, vestingMaster
    await deployer.deploy(BUSDUniswapPCVDeposit,
      core.address,
      "0x5E9d300ec4Ac0D4aEacCd62E8a881dB95754Dc01",
      busdLastPriceOracle,
      busd2usdm,
      router.address,
      factory.address,
      busd,
      constants.ZERO_ADDRESS,
      constants.ZERO_ADDRESS,
      xms.address
    );
    await core.grantMinter(BUSDUniswapPCVDeposit.address);
  });
}