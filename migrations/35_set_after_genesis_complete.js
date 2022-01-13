const {
  BN, // Big Number support
  constants, // Common constants, like the zero address and largest integers
  expectEvent, // Assertions for emitted events
  expectRevert, // Assertions for transactions that should fail
} = require('@openzeppelin/test-helpers');

var Core = artifacts.require("Core");
var XMSRedemptionUnit = artifacts.require("XMSRedemptionUnit");
var OracleIncentives = artifacts.require("OracleIncentives");

module.exports = function (deployer, network, accounts) {
  deployer.then(async () => {
    var core;
    var xmsRedemptionUnit;
    if (network == 'mainnet') {
      core = await Core.at(process.env.MAIN_DEPLOYED_CORE);
      xmsRedemptionUnit = await XMSRedemptionUnit.at(process.env.MAIN_DEPLOYED_XMS_REDEMPTION_UTIL);
    } else if (network == 'testnet') {
      core = await Core.at(process.env.TEST_DEPLOYED_CORE);
      xmsRedemptionUnit = await XMSRedemptionUnit.at(process.env.TEST_DEPLOYED_XMS_REDEMPTION_UTIL);
    } else {
      core = await Core.at(process.env.DEV_DEPLOYED_CORE);
      xmsRedemptionUnit = await XMSRedemptionUnit.at(process.env.DEV_DEPLOYED_XMS_REDEMPTION_UTIL);
    }

    var complete = await core.hasGenesisGroupCompleted();
    if (complete == true) {
      await deployer.then(async () => {
        var oracleIncentives = await OracleIncentives.deployed();
        await oracleIncentives.unpause();
        await xmsRedemptionUnit.unpause();
      });
    }
  });

}