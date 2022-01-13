const {
    BN, // Big Number support
    constants, // Common constants, like the zero address and largest integers
    expectEvent, // Assertions for emitted events
    expectRevert, // Assertions for transactions that should fail
} = require('@openzeppelin/test-helpers');
require('dotenv').config();

var BUSDLastPriceOracle = artifacts.require("BUSDLastPriceOracle");
var MockBUSDLastPriceOracle = artifacts.require("MockBUSDLastPriceOracle");

var need = true;
module.exports = function (deployer, network, accounts) {
    if (need) {

        deployer.then(() => {
            if (network == 'mainnet') {
                return deployer.deploy(BUSDLastPriceOracle, process.env.MAIN_BUSD_CHAIN_LINK_ADDRESS, process.env.MAIN_BUSD_ADDRESS);
            } else if (network == 'testnet') {
                return deployer.deploy(BUSDLastPriceOracle, process.env.TEST_BUSD_CHAIN_LINK_ADDRESS, process.env.TEST_BUSD_ADDRESS);
            } else {
                return deployer.deploy(MockBUSDLastPriceOracle, process.env.DEV_BUSD_CHAIN_LINK_ADDRESS, process.env.DEV_BUSD_ADDRESS);
            }
        });
    }
}