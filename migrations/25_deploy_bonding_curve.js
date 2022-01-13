const {
  BN, // Big Number support
  constants, // Common constants, like the zero address and largest integers
  expectEvent, // Assertions for emitted events
  expectRevert, // Assertions for transactions that should fail
} = require('@openzeppelin/test-helpers');
require('dotenv').config();

var Core = artifacts.require("Core");
var USDMToken = artifacts.require("USDMToken");
var MarsSwapFactory = artifacts.require("MarsSwapFactory");
var MarsSwapRouter = artifacts.require("MarsSwapRouter");
var BUSDUniswapPCVDeposit = artifacts.require("BUSDUniswapPCVDeposit");

var BUSDBondingLCurve = artifacts.require("BUSDBondingLCurve");

var one = new BN("1000000000000000000");
module.exports = function (deployer, network, accounts) {
  deployer.then(async function () {
    var core;
    var factory;
    var router;
    var usdm;
    if (network == 'mainnet') {
      core = await Core.at(process.env.MAIN_DEPLOYED_CORE);
      factory = await MarsSwapFactory.at(process.env.MAIN_DEPLOYED_MARSSWAP_FACTORY);
      router = await MarsSwapRouter.at(process.env.MAIN_DEPLOYED_MARSSWAP_ROUTER);
      usdm = await USDMToken.at(process.env.MAIN_DEPLOYED_USDM);
    } else if (network == 'testnet') {
      core = await Core.at(process.env.TEST_DEPLOYED_CORE);
      factory = await MarsSwapFactory.at(process.env.TEST_DEPLOYED_MARSSWAP_FACTORY);
      router = await MarsSwapRouter.at(process.env.TEST_DEPLOYED_MARSSWAP_ROUTER);
      usdm = await USDMToken.at(process.env.TEST_DEPLOYED_USDM);
    } else {
      core = await Core.at(process.env.DEV_DEPLOYED_CORE);
      factory = await MarsSwapFactory.at(process.env.DEV_DEPLOYED_MARSSWAP_FACTORY);
      router = await MarsSwapRouter.at(process.env.DEV_DEPLOYED_MARSSWAP_ROUTER);
      usdm = await USDMToken.at(process.env.DEV_DEPLOYED_USDM);
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
    var pair = await factory.getPair(busd, usdm.address);
    console.log("BUSD/USDM");
    console.log(pair)

    // core, oracle[xmsForUSDMMROracle, xmsForUSDMSupplyCapOracle, usdmGovernanceOracle, xmsCirculatingSupplyOracle], busd, chainlink, pcvDeposits, ratios, duration, incentive
    await deployer.deploy(BUSDBondingLCurve,
      core.address,
      [
        constants.ZERO_ADDRESS,
        "0x44f2BDDDEbAaaeF24Bf0559D29135aF33Dea15C6",
        "0xF2D658C62fcdF04dD63d5D376E0Dc5f68a341E8B",
        "0xD27CF0BC9FB18301C9F5b0e0FaC4D1c99698F12D"
      ],
      busd,
      busdLastPriceOracle,
      ["0x343BD1bE0C557043ee2b31bb9a99DD4b6c585455"],
      [10000],
      86400,
      new BN(2).mul(one),
    );
    await core.grantMinter(BUSDBondingLCurve.address);
  });
}