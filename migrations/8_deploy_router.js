const {
  BN, // Big Number support
  constants, // Common constants, like the zero address and largest integers
  expectEvent, // Assertions for emitted events
  expectRevert, // Assertions for transactions that should fail
} = require('@openzeppelin/test-helpers');
require('dotenv').config();

var Core = artifacts.require("Core");
var MarsSwapFactory = artifacts.require("MarsSwapFactory");

var MarsSwapRouter = artifacts.require("MarsSwapRouter");

module.exports = function (deployer, network, accounts) {
  deployer.then(async () => {
    var core;
    if (network == 'mainnet') {
      core = await Core.at(process.env.MAIN_DEPLOYED_CORE);
    } else if (network == 'testnet') {
      core = await Core.at(process.env.TEST_DEPLOYED_CORE);
    } else {
      core = await Core.at(process.env.DEV_DEPLOYED_CORE);
    }
    // core, factory, weth, swapMining
    var wbnb;
    if (network == 'mainnet') {
      wbnb = process.env.MAIN_WBNB_ADDRESS;
    } else if (network == 'testnet') {
      wbnb = process.env.TEST_WBNB_ADDRESS;
    } else {
      wbnb = process.env.DEV_WBNB_ADDRESS;
    }
    await deployer.deploy(MarsSwapRouter, core.address, MarsSwapFactory.address, wbnb, constants.ZERO_ADDRESS);
  });
}