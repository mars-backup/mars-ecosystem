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

module.exports = function (deployer, network, accounts) {
  deployer.then(async function () {
    console.log("Core");
    console.log(Core.address);
    if (network == "mainnet") {
      await deployer.deploy(XMSToken, process.env.XMS_TREASURY_ADDRESS, Core.address);
    } else {
      await deployer.deploy(XMSToken, Core.address, Core.address);
    }
    var core = await Core.deployed();
    await core.setXMS(XMSToken.address);
  });
}