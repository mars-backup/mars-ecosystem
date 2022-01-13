const {
  BN, // Big Number support
  constants, // Common constants, like the zero address and largest integers
  expectEvent, // Assertions for emitted events
  expectRevert, // Assertions for transactions that should fail
  time
} = require('@openzeppelin/test-helpers');

var Core = artifacts.require("Core");

module.exports = function (deployer, network, accounts) {
  deployer.then(async function () {
    var core = await deployer.deploy(Core);
  });
}