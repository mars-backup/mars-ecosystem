const {
  BN, // Big Number support
  constants, // Common constants, like the zero address and largest integers
  expectEvent, // Assertions for emitted events
  expectRevert, // Assertions for transactions that should fail
} = require('@openzeppelin/test-helpers');
require('dotenv').config();

var Core = artifacts.require("Core");

var XMSRedemptionUnit = artifacts.require("XMSRedemptionUnit");

module.exports = function (deployer, network, accounts) {
  deployer.then(async function () {
    var core;
    if (network == 'mainnet') {
      core = await Core.at(process.env.MAIN_DEPLOYED_CORE);
    } else if (network == 'testnet') {
      core = await Core.at(process.env.TEST_DEPLOYED_CORE);
    } else {
      core = await Core.at(process.env.DEV_DEPLOYED_CORE);
    }
    return deployer.deploy(XMSRedemptionUnit,
      core.address,
      "0x1a4749172e40D4Ca21eDc562C35c0d3a0aFCc525",
      [
        constants.ZERO_ADDRESS,
        constants.ZERO_ADDRESS,
        constants.ZERO_ADDRESS,
        constants.ZERO_ADDRESS
      ]);
  });
}