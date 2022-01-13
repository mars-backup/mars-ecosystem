const {
    BN,
    constants
} = require('@openzeppelin/test-helpers');
const { ZERO_ADDRESS } = constants;

const BUSDGenesisGroup = artifacts.require('BUSDGenesisGroup');
const Core = artifacts.require('Core');
const TERC20 = artifacts.require('TERC20');
const BUSDBondingLCurve = artifacts.require('BUSDBondingLCurve');
const USDMToken = artifacts.require('USDMToken');
const XMSToken = artifacts.require('XMSToken');
const MarsSwapFactory = artifacts.require('MarsSwapFactory');
const MarsSwapRouter = artifacts.require('MarsSwapRouter');
const MarsStake = artifacts.require('MarsStake');
const MockBUSDLastPriceOracle = artifacts.require("MockBUSDLastPriceOracle");
const MockBNBLastPriceOracle = artifacts.require("MockBNBLastPriceOracle");
const SwapMiningOracle = artifacts.require("SwapMiningOracle");
const SwapMining = artifacts.require("SwapMining");
const LiquidityMiningMaster = artifacts.require("LiquidityMiningMaster");
const BUSDUniswapPCVDeposit = artifacts.require("BUSDUniswapPCVDeposit");
const BUSDUniswapPCVController = artifacts.require("BUSDUniswapPCVController");
const XMSRedemptionUnit = artifacts.require("XMSRedemptionUnit");
const IDO = artifacts.require("IDO");
const MockXMSLastPriceOracle = artifacts.require("MockXMSLastPriceOracle");

const busd_chainlink = ZERO_ADDRESS; // TODO:
const bnb_chainlink = ZERO_ADDRESS; // TODO

const zero = new BN(0);
const one = new BN("1000000000000000000");
const SWAP_MINING_REWARD = 1;
const LP_MINING_REWARD = 1;
const LP_MINING_START_BLOCK = 0;
const LP_MINING_END_BLOCK = 9999999999999;
const BONDINGCURVE_INCENTIVE_DURATION = 24 * 3600;
const BONDINGCURVE_INCENTIVES = 10;
const GENESIS_GROUP_DURATION = 100;

async function deploy(accounts) {
    const [ owner, minter, feeTo, attacker ] = accounts;
    const wbnb = await TERC20.new('WBNB', 'WBNB');
    const busd = await TERC20.new('BUSD', 'BUSD');

    const core = await Core.new();
    const xms = await XMSToken.new(core.address, core.address);
    await core.setXMS(xms.address);
    
    const factory = await MarsSwapFactory.new(core.address);
    await factory.setFeeTo(feeTo);

    const router = await MarsSwapRouter.new(core.address, factory.address, wbnb.address, ZERO_ADDRESS);
    const stake = await MarsStake.new(xms.address);
    const busdLastPriceOracle = await MockBUSDLastPriceOracle.new(busd_chainlink, busd.address);
    const bnbLastPriceOracle = await MockBNBLastPriceOracle.new(bnb_chainlink, wbnb.address);
    const usdm = await USDMToken.new(core.address);
    await core.setUSDM(usdm.address);

    let busd2usdm = await factory.getPair(busd.address, usdm.address);
    if (busd2usdm == ZERO_ADDRESS) {
        await factory.createPair(busd.address, usdm.address);
        busd2usdm = await factory.getPair(busd.address, usdm.address);
    }

    let xms2usdm = await factory.getPair(xms.address, usdm.address);
    if (xms2usdm == ZERO_ADDRESS) {
        await factory.createPair(xms.address, usdm.address);
        xms2usdm = await factory.getPair(xms.address, usdm.address);
    }

    const swapMiningOracle = await SwapMiningOracle.new(core.address, factory.address);

    const swapMining = await SwapMining.new(
        core.address,
        factory.address,
        swapMiningOracle.address,
        router.address,
        xms.address,
        new BN(SWAP_MINING_REWARD).mul(one),
        0
    );

    await router.setSwapMining(swapMining.address);
    await swapMining.addWhitelist(xms.address);
    await swapMining.addWhitelist(usdm.address);
    await swapMining.addWhitelist(busd.address);
    await core.approveXMS(swapMining.address, one.muln(10000000));
    
    const lpMining = await LiquidityMiningMaster.new(
        core.address,
        one.muln(LP_MINING_REWARD),
        LP_MINING_START_BLOCK,
        LP_MINING_END_BLOCK
    );

    await lpMining.addPool(20, xms.address, true);
    await core.approveXMS(lpMining.address, one.muln(10000000));

    const busdUniswapPCVDeposit = await BUSDUniswapPCVDeposit.new(
        core.address,
        busdLastPriceOracle.address,
        busd2usdm,
        router.address,
        factory.address,
        busd.address,
        lpMining.address
    );

    const busdBondingLCurve = await BUSDBondingLCurve.new(
        core.address,
        ZERO_ADDRESS,
        ZERO_ADDRESS,
        busd2usdm,
        router.address,
        factory.address,
        [ busdUniswapPCVDeposit.address ],
        [ 10000 ],
        BONDINGCURVE_INCENTIVE_DURATION,
        one.muln(BONDINGCURVE_INCENTIVES)
    );
    await busdBondingLCurve.initialize(busd.address, busdLastPriceOracle.address);
    
    const busdUniswapPCVController = await BUSDUniswapPCVController.new(
        core.address,
        busdUniswapPCVDeposit.address
    );

    const mockXMSLastPriceOracle = await MockXMSLastPriceOracle.new();

    const xmsRedemptionUnit = await XMSRedemptionUnit.new(
        core.address,
        mockXMSLastPriceOracle.address,
        ZERO_ADDRESS
    );

    const ido = await IDO.new(
        core.address,
        xms2usdm,
        router.address,
        factory.address
    );

    const busdGenesisGroup = await BUSDGenesisGroup.new(
        core.address,
        busd.address,
        busdBondingLCurve.address,
        ido.address,
        GENESIS_GROUP_DURATION
    );

    await core.allocateXMS(busdGenesisGroup.address, one.muln(1000000));
    await core.allocateXMS(ido.address, one.muln(1000000));
    await core.allocateXMS(xmsRedemptionUnit.address, one.muln(1000000));
    await core.setApprovedPairAndContract(busd2usdm, busdUniswapPCVController.address);
    await core.setApprovedPairAndContract(xms2usdm, ido.address);
    await core.setGenesisGroup(busdGenesisGroup.address);
    await core.grantMinter(ido.address);
    await core.grantMinter(busdUniswapPCVDeposit.address);
    await core.grantMinter(busdBondingLCurve.address);

    await core.grantMinter(owner);
    //await core.allocateXMS(owner, one.muln(10000000));
    //await usdm.mint(owner, one.muln(10000000));
    await lpMining.addPool(20, xms2usdm, true);
    await lpMining.addPool(20, busd2usdm, true);
    await swapMining.addPool(20, xms2usdm, true);
    await swapMining.addPool(20, busd2usdm, true);
    await core.allocateXMS(swapMining.address, one.muln(1000000));
    await xmsRedemptionUnit.unpause();
    await core.allocateXMS(lpMining.address, one.muln(1000000));

    return {
        wbnb,
        busd,
        core,
        xms,
        factory,
        router,
        stake,
        busdLastPriceOracle,
        bnbLastPriceOracle,
        usdm,
        busd2usdm,
        xms2usdm,
        swapMiningOracle,
        swapMining,
        lpMining,
        busdUniswapPCVDeposit,
        busdBondingLCurve,
        busdUniswapPCVController,
        xmsRedemptionUnit,
        ido,
        busdGenesisGroup
    };
}

module.exports = {
    deploy
};