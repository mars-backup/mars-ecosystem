const {
  BN, // Big Number support
  constants, // Common constants, like the zero address and largest integers
  expectEvent, // Assertions for emitted events
  expectRevert, // Assertions for transactions that should fail
} = require('@openzeppelin/test-helpers');
require('dotenv').config();

var Core = artifacts.require("Core");
var XMSToken = artifacts.require("XMSToken");

var BUSDGenesisEvent = artifacts.require("BUSDGenesisEvent");

var one = new BN("1000000000000000000");
module.exports = function (deployer, network, accounts) {
  deployer.then(async function () {
    var core;
    var busd;
    var xms;
    var pcvController;
    var busdLastPriceOracle;
    if (network == 'mainnet') {
      core = await Core.at(process.env.MAIN_DEPLOYED_CORE);
      xms = process.env.MAIN_DEPLOYED_XMS;
      busd = process.env.MAIN_BUSD_ADDRESS;
      pcvController = process.env.MAIN_DEPLOYED_BUSD_PCV_CONTROLLER;
      busdLastPriceOracle = process.env.MAIN_DEPLOYED_CHAINLINK_BUSD;
    } else if (network == 'testnet') {
      core = await Core.at(process.env.TEST_DEPLOYED_CORE);
      xms = process.env.TEST_DEPLOYED_XMS;
      busd = process.env.TEST_BUSD_ADDRESS;
      pcvController = process.env.TEST_DEPLOYED_BUSD_PCV_CONTROLLER;
      busdLastPriceOracle = process.env.TEST_DEPLOYED_CHAINLINK_BUSD;
    } else {
      core = await Core.at(process.env.DEV_DEPLOYED_CORE);
      xms = process.env.DEV_DEPLOYED_XMS;
      busd = process.env.DEV_BUSD_ADDRESS;
      pcvController = process.env.DEV_DEPLOYED_BUSD_PCV_CONTROLLER;
      busdLastPriceOracle = process.env.DEV_DEPLOYED_CHAINLINK_BUSD;
    }

    // core, pcvController, busd, duration, hours, cap, stakeToken, stakeTokenAllocPoint, busdAllocPoint, chainlink
    await deployer.deploy(BUSDGenesisEvent,
      core.address,
      pcvController,
      busd,
      7200,
      7 * 24,
      new BN(15000000).mul(one),
      // constants.ZERO_ADDRESS,
      // 0,
      // 0,
      xms,
      150,
      100,
      busdLastPriceOracle,
    );
    await core.grantMinter(BUSDGenesisEvent.address);
  });
}