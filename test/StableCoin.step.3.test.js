const {
  BN, // Big Number support
  time,
  constants, // Common constants, like the zero address and largest integers
  expectEvent, // Assertions for emitted events
  expectRevert, // Assertions for transactions that should fail
} = require('@openzeppelin/test-helpers')
const ERC20 = artifacts.require("ERC20")

const XMSToken = artifacts.require("XMSToken")
const BUSDGenesisGroup = artifacts.require("BUSDGenesisGroup")
const XMSGenesisEvent = artifacts.require("XMSGenesisEvent")
const BUSDGenesisEvent = artifacts.require("BUSDGenesisEvent")
const MockBNBLastPriceOracle = artifacts.require("MockBNBLastPriceOracle")
const MockBUSDLastPriceOracle = artifacts.require("MockBUSDLastPriceOracle")

const BUSDUniswapPCVDeposit = artifacts.require("BUSDUniswapPCVDeposit")
const BUSDBondingLCurve = artifacts.require("BUSDBondingLCurve")
const BUSDUniswapPCVController = artifacts.require("BUSDUniswapPCVController")
const XMSRedemptionUnit = artifacts.require("XMSRedemptionUnit")
const USDMGovernanceOracle = artifacts.require("USDMGovernanceOracle")
const MarsSwapPairCombOracle = artifacts.require("MarsSwapPairCombOracle")
const OracleIncentives = artifacts.require("OracleIncentives")


var one = new BN("1000000000000000000")
let genesisGroup = null
let xmsGenesisEvent = null
let busdGenesisEvent = null

let busdUniswapPCVDeposit = null
let busdBondingLCurve = null
let busdUniswapPCVController = null
let xmsRedemptionUnit = null
let usdmGovernanceOracle = null
let xmsForUSDMMROracle = null
let xmsForUSDMSupplyCapOracle = null
let oracleIncentives = null

contract("Test", (accounts) => {
  before(async () => {
    busdUniswapPCVDeposit = BUSDUniswapPCVDeposit.deployed();
    busdBondingLCurve = BUSDBondingLCurve.deployed();
    busdUniswapPCVController = BUSDUniswapPCVController.deployed();
    xmsRedemptionUnit = XMSRedemptionUnit.deployed();
    usdmGovernanceOracle = USDMGovernanceOracle.deployed();
    xmsForUSDMMROracle = MarsSwapPairCombOracle.at();
    xmsForUSDMSupplyCapOracle = MarsSwapPairCombOracle.at();
    oracleIncentives = OracleIncentives.deployed();

    genesisGroup = await BUSDGenesisGroup.deployed()
    xmsGenesisEvent = await XMSGenesisEvent.deployed()
    busdGenesisEvent = await BUSDGenesisEvent.deployed()
  })
  it("FF", async () => {

  })
})