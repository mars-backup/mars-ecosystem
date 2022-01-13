const {
    BN, // Big Number support
    constants, // Common constants, like the zero address and largest integers
    expectEvent, // Assertions for emitted events
    expectRevert, // Assertions for transactions that should fail
    time
} = require('@openzeppelin/test-helpers');
require('dotenv').config();

var XMSToken = artifacts.require("XMSToken");
var USDMToken = artifacts.require("USDMToken");
var MarsSwapFactory = artifacts.require("MarsSwapFactory");

module.exports = function (deployer, network, accounts) {
    deployer.then(async () => {
        var factory;
        var xms;
        if (network == 'mainnet') {
            factory = await MarsSwapFactory.at(process.env.MAIN_DEPLOYED_MARSSWAP_FACTORY);
            xms = await XMSToken.at(process.env.MAIN_DEPLOYED_XMS);
        } else if (network == 'testnet') {
            factory = await MarsSwapFactory.at(process.env.TEST_DEPLOYED_MARSSWAP_FACTORY);
            xms = await XMSToken.at(process.env.TEST_DEPLOYED_XMS);
        } else {
            factory = await MarsSwapFactory.at(process.env.DEV_DEPLOYED_MARSSWAP_FACTORY);
            xms = await XMSToken.at(process.env.DEV_DEPLOYED_XMS);
        }

        var busd;
        var wbnb;
        if (network == 'mainnet') {
            busd = process.env.MAIN_BUSD_ADDRESS;
            wbnb = process.env.MAIN_WBNB_ADDRESS;
        } else if (network == 'testnet') {
            busd = process.env.TEST_BUSD_ADDRESS;
            wbnb = process.env.TEST_WBNB_ADDRESS;
        } else {
            busd = process.env.DEV_BUSD_ADDRESS;
            wbnb = process.env.DEV_WBNB_ADDRESS;
        }
        var busd2usdm = await factory.getPair(busd, USDMToken.address);
        if (busd2usdm == constants.ZERO_ADDRESS) {
            await factory.createPair(busd, USDMToken.address);
            busd2usdm = await factory.getPair(busd, USDMToken.address);
        }
        console.log("BUSD/USDM");
        console.log(busd2usdm);
        var xms2usdm = await factory.getPair(xms.address, USDMToken.address);
        if (xms2usdm == constants.ZERO_ADDRESS) {
            await factory.createPair(xms.address, USDMToken.address);
            xms2usdm = await factory.getPair(xms.address, USDMToken.address);
        }
        console.log("XMS/USDM");
        console.log(xms2usdm);

        var xms2wbnb = await factory.getPair(xms.address, wbnb);
        if (xms2wbnb == constants.ZERO_ADDRESS) {
            await factory.createPair(xms.address, wbnb);
            xms2wbnb = await factory.getPair(xms.address, wbnb);
        }
        console.log("XMS/BNB");
        console.log(xms2wbnb);
    });
}