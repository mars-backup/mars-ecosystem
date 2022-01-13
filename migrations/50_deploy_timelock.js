var Timelock = artifacts.require("Timelock");

var need = true;
module.exports = function (deployer, network, accounts) {
  if (need) {

    deployer.then(async function () {
      return deployer.deploy(Timelock,
        accounts[0],
        3600 * 1
      );
    });
  }
}