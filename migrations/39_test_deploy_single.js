const {
  BN, // Big Number support
  constants, // Common constants, like the zero address and largest integers
  expectEvent, // Assertions for emitted events
  expectRevert, // Assertions for transactions that should fail
} = require('@openzeppelin/test-helpers');

var XMSToken = artifacts.require("XMSToken");
var USDMToken = artifacts.require("USDMToken");
var MarsSwapFactory = artifacts.require("MarsSwapFactory");
var TERC20 = artifacts.require("TERC20");
var WBNB = artifacts.require("WBNB");
var BUSDGenesisGroup = artifacts.require("BUSDGenesisGroup");
var XMSGenesisEvent = artifacts.require("XMSGenesisEvent");
var BUSDGenesisEvent = artifacts.require("BUSDGenesisEvent");
var Core = artifacts.require("Core");
var Multicall = artifacts.require("Multicall");
var IMO = artifacts.require("IMO");
var AirDrop = artifacts.require("AirDrop");
var AirDropV2 = artifacts.require("AirDropV2");
var IMOExt = artifacts.require("IMOExt");
var MarsStakeReward = artifacts.require("MarsStakeReward");
var BUSDBondingLCurve = artifacts.require("BUSDBondingLCurve");
var RandomAirDrop = artifacts.require("RandomAirDrop");
var XMSRedemptionUnit = artifacts.require("XMSRedemptionUnit");
var MarsSwapPairCombOracle = artifacts.require("MarsSwapPairCombOracle");
var OracleIncentives = artifacts.require("OracleIncentives");
var SwapMiningOracle = artifacts.require("SwapMiningOracle");
var Timelock = artifacts.require("Timelock");
var LiquidityMiningMaster = artifacts.require("LiquidityMiningMaster");
var LiquidityMiningMasterBNB = artifacts.require("LiquidityMiningMasterBNB");
var SwapMining = artifacts.require("SwapMining");
var VestingMaster = artifacts.require("VestingMaster");
var USDMGovernanceOracle = artifacts.require("USDMGovernanceOracle");
var XMSCirculatingSupplyOracle = artifacts.require("XMSCirculatingSupplyOracle");
var BUSDUniswapPCVDeposit = artifacts.require("BUSDUniswapPCVDeposit");

var one = new BN("1000000000000000000");

module.exports = function (deployer, network, accounts) {

  deployer.then(async () => {
    if (network == "development") {
      // var core = await Core.at("0x04BB2D6cb14910024a8494E0e459b7650F04b99b");
      // await core.grantMinter(accounts[0]);
      // await usdm.mint(accounts[0], one.mul(new BN("1000000")));
      // await core.allocateXMS(accounts[0], one.mul(new BN("10000000")));
      // var busd = await deployer.deploy(TERC20, 'BUSD', 'BUSD')
      // await deployer.deploy(WBNB)
      // await busd.mint(accounts[0], new BN(1000000000000).mul(one))
      // console.log("BUSD");
      // console.log(BUSD.address);
      // console.log("WBNB");
      // console.log(WBNB.address);
      // await core.createRole(web3.utils.keccak256("FARMS_ROLE"), web3.utils.keccak256("GOVERN_ROLE"));
      // await core.grantRole(web3.utils.keccak256("FARMS_ROLE"), accounts[0]);
      // await deployer.deploy(VestingMaster, core.address, 5 * 60, 59, xms.address);

      // var liquidityMiningMaster = await LiquidityMiningMaster.at("0xA76ed055Fe2cF48650CB1F21F54a3be6c93EaEff");

      // await liquidityMiningMaster.addPool(60, "0x2E794618D0C29013E999b175e3ef1b529cf7048B", false, true);

    }
  }).then(async () => {
    // var PARK = await deployer.deploy(TERC20, 'PARK', 'PARK')
    // var ETH = await deployer.deploy(TERC20, 'ETH', 'ETH')
    // await KALA.mint(accounts[0], one.mul(new BN("100000000")));
    // await ETH.mint(accounts[0], one.mul(new BN("100000000")));

    // var core = await Core.at("0xcdCD82d41463C672D60c0CD89930070D469256f9");
    // var core = await Core.at("0xEEFf02B30420A76757b56CE057a9b20e86C1B168");

    // await core.setXMS("0x70138966a7CcFd7DB437797126E547fcB21e69BC");
    // await core.setUSDM("0x86C1f573E34dAb04C42fD5489dBE5cB04f51eCa3");

    // await core.createRole(web3.utils.keccak256("FARMS_ROLE"), web3.utils.keccak256("GOVERN_ROLE"));
    // await core.grantRole(web3.utils.keccak256("FARMS_ROLE"), "0x62E87D5dfCDc6518939C4D6DCEba461f34Bca043");

    // await core.grantMinter("0x9CC1A35E7a8BBa9E1536DEEDE9579Ba42E48C227");
    // await core.grantMinter("0x8b4F6f6004D845B1ABf3e2743eD47B9Eac294ca9");
    // await core.grantMinter("0xC39e6D657d353aeCC414122fb4DCAbba873920D4");
    // await core.grantMinter(accounts[0]);
    // await core.grantGuardian("0xfE08B6D4c02179734723cBa7BDc487eF8d8a7c22");
    // await core.grantGovernor("0xC6965103d5C59e4518be665dceC25b3C588Da71c");
    // await core.grantGuardian("0xBbCceB9a4C3c0F8Cd9d8a213c3D5B713324b46E4");
    // await core.grantGovernor("0x999AC610710f2DEACE0d571A48ec8277faB17f82");

    // const xmsCirculatingSupplyOracle = await deployer.deploy(XMSCirculatingSupplyOracle, "0xcdCD82d41463C672D60c0CD89930070D469256f9", "0x70138966a7CcFd7DB437797126E547fcB21e69BC");

    // var timelock = await Timelock.at("0xf70DAFE4a70bB040387F48876F665c441Fa7b96C");
    // var core = new web3.eth.Contract(Core.abi, "0xa7b115f55E5f02fcF55dd364C7Bd4360DAeCe6EE");

    // var data = core.methods.grantGuardian("0x625FcCB779045945a1e84742F22bD7fF190C6882").encodeABI();
    // console.log(data);
    // const now = Math.floor(new Date().getTime() / 1000)
    // console.log(now)
    // var response1 = await timelock.queueTransaction("0xa7b115f55E5f02fcF55dd364C7Bd4360DAeCe6EE", 0, "", data, now + 3600 + 120);
    // console.log(response1);



    // var liquidityMiningMaster = await LiquidityMiningMaster.deployed();
    // var liquidityMiningMaster = await LiquidityMiningMaster.at("0x207533945a72DccD0a040eFA286A4dC6CE2A5bcb");

    // await liquidityMiningMaster.addPool(60, "0x9e973C0545AcB2a3A55c67077629C9f79c4D3f2B", false, true);
    // await liquidityMiningMaster.addPool(40, "0xDDd109a7F58994d2Be04cF93c1BE4066E095c5e4", true);
    // await liquidityMiningMaster.addPool(30, "0x3Fc5Ee0B6F23c8b0feBfeF1e3bd6BFB6624aC750", true);
    // await liquidityMiningMaster.addPool(20, "0x70138966a7CcFd7DB437797126E547fcB21e69BC", false, true);
    // await liquidityMiningMaster.addPool(100, "0x5899CBE615212f6b94751344b9EAa164ABc177B2", true);
    // await liquidityMiningMaster.addPool(30, "0x068065e0075d3d1ecb9378872de4a8117e5c9b2d", true);
    // await liquidityMiningMaster.addPool(70, "0xd508f5B8c72b64B73bfD9Da823229F89590a8fA5", false, true);
    // var swapMining = await SwapMining.deployed();
    // await swapMining.addPool(20, "0xDDd109a7F58994d2Be04cF93c1BE4066E095c5e4", true);
    // await swapMining.addPool(30, "0x3Fc5Ee0B6F23c8b0feBfeF1e3bd6BFB6624aC750", true);

    // var liquidityMiningMasterBNB = await LiquidityMiningMaster.at("0x207533945a72DccD0a040eFA286A4dC6CE2A5bcb");
    // await liquidityMiningMasterBNB.setPool(0,20,false,true);
    // await liquidityMiningMasterBNB.setPool(1,15,false,true);
    // var liquidityMiningMasterBTCB = await LiquidityMiningMaster.at("0x926854E15A30945Ed5dF28dbEdd70c59ad5a5663");
    // await liquidityMiningMasterBTCB.setPool(0,18,false,true);
    // await liquidityMiningMasterBTCB.setPool(1,30,false,true);
    // var liquidityMiningMasterETH = await LiquidityMiningMaster.at("0x3B8Ae4ab91144e65041709562Be61671E1049565");
    // await liquidityMiningMasterETH.setPool(0,30,false,true);
    // await liquidityMiningMasterETH.setPool(1,40,false,true);
    // var liquidityMiningMasterCAKE = await LiquidityMiningMaster.at("0x1933f09A3236678A4eFfa655890a9927Ada9Cc5A");
    // await liquidityMiningMasterCAKE.setPool(0,50,false,true);
    // await liquidityMiningMasterCAKE.setPool(1,60,false,true);

    var testAddress = [
      // "0x9c6f45B39951BAF36e0EDDf18e1a16e25f667360", // xji
      // "0x625FcCB779045945a1e84742F22bD7fF190C6882", // john
      // "0xD746122dD7Dd4a292a06c2D12D0203f171b8eF7b", // john
      // "0xe55908dD03cCEAf3Cd8B879e0319776e3A767B25", // sira
      // "0x5719BCc81082f4D21dCF826AC5a31f808c5F8fe8", // ezra
      // "0xD300504063836e7774564E58B8a17Ed50798Bed7", // xiong
      // "0xb4F83CF3461E0B9E0d36fB8D41B635c8A7Fe6809", // lu
      // "0x4791D2b913D58bdA228e619ce5C6E98A4E75c1aa", // rita
      "0x3360deC490E74605c65CDb8D2F87137c1C5E8345", // zhenguo
      "0x51EdcEA7C3Af77E6BB900D588D973d42C352018b", // yuechan
      // accounts[0]
    ];
    // var cake = await TERC20.at("0x9Ff7010Fe2DbdD638257b8eaA1a65e73129361A3");
    // var busda = await TERC20.at("0xd508f5B8c72b64B73bfD9Da823229F89590a8fA5");
    // var busdb = await TERC20.at("0x5899CBE615212f6b94751344b9EAa164ABc177B2");
    // var xms = await XMSToken.at("0x70138966a7CcFd7DB437797126E547fcB21e69BC");
    // var usdm = await USDMToken.at("0x3a851f90bcCBF71061B3516C7BdB3a867385177D");
    // for (var i = 0; i < testAddress.length; i++) {
    //   await cake.mint(testAddress[i], one.mul(new BN("100000")));
    // await busda.mint(testAddress[i], one.mul(new BN("100000")));
    // await busdb.mint(testAddress[i], one.mul(new BN("100000")));
    // await xms.transfer(testAddress[i], one.mul(new BN("100000")));
    //   await usdm.transfer(testAddress[i], one.mul(new BN("100000")));
    // }

  }).then(async () => {
    // var core = await Core.at("0x00789Cfb69499c65ac9A3a68fb4917c9b4FcA2a7");

    // var liquidityMiningMaster = await LiquidityMiningMaster.deployed();
    // await liquidityMiningMaster.addPool(100, "0x7859B01BbF675d67Da8cD128a50D155cd881B576", false, true);
    // await liquidityMiningMaster.addPool(2, "0x40b605d8beed09568e702deadce90fb23cfd74d8", true);

    // var liquidityMiningMasterBNB = await LiquidityMiningMasterBNB.deployed();
    // await liquidityMiningMasterBNB.addPool(100, "0x7859B01BbF675d67Da8cD128a50D155cd881B576", false, true);

    // var xmsRedemptionUnit = await XMSRedemptionUnit.deployed();
    // await xmsRedemptionUnit.unpause();

    // var busdGenesisGroup = await BUSDGenesisGroup.deployed();
    // var busdGenesisGroup = await BUSDGenesisGroup.at("0xa8262f35F3dc721fBd228C40Fa3E0f09F90a29eA");
    // await busdGenesisGroup.complete();
    // await busdGenesisGroup.initGenesis(1635821700);
    // await busdGenesisGroup.launch();
    // var xmsGenesisEvent = await XMSGenesisEvent.deployed();
    // await xmsGenesisEvent.initGenesisEvent(1635308100);
    // await xmsGenesisEvent.launch();
    // var busdGenesisEvent = await BUSDGenesisEvent.deployed();
    // var busdGenesisEvent = await BUSDGenesisEvent.at("0x03e238d71882C27977eD61A77FB14f7Bf88793e7");
    // await busdGenesisEvent.initGenesisEvent(1635321600);
    // await busdGenesisEvent.launch();

    // var usdmGovernanceOracle = await USDMGovernanceOracle.at("0xa5AdA954b8617Aa0fdC54B53c0986672A663A73A");
    // await usdmGovernanceOracle.addApprovedPairAndContract("0x014C558beE62feF578757C21103AD7864B3f1439", BUSDUniswapPCVDeposit.address);
    // await usdmGovernanceOracle.addApprovedFarmPairAndContract("0x014C558beE62feF578757C21103AD7864B3f1439", BUSDUniswapPCVDeposit.address, "0x7A0336C03e6ac95FF66017743C882d13f5F598D9");

    // var liquidityMiningMasterBNB = await LiquidityMiningMaster.at("0x48C42579D98Aa768cde893F8214371ed607CABE3");
    // await liquidityMiningMasterBNB.setPool(0,194,false,true);
    // await liquidityMiningMasterBNB.setPool(1,100,false,true);
    // await liquidityMiningMasterBNB.setPool(2,3,false,true);
    // var liquidityMiningMasterBTCB = await LiquidityMiningMaster.at("0xA53b575F9eC7126ba7b43c8c3171Fe4685F2f8b0");
    // await liquidityMiningMasterBTCB.setPool(0,315,false,true);
    // await liquidityMiningMasterBTCB.setPool(1,19,false,true);
    // var liquidityMiningMasterETH = await LiquidityMiningMaster.at("0x4639d936F0A716f234EAD073362C5Cb272Cc4B70");
    // await liquidityMiningMasterETH.setPool(0,357,false,true);
    // await liquidityMiningMasterETH.setPool(1,18,false,true);
    // var liquidityMiningMasterCAKE = await LiquidityMiningMaster.at("0x22D8d50454203bd5a41B49ef515891f1aD9f3e53");
    // await liquidityMiningMasterCAKE.setPool(2,14,false,true);
    var liquidityMiningMasterCELT = await LiquidityMiningMaster.at("0x6E7cf396eA6Cb48bE7d15e03e3b6BD1E7860cE6B");
    await liquidityMiningMasterCELT.updateTokenPerBlock(0);

    // const airDropV2 = await deployer.deploy(AirDropV2, "0x00789Cfb69499c65ac9A3a68fb4917c9b4FcA2a7", process.env.XMS_TREASURY_ADDRESS);

  });
}