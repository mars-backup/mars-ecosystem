require('dotenv').config();

var Core = artifacts.require("Core");

var VestingAirDrop = artifacts.require("VestingAirDrop");

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
            await deployer.deploy(VestingAirDrop,
                core.address,
                process.env.XMS_TREASURY_ADDRESS,
                "0x381Facb9282770a5E3Ac6c8637096b442039C3dB");
            await core.grantRole(web3.utils.keccak256("FARMS_ROLE"), VestingAirDrop.address);
        });
    }
}