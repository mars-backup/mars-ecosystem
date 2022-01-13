const {
  BN, // Big Number support
  constants, // Common constants, like the zero address and largest integers
  expectEvent, // Assertions for emitted events
  expectRevert, // Assertions for transactions that should fail
} = require('@openzeppelin/test-helpers');
require('dotenv').config();

var Core = artifacts.require("Core");
var BUSDBondingLCurve = artifacts.require("BUSDBondingLCurve");

var BUSDGenesisGroup = artifacts.require("BUSDGenesisGroup");

var one = new BN("1000000000000000000");
module.exports = function (deployer, network, accounts) {
  deployer.then(async function () {
    var core;
    var xms;
    if (network == 'mainnet') {
      core = await Core.at(process.env.MAIN_DEPLOYED_CORE);
      xms = process.env.MAIN_DEPLOYED_XMS;
    } else if (network == 'testnet') {
      core = await Core.at(process.env.TEST_DEPLOYED_CORE);
      xms = process.env.TEST_DEPLOYED_XMS;
    } else {
      core = await Core.at(process.env.DEV_DEPLOYED_CORE);
      xms = process.env.DEV_DEPLOYED_XMS;
    }

    var busd;
    if (network == 'mainnet') {
      busd = process.env.MAIN_BUSD_ADDRESS;
    } else if (network == 'testnet') {
      busd = process.env.TEST_BUSD_ADDRESS;
    } else {
      busd = process.env.DEV_BUSD_ADDRESS;
    }
    // core, busd, bondingCurve, duration, hours, cap, stakeToken, stakeTokenAllocPoint, busdAllocPoint
    await deployer.deploy(BUSDGenesisGroup,
      core.address,
      busd,
      BUSDBondingLCurve.address,
      7200,
      7 * 24,
      new BN(5000000).mul(one),
      xms,
      200,
      100
    );
    await core.setGenesisGroup(BUSDGenesisGroup.address);
  });
}