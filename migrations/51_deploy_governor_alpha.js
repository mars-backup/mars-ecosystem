var XMSToken = artifacts.require("XMSToken");
var Timelock = artifacts.require("Timelock");

var GovernorAlpha = artifacts.require("GovernorAlpha");

var need = false;
module.exports = function (deployer, network, accounts) {
  if (need) {

    deployer.then(async function () {
      var xms;
      if (network == 'mainnet') {
        xms = await XMSToken.at(process.env.MAIN_DEPLOYED_XMS);
      } else if (network == 'testnet') {
        xms = await XMSToken.at(process.env.TEST_DEPLOYED_XMS);
      } else {
        xms = await XMSToken.at(process.env.DEV_DEPLOYED_XMS);
      }
      return deployer.deploy(GovernorAlpha,
        Timelock.address,
        xms.address,
        accounts[0]
      );
    });
  }
}