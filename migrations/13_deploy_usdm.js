const {
  BN, // Big Number support
  constants, // Common constants, like the zero address and largest integers
  expectEvent, // Assertions for emitted events
  expectRevert, // Assertions for transactions that should fail
  time
} = require('@openzeppelin/test-helpers');

var Core = artifacts.require("Core");

var USDMToken = artifacts.require("USDMToken");

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
    await deployer.deploy(USDMToken, core.address);
    await core.setUSDM(USDMToken.address);
  });
}