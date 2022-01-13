require('dotenv').config();

var Core = artifacts.require("Core");
var MarsStake = artifacts.require("MarsStake");

var MarsStakeReward = artifacts.require("MarsStakeReward");

var need = false;
module.exports = function (deployer, network, accounts) {
    if (need) {

        deployer.then(async () => {
            var core;
            var stake;
            if (network == 'mainnet') {
                core = await Core.at(process.env.MAIN_DEPLOYED_CORE);
                stake = await MarsStake.at(process.env.MAIN_DEPLOYED_STAKE)
            } else if (network == 'testnet') {
                core = await Core.at(process.env.TEST_DEPLOYED_CORE);
                stake = await MarsStake.at(process.env.TEST_DEPLOYED_STAKE)
            } else {
                core = await Core.at(process.env.DEV_DEPLOYED_CORE);
                stake = await MarsStake.at(process.env.DEV_DEPLOYED_STAKE)
            }
            await deployer.deploy(MarsStakeReward, core.address, process.env.XMS_TREASURY_ADDRESS, stake.address, 24 * 3600, 360 / 2);
        });
    }
}