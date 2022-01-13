const {
  BN, // Big Number support
  constants, // Common constants, like the zero address and largest integers
  expectEvent, // Assertions for emitted events
  expectRevert, // Assertions for transactions that should fail
} = require('@openzeppelin/test-helpers');

var Core = artifacts.require("Core");

var IMO = artifacts.require("IMO");

var need = false;
module.exports = function (deployer, network, accounts) {
  if (need) {

    deployer.then(async () => {
      var busd;
      var core;
      if (network == 'mainnet') {
        core = await Core.at(process.env.MAIN_DEPLOYED_CORE);
      } else if (network == 'testnet') {
        core = await Core.at(process.env.TEST_DEPLOYED_CORE);
      } else {
        core = await Core.at(process.env.DEV_DEPLOYED_CORE);
      }

      if (network == 'mainnet') {
        busd = process.env.MAIN_BUSD_ADDRESS;
      } else if (network == 'testnet') {
        busd = process.env.TEST_BUSD_ADDRESS;
      } else {
        busd = process.env.DEV_BUSD_ADDRESS;
      }
      await deployer.deploy(IMO, core.address, process.env.XMS_TREASURY_ADDRESS, busd, 24 * 3600, 360 / 2);
    });
  }
}