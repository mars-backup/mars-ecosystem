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

var one = new BN("1000000000000000000")
let genesisGroup = null
let xmsGenesisEvent = null
let busdGenesisEvent = null
let busdChainlink = null
let xms = null
let busd = null
let usdm = null
contract("Test", (accounts) => {
  before(async () => {
    xms = await XMSToken.at(process.env.DEV_DEPLOYED_XMS)
    busd = await ERC20.at(process.env.DEV_BUSD_ADDRESS)
    usdm = await ERC20.at(process.env.DEV_DEPLOYED_USDM)
    genesisGroup = await BUSDGenesisGroup.deployed()
    xmsGenesisEvent = await XMSGenesisEvent.deployed()
    busdGenesisEvent = await BUSDGenesisEvent.deployed()
    busdChainlink = await MockBUSDLastPriceOracle.at(process.env.DEV_DEPLOYED_CHAINLINK_BUSD)
  })
  it("launch, genesis group", async () => {
    console.log("current block:")
    console.log(await web3.eth.getBlockNumber())
    await time.advanceBlock()
    await genesisGroup.launch()
    await xmsGenesisEvent.launch()
    await busdGenesisEvent.launch()
    console.log("current block:")
    console.log(await web3.eth.getBlockNumber())

  })
  it("claim genesis group", async () => {
    var ret = await genesisGroup.getAmountsToRedeem(accounts[0])
    var busdPrice = await busdChainlink.getLatestPrice()
    console.log("genesis group");
    console.log("committed busd: " + (await genesisGroup.balanceOf(accounts[0])).toString())
    console.log("busd price: " + busdPrice[0])
    console.log("claim usdm: " + ret[0].toString())
    console.log("claim busd: " + ret[1].toString())
    var usdmBalance = await usdm.balanceOf(accounts[0])
    var busdBalance = await busd.balanceOf(accounts[0])
    await genesisGroup.redeem(accounts[0])
    var usdmBalanceNew = await usdm.balanceOf(accounts[0])
    var busdBalanceNew = await busd.balanceOf(accounts[0])
    console.log("rest committed busd: " + (await genesisGroup.balanceOf(accounts[0])).toString())
    console.log("usdm balance added: " + usdmBalanceNew.sub(usdmBalance).toString())
    console.log("busd balance added: " + busdBalanceNew.sub(busdBalance).toString())


  })
  it("claim xms genesis event", async () => {
    var ret = await xmsGenesisEvent.getAmountsToClaim(accounts[0])
    var xmsPrice = await xmsGenesisEvent.underlyingPrice()
    console.log("xms genesis event")
    console.log("committed xms: " + (await xmsGenesisEvent.balanceOf(accounts[0])).toString())
    console.log("xms price: " + xmsPrice[0])
    console.log("claim usdm: " + ret[0].toString())
    console.log("claim xms: " + ret[1].toString())
    var usdmBalance = await usdm.balanceOf(accounts[0])
    var xmsBalance = await xms.balanceOf(accounts[0])
    await xmsGenesisEvent.claim(accounts[0])
    var usdmBalanceNew = await usdm.balanceOf(accounts[0])
    var xmsBalanceNew = await xms.balanceOf(accounts[0])
    console.log("rest committed xms: " + (await xmsGenesisEvent.balanceOf(accounts[0])).toString())
    console.log("usdm balance added: " + usdmBalanceNew.sub(usdmBalance).toString())
    console.log("xms balance added: " + xmsBalanceNew.sub(xmsBalance).toString())


  })
  it("claim busd genesis event", async () => {
    var ret = await busdGenesisEvent.getAmountsToClaim(accounts[0])
    var busdPrice = await busdGenesisEvent.underlyingPrice()
    console.log("busd genesis event")
    console.log("committed busd: " + (await busdGenesisEvent.balanceOf(accounts[0])).toString())
    console.log("busd price: " + busdPrice[0])
    console.log("claim usdm: " + ret[0].toString())
    console.log("claim busd: " + ret[1].toString())
    var usdmBalance = await usdm.balanceOf(accounts[0])
    var busdBalance = await busd.balanceOf(accounts[0])
    await busdGenesisEvent.claim(accounts[0])
    var usdmBalanceNew = await usdm.balanceOf(accounts[0])
    var busdBalanceNew = await busd.balanceOf(accounts[0])
    console.log("rest committed busd: " + (await busdGenesisEvent.balanceOf(accounts[0])).toString())
    console.log("usdm balance added: " + usdmBalanceNew.sub(usdmBalance).toString())
    console.log("busd balance added: " + busdBalanceNew.sub(busdBalance).toString())
  })
})