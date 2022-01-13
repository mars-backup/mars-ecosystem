const {
  BN, // Big Number support
  constants, // Common constants, like the zero address and largest integers
  expectEvent, // Assertions for emitted events
  expectRevert, // Assertions for transactions that should fail
} = require('@openzeppelin/test-helpers');

var Core = artifacts.require("Core");
var IMO = artifacts.require("IMO");

var one = new BN("1000000000000000000");

var need = false;
module.exports = function (deployer, network, accounts) {
  if (need) {

    deployer.then(async () => {
      if (network != 'mainnet') {

        var core = await Core.at(process.env.TEST_DEPLOYED_CORE);
        await core.allocateXMS(IMO.address, one.mul(new BN("15772947")));
      }
    });
  }
}