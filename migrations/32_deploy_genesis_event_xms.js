const {
  BN, // Big Number support
  constants, // Common constants, like the zero address and largest integers
  expectEvent, // Assertions for emitted events
  expectRevert, // Assertions for transactions that should fail
} = require('@openzeppelin/test-helpers');
require('dotenv').config();

var Core = artifacts.require("Core");
var MarsSwapFactory = artifacts.require("MarsSwapFactory");

var XMSGenesisEvent = artifacts.require("XMSGenesisEvent");

var one = new BN("1000000000000000000");
module.exports = function (deployer, network, accounts) {
  deployer.then(async function () {
    var core;
    var wbnb;
    var bnbLastPriceOracle;
    var factory;
    if (network == 'mainnet') {
      core = await Core.at(process.env.MAIN_DEPLOYED_CORE);
      factory = process.env.MAIN_DEPLOYED_MARSSWAP_FACTORY;
      wbnb = process.env.MAIN_WBNB_ADDRESS;
      bnbLastPriceOracle = process.env.MAIN_DEPLOYED_CHAINLINK_WBNB;
    } else if (network == 'testnet') {
      core = await Core.at(process.env.TEST_DEPLOYED_CORE);
      factory = process.env.TEST_DEPLOYED_MARSSWAP_FACTORY;
      wbnb = process.env.TEST_WBNB_ADDRESS;
      bnbLastPriceOracle = process.env.TEST_DEPLOYED_CHAINLINK_WBNB;
    } else {
      core = await Core.at(process.env.DEV_DEPLOYED_CORE);
      factory = process.env.DEV_DEPLOYED_MARSSWAP_FACTORY;
      wbnb = process.env.DEV_WBNB_ADDRESS;
      bnbLastPriceOracle = process.env.DEV_DEPLOYED_CHAINLINK_WBNB;
    }

    // core, dev, duration, hours, cap, stakeToken, stakeTokenAllocPoint, xmsAllocPoint, chainlink, wbnb, factory
    await deployer.deploy(XMSGenesisEvent,
      core.address,
      "0xe2d993201BB92357Bb651d01a7Ca0CCa53535aeb",
      1800,
      2,
      new BN(1000000).mul(one),
      constants.ZERO_ADDRESS,
      0,
      0,
      bnbLastPriceOracle,
      wbnb,
      factory
    );
    await core.grantMinter(XMSGenesisEvent.address);
  });
}