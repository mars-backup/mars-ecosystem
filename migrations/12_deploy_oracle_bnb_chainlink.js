const {
    BN, // Big Number support
    constants, // Common constants, like the zero address and largest integers
    expectEvent, // Assertions for emitted events
    expectRevert, // Assertions for transactions that should fail
} = require('@openzeppelin/test-helpers');
require('dotenv').config();

var BNBLastPriceOracle = artifacts.require("BNBLastPriceOracle");
var MockBNBLastPriceOracle = artifacts.require("MockBNBLastPriceOracle");

var need = true;
module.exports = function (deployer, network, accounts) {
    if (need) {
        deployer.then(() => {
            if (network == 'mainnet') {
                return deployer.deploy(BNBLastPriceOracle, process.env.MAIN_WBNB_CHAIN_LINK_ADDRESS, process.env.MAIN_WBNB_ADDRESS);
            } else if (network == 'testnet') {
                return deployer.deploy(BNBLastPriceOracle, process.env.TEST_WBNB_CHAIN_LINK_ADDRESS, process.env.TEST_WBNB_ADDRESS);
            } else {
                return deployer.deploy(MockBNBLastPriceOracle, process.env.DEV_WBNB_CHAIN_LINK_ADDRESS, process.env.DEV_WBNB_ADDRESS);
            }
        });
    }
}