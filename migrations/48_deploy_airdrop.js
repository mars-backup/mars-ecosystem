require('dotenv').config();

var Core = artifacts.require("Core");

var AirDrop = artifacts.require("AirDrop");

var need = true;
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
            var startBlock = 13244820;
            // var endBlock = startBlock + 600 / 3;
            var endBlock = 14972820;
            await deployer.deploy(AirDrop, core.address, process.env.XMS_TREASURY_ADDRESS, startBlock, endBlock);
        });
    }
}