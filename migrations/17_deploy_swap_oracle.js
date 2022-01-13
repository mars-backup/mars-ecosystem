const {
    BN, // Big Number support
    constants, // Common constants, like the zero address and largest integers
    expectEvent, // Assertions for emitted events
    expectRevert, // Assertions for transactions that should fail
} = require('@openzeppelin/test-helpers');

var Core = artifacts.require("Core");
var MarsSwapFactory = artifacts.require("MarsSwapFactory");

var SwapMiningOracle = artifacts.require("SwapMiningOracle");

module.exports = function (deployer, network, accounts) {
    deployer.then(async () => {
        var core;
        var factory;
        if (network == 'mainnet') {
            core = await Core.at(process.env.MAIN_DEPLOYED_CORE);
            factory = await MarsSwapFactory.at(process.env.MAIN_DEPLOYED_MARSSWAP_FACTORY);
        } else if (network == 'testnet') {
            core = await Core.at(process.env.TEST_DEPLOYED_CORE);
            factory = await MarsSwapFactory.at(process.env.TEST_DEPLOYED_MARSSWAP_FACTORY);
        } else {
            core = await Core.at(process.env.DEV_DEPLOYED_CORE);
            factory = await MarsSwapFactory.at(process.env.DEV_DEPLOYED_MARSSWAP_FACTORY);
        }

        return deployer.deploy(SwapMiningOracle, core.address, factory.address);
    });
}