const {
  BN, // Big Number support
  constants, // Common constants, like the zero address and largest integers
  expectEvent, // Assertions for emitted events
  expectRevert, // Assertions for transactions that should fail
} = require('@openzeppelin/test-helpers');

var Core = artifacts.require("Core");
var BUSDUniswapPCVDeposit = artifacts.require("BUSDUniswapPCVDeposit");
var BUSDBondingLCurve = artifacts.require("BUSDBondingLCurve");

var BUSDUniswapPCVController = artifacts.require("BUSDUniswapPCVController");

module.exports = function (deployer, network, accounts) {
  deployer.then(async function () {
    var core;
    var busd;
    if (network == 'mainnet') {
      core = await Core.at(process.env.MAIN_DEPLOYED_CORE);
      busd = process.env.MAIN_BUSD_ADDRESS;
    } else if (network == 'testnet') {
      core = await Core.at(process.env.TEST_DEPLOYED_CORE);
      busd = process.env.TEST_BUSD_ADDRESS;
    } else {
      core = await Core.at(process.env.DEV_DEPLOYED_CORE);
      busd = process.env.DEV_BUSD_ADDRESS;
    }
    
    await deployer.deploy(BUSDUniswapPCVController, core.address, busd, "0x343BD1bE0C557043ee2b31bb9a99DD4b6c585455", BUSDBondingLCurve.address);
    await core.grantPCVController(BUSDUniswapPCVController.address);
  });
}