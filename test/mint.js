const {
    BN
} = require('@openzeppelin/test-helpers');
const _ = require('lodash');

const one = new BN("1000000000000000000");

const bondingLCurveAddress = '0xE685Fa4154E4E3a03D0029f8CFE82d8194725a8D';
const usdmAddress = '0x3a851f90bcCBF71061B3516C7BdB3a867385177D';

const USDMToken = artifacts.require('USDMToken');
const BUSDBondingLCurve = artifacts.require('BUSDBondingLCurve');

async function main() {
    const usdm = await USDMToken.at(usdmAddress);
    const bondingLCurve = await BUSDBondingLCurve.at(bondingLCurveAddress);

    const cap = await bondingLCurve.getUSDMSupplyCap();
    const total = await usdm.totalSupply();
    const limit = cap.sub(total);

    console.log(`Mintage Control Value: ${limit.toString()}`);

    const price = await bondingLCurve.getCurrentPrice();
    console.log(`${price.toString()} USDM per BUSD`);
    console.log(`${one.mul(one).div(new BN(price.toString()))} BUSD per USDM`);

    const amount = one.muln(10000);
    const amountOut = await bondingLCurve.getAmountOut(amount);
    const amountIn = await bondingLCurve.getAmountIn(amount);
    console.log(`amount out: ${amountOut}`);
    console.log(`amount in: ${amountIn}`);
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
