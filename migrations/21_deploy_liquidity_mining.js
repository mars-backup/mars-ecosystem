const {
  BN, // Big Number support
  constants, // Common constants, like the zero address and largest integers
  expectEvent, // Assertions for emitted events
  expectRevert, // Assertions for transactions that should fail
} = require('@openzeppelin/test-helpers');
require('dotenv').config();

var Core = artifacts.require("Core");
var XMSToken = artifacts.require("XMSToken");

var VestingMaster = artifacts.require("VestingMaster");
var LiquidityMiningMaster = artifacts.require("LiquidityMiningMaster");

var one = new BN("1000000000000000000");
module.exports = function (deployer, network, accounts) {
  deployer.then(async function () {
    var core;
    var xms;
    if (network == 'mainnet') {
      core = await Core.at(process.env.MAIN_DEPLOYED_CORE);
      xms = await XMSToken.at(process.env.MAIN_DEPLOYED_XMS);
    } else if (network == 'testnet') {
      core = await Core.at(process.env.TEST_DEPLOYED_CORE);
      xms = await XMSToken.at(process.env.TEST_DEPLOYED_XMS);
    } else {
      core = await Core.at(process.env.DEV_DEPLOYED_CORE);
      xms = await XMSToken.at(process.env.DEV_DEPLOYED_XMS);
    }
    // await deployer.deploy(VestingMaster, core.address, 3600 * 24 * 6, 29, xms.address);
    // core, vestingMaster, rewardToken, tokenPerBlock, startBlock, endBlock, name, symbol
    await deployer.deploy(LiquidityMiningMaster,
      core.address,
      constants.ZERO_ADDRESS,
      "0xBb0fA2fBE9b37444f5D1dBD22e0e5bdD2afbbE85",
      new BN("347").mul(one).div(new BN(1000)),
      13726400,
      31272476
      // 61272476
    );
    await core.grantRole(web3.utils.keccak256("FARMS_ROLE"), LiquidityMiningMaster.address);
  });
}