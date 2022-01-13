const {
  BN, // Big Number support
  constants, // Common constants, like the zero address and largest integers
  expectEvent, // Assertions for emitted events
  expectRevert, // Assertions for transactions that should fail
} = require('@openzeppelin/test-helpers');

var Core = artifacts.require("Core");

var IHO = artifacts.require("IHO");

var need = true;
module.exports = function (deployer, network, accounts) {
  if (need) {

    deployer.then(async () => {
      var xms;
      var core;
      if (network == 'mainnet') {
        core = await Core.at(process.env.MAIN_DEPLOYED_CORE);
      } else if (network == 'testnet') {
        core = await Core.at(process.env.TEST_DEPLOYED_CORE);
      } else {
        core = await Core.at(process.env.DEV_DEPLOYED_CORE);
      }

      if (network == 'mainnet') {
        xms = process.env.MAIN_DEPLOYED_XMS;
      } else if (network == 'testnet') {
        xms = process.env.TEST_DEPLOYED_XMS;
      } else {
        xms = process.env.DEV_DEPLOYED_XMS;
      }
      await deployer.deploy(IHO, core.address, process.env.XMS_TREASURY_ADDRESS, xms, "0x9ca057A0f9e4A03F285d00fe4DC18ce95243FD16", 0, 2 * 3600, 1);
  });
  }
}