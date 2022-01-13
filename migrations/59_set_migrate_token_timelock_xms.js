const {
  BN, // Big Number support
  constants, // Common constants, like the zero address and largest integers
  expectEvent, // Assertions for emitted events
  expectRevert, // Assertions for transactions that should fail
  time
} = require('@openzeppelin/test-helpers');

var Core = artifacts.require("Core");
var MigrateTokenTimelock = artifacts.require("MigrateTokenTimelock");

var one = new BN("1000000000000000000");
var need = false;
module.exports = function (deployer, network, accounts) {
  if (need) {
    deployer.then(async function () {
      var core;
      if (network == 'mainnet') {
        core = await Core.at(process.env.MAIN_DEPLOYED_CORE);
      } else if (network == 'testnet') {
        core = await Core.at(process.env.TEST_DEPLOYED_CORE);
      } else {
        core = await Core.at(process.env.DEV_DEPLOYED_CORE);
      }

      var migrate = await MigrateTokenTimelock.deployed();
      var lockInstances = await migrate.getAddress();
      console.log(lockInstances);
      // await core.allocateXMS(lockInstances[0], new BN(10).pow(new BN(8)).mul(one));
      // await core.allocateXMS(lockInstances[1], new BN(10).pow(new BN(8)).mul(one));
      await migrate.initialize();
    });
  }
}