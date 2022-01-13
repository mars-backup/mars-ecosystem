const {
    BN
} = require('@openzeppelin/test-helpers');
const _ = require('lodash');

const bondingLCurveAddress = '0xE685Fa4154E4E3a03D0029f8CFE82d8194725a8D';
const idoAddress = '0xcFC9BaC161a3AEA799Df3C3DeC73ab1F2EEC57e6';
const busd2usdmAddress = '0x3Fc5Ee0B6F23c8b0feBfeF1e3bd6BFB6624aC750';
const xms2usdmAddress = '0xDDd109a7F58994d2Be04cF93c1BE4066E095c5e4';
const usdmAddress = '0x3a851f90bcCBF71061B3516C7BdB3a867385177D';
const xmsAddress = '0x70138966a7CcFd7DB437797126E547fcB21e69BC';
const busdGenesisGroupAddress = '0xe033ddbdBcF6448e5E9a9234361f2c34CAF182d3';
const busdUniswapPCVDepositAddress = '0xA5caeF1BFFDa1eBaCcB558eA8A5a73db244bb988';
const marsSwapRouterAddress = '0xC9261c7Ca765A1e1cf563ecab36C41a7B1a6B460';
const busdLastPriceOracleAddress = '0xCC2d00d2aaFb753F230a488cE9A5fb11Df93A55A';
const coreAddress = '0xcdCD82d41463C672D60c0CD89930070D469256f9';
const xmsRedemptionUnitAddress = '0x044CA7097aC5926114Bd64884b115c5D0f86f4ED';

const USDMToken = artifacts.require('USDMToken');
const XMSToken = artifacts.require('XMSToken');
const BUSDBondingLCurve = artifacts.require('BUSDBondingLCurve');
const IDO = artifacts.require('IDO');
const MarsSwapPair = artifacts.require('MarsSwapPair');
const BUSDGenesisGroup = artifacts.require('BUSDGenesisGroup');
const BUSDUniswapPCVDeposit = artifacts.require('BUSDUniswapPCVDeposit');
const MarsSwapRouter = artifacts.require('MarsSwapRouter');
const BUSDLastPriceOracle = artifacts.require('BUSDLastPriceOracle');

const one = new BN("1000000000000000000");

async function analytics() {
    const usdm = await USDMToken.at(usdmAddress);
    const xms = await XMSToken.at(xmsAddress);
    const bondingLCurve = await BUSDBondingLCurve.at(bondingLCurveAddress);
    const ido = await IDO.at(idoAddress);
    const busd2usdm = await MarsSwapPair.at(busd2usdmAddress);
    const xms2usdm = await MarsSwapPair.at(xms2usdmAddress);
    const busdGenesisGroup = await BUSDGenesisGroup.at(busdGenesisGroupAddress);
    const busdUniswapPCVDeposit = await BUSDUniswapPCVDeposit.at(busdUniswapPCVDepositAddress);
    const marsSwapRouter = await MarsSwapRouter.at(marsSwapRouterAddress);
    const busdLastPriceOracle = await BUSDLastPriceOracle.at(busdLastPriceOracleAddress);

    const l1 = await busd2usdm.balanceOf(busdUniswapPCVDeposit.address);
    const token10 = await busd2usdm.token0();
    const r1 = await busd2usdm.getReserves();
    const t1 = await busd2usdm.totalSupply();
    const u1 = l1.mul(token10 == usdm.address ? r1._reserve0 : r1._reserve1).div(t1);
    const b1 = l1.mul(token10 == usdm.address ? r1._reserve1 : r1._reserve0).div(t1);

    const l2 = await xms2usdm.balanceOf(ido.address);
    const token20 = await xms2usdm.token0();
    const r2 = await xms2usdm.getReserves();
    const t2 = await xms2usdm.totalSupply();
    const u2 = l2.mul(token20 == usdm.address ? r2._reserve0 : r2._reserve1).div(t2);
    const x2 = l2.mul(token20 == usdm.address ? r2._reserve1 : r2._reserve0).div(t2);

    // 1. USDM/BUSD
    const usdmOfBusd = await marsSwapRouter.quote(
        one,
        token10 == usdm.address ? r1._reserve0 : r1._reserve1,
        token10 == usdm.address ? r1._reserve1 : r1._reserve0
    );
    console.log(`USDM/BUSD: ${usdmOfBusd}`);

    // 2. USDM/USD
    const price = await busdLastPriceOracle.getLatestPrice();
    const usdmOfUsd = usdmOfBusd.mul(price[0]).div(new BN(10).pow(price[1]));
    console.log(`USDM/USD: ${usdmOfUsd}`);

    // 3. Mars Treasury Owned USDM
    const treasuryOwnedUSDM = u1.add(u2);
    const usdmTotal = await usdm.totalSupply();
    const userOwnedUSDM = usdmTotal.sub(treasuryOwnedUSDM);

    console.log(`Mas Treasury Owned USDM: ${treasuryOwnedUSDM.toString()}`);
    console.log(`User Owned USDM: ${userOwnedUSDM.toString()}`);

    // 4. XMS market price
    const xmsOfUsdm = await marsSwapRouter.quote(
        one,
        token20 == xms.address ? r2._reserve0 : r2._reserve1,
        token20 == xms.address ? r2._reserve1 : r2._reserve0
    );

    const xmsPrice = xmsOfUsdm.mul(usdmOfUsd).div(one);
    console.log(`XMS market price: ${xmsPrice}`);

    // 5. Mars Treasury Value
    
    const b = await bondingLCurve.getTotalPCVHeld();
    const xcore = await xms.balanceOf(coreAddress);
    const xredemption = await xms.balanceOf(xmsRedemptionUnitAddress);
    const v1 = xcore.add(xredemption).mul(xmsPrice).div(one);
    const v2 = b.mul(price[0]).div(new BN(10).pow(price[1]));
    const v3 = x2.mul(xmsPrice).div(one);
    const v4 = b1.mul(price[0]).div(new BN(10).pow(price[1]));
    const treasuryValue = v1.add(v2).add(v3).add(v4);
    console.log(`Mars Treasury Value: ${treasuryValue}`);
    // 6. Mars Treasury Support Ratio

    const ratio = treasuryValue.mul(one).div(userOwnedUSDM);
    console.log(`Mars Treasury Support Ratio: ${ratio}`);
}

module.exports = function() {
    analytics()
    .then(() => {
        console.log('done.');
        process.exit(0);
    })
    .catch(e => {
        console.log(e.toString());
    });
}