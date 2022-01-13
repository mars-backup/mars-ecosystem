require('dotenv').config();

var Core = artifacts.require("Core");

var MarsSwapFactory = artifacts.require("MarsSwapFactory");

module.exports = function (deployer, network, accounts) {
    deployer.then(async () => {
        var core;
        if (network == 'mainnet') {
            core = await Core.at(process.env.MAIN_DEPLOYED_CORE);
        } else if (network == 'testnet') {
            core = await Core.at(process.env.TEST_DEPLOYED_CORE);
        } else {
            core = await Core.at(process.env.DEV_DEPLOYED_CORE);
        }
        var factory = await deployer.deploy(MarsSwapFactory, core.address);
        await factory.setFeeTo(process.env.XMS_TREASURY_ADDRESS);
    });
}