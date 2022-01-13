const {
  BN, // Big Number support
  constants, // Common constants, like the zero address and largest integers
  expectEvent, // Assertions for emitted events
  expectRevert, // Assertions for transactions that should fail
  time
} = require('@openzeppelin/test-helpers');
require('dotenv').config();

var Core = artifacts.require("Core");
var XMSToken = artifacts.require("XMSToken");
var USDMToken = artifacts.require("USDMToken");
var MarsSwapFactory = artifacts.require("MarsSwapFactory");
var BUSDUniswapPCVDeposit = artifacts.require("BUSDUniswapPCVDeposit");
var LiquidityMiningMaster = artifacts.require("LiquidityMiningMaster");
var BUSDBondingLCurve = artifacts.require("BUSDBondingLCurve");
var XMSRedemptionUnit = artifacts.require("XMSRedemptionUnit");

var USDMGovernanceOracle = artifacts.require("USDMGovernanceOracle");
var XMSCirculatingSupplyOracle = artifacts.require("XMSCirculatingSupplyOracle");
var XMSForUSDMMROracle = artifacts.require("MarsSwapPairCombOracle");
var XMSForUSDMSupplyCapOracle = artifacts.require("MarsSwapPairCombOracle");
var OracleIncentives = artifacts.require("OracleIncentives");

var one = new BN("1000000000000000000");
module.exports = function (deployer, network, accounts) {
  deployer.then(async function () {
    var core;
    var busd;
    var factory;
    var xms;
    var usdm;
    var lpMining;
    var busdBondingLCurve;
    var xmsRedemptionUnit;
    var busdPCVDeposit;
    var wbnb;
    var busdLastPriceOracle;
    var bnbLastPriceOracle;
    if (network == 'mainnet') {
      core = await Core.at(process.env.MAIN_DEPLOYED_CORE);
      busd = process.env.MAIN_BUSD_ADDRESS;
      factory = await MarsSwapFactory.at(process.env.MAIN_DEPLOYED_MARSSWAP_FACTORY);
      xms = process.env.MAIN_DEPLOYED_XMS;
      usdm = process.env.MAIN_DEPLOYED_USDM;
      lpMining = process.env.MAIN_DEPLOYED_LP_MINING;
      busdPCVDeposit = process.env.MAIN_DEPLOYED_BUSD_PCV_DEPOSIT
      busdBondingLCurve = await BUSDBondingLCurve.at(process.env.MAIN_DEPLOYED_BUSD_BONDING_L_CURVE);
      xmsRedemptionUnit = await XMSRedemptionUnit.at(process.env.MAIN_DEPLOYED_XMS_REDEMPTION_UTIL);
      wbnb = process.env.MAIN_WBNB_ADDRESS;
      busdLastPriceOracle = process.env.MAIN_DEPLOYED_CHAINLINK_BUSD;
      bnbLastPriceOracle = process.env.MAIN_DEPLOYED_CHAINLINK_WBNB;
    } else if (network == 'testnet') {
      core = await Core.at(process.env.TEST_DEPLOYED_CORE);
      busd = process.env.TEST_BUSD_ADDRESS;
      factory = await MarsSwapFactory.at(process.env.TEST_DEPLOYED_MARSSWAP_FACTORY);
      xms = process.env.TEST_DEPLOYED_XMS;
      usdm = process.env.TEST_DEPLOYED_USDM;
      lpMining = process.env.TEST_DEPLOYED_LP_MINING;
      busdPCVDeposit = process.env.TEST_DEPLOYED_BUSD_PCV_DEPOSIT
      busdBondingLCurve = await BUSDBondingLCurve.at(process.env.TEST_DEPLOYED_BUSD_BONDING_L_CURVE);
      xmsRedemptionUnit = await XMSRedemptionUnit.at(process.env.TEST_DEPLOYED_XMS_REDEMPTION_UTIL);
      wbnb = process.env.TEST_WBNB_ADDRESS;
      busdLastPriceOracle = process.env.TEST_DEPLOYED_CHAINLINK_BUSD;
      bnbLastPriceOracle = process.env.TEST_DEPLOYED_CHAINLINK_WBNB;
    } else {
      core = await Core.at(process.env.DEV_DEPLOYED_CORE);
      busd = process.env.DEV_BUSD_ADDRESS;
      factory = await MarsSwapFactory.at(process.env.DEV_DEPLOYED_MARSSWAP_FACTORY);
      xms = process.env.DEV_DEPLOYED_XMS;
      usdm = process.env.DEV_DEPLOYED_USDM;
      lpMining = process.env.DEV_DEPLOYED_LP_MINING;
      busdPCVDeposit = process.env.DEV_DEPLOYED_BUSD_PCV_DEPOSIT
      busdBondingLCurve = await BUSDBondingLCurve.at(process.env.DEV_DEPLOYED_BUSD_BONDING_L_CURVE);
      xmsRedemptionUnit = await XMSRedemptionUnit.at(process.env.DEV_DEPLOYED_XMS_REDEMPTION_UTIL);
      wbnb = process.env.DEV_WBNB_ADDRESS;
      busdLastPriceOracle = process.env.DEV_DEPLOYED_CHAINLINK_BUSD;
      bnbLastPriceOracle = process.env.DEV_DEPLOYED_CHAINLINK_WBNB;
    }


    var busd2usdm = await factory.getPair(busd, usdm);
    console.log("BUSD/USDM");
    console.log(busd2usdm);
    var xms2usdm = await factory.getPair(xms, usdm);
    console.log("XMS/USDM");
    console.log(xms2usdm);


    var usdmGovernanceOracle = await deployer.deploy(USDMGovernanceOracle, core.address, usdm);
    await usdmGovernanceOracle.addApprovedPairAndContract(busd2usdm, busdPCVDeposit);
    await busdBondingLCurve.setUSDMGovernanceOracle(usdmGovernanceOracle.address);
    
    var xmsCirculatingSupplyOracle = await deployer.deploy(XMSCirculatingSupplyOracle, core.address, xms);
    await busdBondingLCurve.setXMSCirculatingSupplyOracle(xmsCirculatingSupplyOracle.address);

    var xmsForUSDMMROracle = await deployer.deploy(XMSForUSDMMROracle, core.address, factory.address, 900, 300, 1200);
    await xmsForUSDMMROracle.initialize(bnbLastPriceOracle, [xms, wbnb]);

    var xmsForUSDMSupplyCapOracle = await deployer.deploy(XMSForUSDMSupplyCapOracle, core.address, factory.address, 180, 180, 360);
    await xmsForUSDMSupplyCapOracle.initialize(bnbLastPriceOracle, [xms, wbnb]);

    await deployer.deploy(OracleIncentives,
      core.address,
      [
        xmsForUSDMMROracle.address,
        xmsForUSDMSupplyCapOracle.address,
        constants.ZERO_ADDRESS,
        constants.ZERO_ADDRESS
      ],
      new BN(5).mul(one).div(new BN(10)));
    await core.grantMinter(OracleIncentives.address);

    await busdBondingLCurve.setXMSForUSDMSupplyCapOracle(xmsForUSDMSupplyCapOracle.address);
    await xmsRedemptionUnit.setXMSForUSDMMROracle(xmsForUSDMMROracle.address);
    await xmsForUSDMMROracle.update();
    await xmsForUSDMSupplyCapOracle.update();
  });
}