require('dotenv').config();

var Core = artifacts.require("Core");

var RandomAirDrop = artifacts.require("RandomAirDrop");

var need = false;
module.exports = function (deployer, network, accounts) {
    if (need) {

        deployer.then(async () => {
            var core;
            if (network == 'mainnet') {
                core = await Core.at(process.env.MAIN_DEPLOYED_CORE);
            } else if (network == 'testnet') {
                core = await Core.at(process.env.TEST_DEPLOYED_CORE);
            } else {
                core = await Core.at(process.env.DEV_DEPLOYED_CORE);
            }
            await deployer.deploy(RandomAirDrop, core.address, process.env.XMS_TREASURY_ADDRESS);
        });
    }
}