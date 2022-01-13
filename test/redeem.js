const {
    BN
} = require('@openzeppelin/test-helpers');
const _ = require('lodash');

const one = new BN("1000000000000000000");

const xmsRedemptionUnitAddress = '0x044CA7097aC5926114Bd64884b115c5D0f86f4ED';
const usdmAddress = '0x3a851f90bcCBF71061B3516C7BdB3a867385177D';

const USDMToken = artifacts.require('USDMToken');
const XMSRedemptionUnit = artifacts.require('XMSRedemptionUnit');

async function main() {
    const usdm = await USDMToken.at(usdmAddress);
    const xmsRedemptionUnit = await XMSRedemptionUnit.at(xmsRedemptionUnitAddress);

    const price = await xmsRedemptionUnit.getCurrentPrice();
    console.log(`${price.toString()} XMS per USDM`);
    console.log(`${one.mul(one).div(new BN(price.toString()))} USDM per XMS`);
}

module.exports = function() {
    main()
    .then(() => {
        console.log('done.');
        process.exit(0);
    })
    .catch(e => {
        console.log(e.toString());
    });
}