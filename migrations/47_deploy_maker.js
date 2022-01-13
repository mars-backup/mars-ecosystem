require('dotenv').config();

var Core = artifacts.require("Core");
var MarsSwapFactory = artifacts.require("MarsSwapFactory");
var MarsStake = artifacts.require("MarsStake");

var MarsMaker = artifacts.require("MarsMaker");

var need = false;
module.exports = function (deployer, network, accounts) {
    if (need) {

        deployer.then(async () => {
            var core;
            var factory;
            var stake;
            if (network == 'mainnet') {
                core = await Core.at(process.env.MAIN_DEPLOYED_CORE);
                factory = await MarsSwapFactory.at(process.env.MAIN_DEPLOYED_MARSSWAP_FACTORY);
                stake = await MarsStake.at(process.env.MAIN_DEPLOYED_STAKE);
            } else if (network == 'testnet') {
                core = await Core.at(process.env.TEST_DEPLOYED_CORE);
                factory = await MarsSwapFactory.at(process.env.TEST_DEPLOYED_MARSSWAP_FACTORY);
                stake = await MarsStake.at(process.env.TEST_DEPLOYED_STAKE);
            } else {
                core = await Core.at(process.env.DEV_DEPLOYED_CORE);
                factory = await MarsSwapFactory.at(process.env.DEV_DEPLOYED_MARSSWAP_FACTORY);
                stake = await MarsStake.at(process.env.DEV_DEPLOYED_STAKE);
            }

            var wbnb;
            if (network == 'mainnet') {
                wbnb = process.env.MAIN_WBNB_ADDRESS;
            } else if (network == 'testnet') {
                wbnb = process.env.TEST_WBNB_ADDRESS;
            } else {
                wbnb = process.env.DEV_WBNB_ADDRESS;
            }
            // core, factory, stake, weth
            await deployer.deploy(MarsMaker,
                core.address,
                factory.address,
                stake.address,
                wbnb);
        });
    }
}