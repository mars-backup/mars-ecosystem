const {
    BN, // Big Number support
    constants, // Common constants, like the zero address and largest integers
    expectEvent, // Assertions for emitted events
    expectRevert, // Assertions for transactions that should fail
} = require('@openzeppelin/test-helpers');
require('dotenv').config();

var Core = artifacts.require("Core");

var MarsStakeReward = artifacts.require("MarsStakeReward");

var one = new BN("1000000000000000000");

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
            // await core.allocateXMS(MarsStakeReward.address, new BN(461501).mul(one));
            var marsStakeReward = await MarsStakeReward.deployed();
            await marsStakeReward.initialize();
        });
    }
}