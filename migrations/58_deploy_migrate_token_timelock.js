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

var MigrateTokenTimelock = artifacts.require("MigrateTokenTimelock");

var need = false;
module.exports = function (deployer, network, accounts) {
  if (need) {
    deployer.then(async function () {
      var core;
      var xms;
      if (network == 'mainnet') {
        core = await Core.at(process.env.MAIN_DEPLOYED_CORE);
        xms = await XMSToken.at(process.env.MAIN_DEPLOYED_XMS);
      } else if (network == 'testnet') {
        core = await Core.at(process.env.TEST_DEPLOYED_CORE);
        xms = await XMSToken.at(process.env.TEST_DEPLOYED_XMS);
      } else {
        core = await Core.at(process.env.DEV_DEPLOYED_CORE);
        xms = await XMSToken.at(process.env.DEV_DEPLOYED_XMS);
      }
      await deployer.deploy(MigrateTokenTimelock, core.address, xms.address, process.env.DEV_ADDRESS, time.duration.years(3), process.env.INVESTOR_ADDRESS, time.duration.days(180 + 265));
    });
  }
}