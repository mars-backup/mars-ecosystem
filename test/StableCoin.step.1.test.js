const {
  BN, // Big Number support
  time,
  constants, // Common constants, like the zero address and largest integers
  expectEvent, // Assertions for emitted events
  expectRevert, // Assertions for transactions that should fail
} = require('@openzeppelin/test-helpers')
const ERC20 = artifacts.require("ERC20")
const assert = require('assert')

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
  // it("genesis group, revet info", async () => {
  //   console.log("genesis group, purchase")
  //   await assert.rejects( 
  //     async () => { 
  //       await genesisGroup.purchase(accounts[0], one.mul(new BN("1000")))
  //     }, 
  //     (err) => { 
  //       console.log(err.message) 
  //       return true; 
  //     } 
  //   )
  //   console.log("genesis group, emergencyExit")
  //   await assert.rejects( 
  //     async () => { 
  //       await genesisGroup.emergencyExit(accounts[0], accounts[0])
  //     }, 
  //     (err) => { 
  //       console.log(err.message) 
  //       return true; 
  //     } 
  //   )
  //   console.log("genesis group, launch")
  //   await assert.rejects( 
  //     async () => { 
  //       await genesisGroup.launch()
  //     }, 
  //     (err) => { 
  //       console.log(err.message) 
  //       return true; 
  //     } 
  //   )
  //   console.log("genesis group, redeem")
  //   await assert.rejects( 
  //     async () => { 
  //       await genesisGroup.redeem(accounts[0])
  //     }, 
  //     (err) => { 
  //       console.log(err.message) 
  //       return true; 
  //     } 
  //   )
  //   console.log("genesis group, complete")
  //   await assert.rejects( 
  //     async () => { 
  //       await genesisGroup.complete()
  //     }, 
  //     (err) => { 
  //       console.log(err.message) 
  //       return true; 
  //     } 
  //   )
  // })
  // it("xms genesis event, revet info", async () => {
  //   console.log("xms genesis event, purchase")
  //   await assert.rejects( 
  //     async () => { 
  //       await xmsGenesisEvent.purchase(accounts[0], one.mul(new BN("1000")))
  //     }, 
  //     (err) => { 
  //       console.log(err.message) 
  //       return true; 
  //     } 
  //   )
  //   console.log("xms genesis event, emergencyExit")
  //   await assert.rejects( 
  //     async () => { 
  //       await xmsGenesisEvent.emergencyExit(accounts[0], accounts[0])
  //     }, 
  //     (err) => { 
  //       console.log(err.message) 
  //       return true; 
  //     } 
  //   )
  //   console.log("xms genesis event, launch")
  //   await assert.rejects( 
  //     async () => { 
  //       await xmsGenesisEvent.launch()
  //     }, 
  //     (err) => { 
  //       console.log(err.message) 
  //       return true; 
  //     } 
  //   )
  //   console.log("xms genesis event, claim")
  //   await assert.rejects( 
  //     async () => { 
  //       await xmsGenesisEvent.claim(accounts[0])
  //     }, 
  //     (err) => { 
  //       console.log(err.message) 
  //       return true; 
  //     } 
  //   )
  // })
  // it("busd genesis event, revet info", async () => {
  //   console.log("busd genesis event, purchase")
  //   await assert.rejects( 
  //     async () => { 
  //       await busdGenesisEvent.purchase(accounts[0], one.mul(new BN("1000")))
  //     }, 
  //     (err) => { 
  //       console.log(err.message) 
  //       return true; 
  //     } 
  //   )
  //   console.log("busd genesis event, emergencyExit")
  //   await assert.rejects( 
  //     async () => { 
  //       await busdGenesisEvent.emergencyExit(accounts[0], accounts[0])
  //     }, 
  //     (err) => { 
  //       console.log(err.message) 
  //       return true; 
  //     } 
  //   )
  //   console.log("busd genesis event, launch")
  //   await assert.rejects( 
  //     async () => { 
  //       await await busdGenesisEvent.launch()
  //     }, 
  //     (err) => { 
  //       console.log(err.message) 
  //       return true; 
  //     } 
  //   )
  //   console.log("busd genesis event, claim")
  //   await assert.rejects( 
  //     async () => { 
  //       await busdGenesisEvent.claim(accounts[0])
  //     }, 
  //     (err) => { 
  //       console.log(err.message) 
  //       return true; 
  //     } 
  //   )
  // })
  it("init", async () => {
    await time.advanceBlock()
    console.log("current block:")
    const blockNumber = await web3.eth.getBlockNumber()
    console.log(blockNumber)
    const block = await web3.eth.getBlock(blockNumber)
    await genesisGroup.initGenesis(block.timestamp)
    await xmsGenesisEvent.initGenesisEvent(block.timestamp)
    await busdGenesisEvent.initGenesisEvent(block.timestamp)
  })
  it("purchase, genesis group", async () => {
    const busd = await ERC20.at(process.env.DEV_BUSD_ADDRESS)
    await busd.approve(genesisGroup.address, one.mul(new BN("100000000")))
    const busdBalance = await busd.balanceOf(accounts[0])

    await genesisGroup.purchase(accounts[0], one.mul(new BN("1000")))
    const busdNowBalance = await busd.balanceOf(accounts[0])
    console.log("busd reduce: ")
    console.log(busdNowBalance.sub(busdBalance).toString())
    let balance = await genesisGroup.balanceOf(accounts[0])
    console.log("commit: ")
    console.log(balance.toString())


  })
  it("purchase, xms genesis event", async () => {
    const xms = await XMSToken.at(process.env.DEV_DEPLOYED_XMS)
    await xms.approve(xmsGenesisEvent.address, one.mul(new BN("100000000")))

    const stakeTokenAddress = await xmsGenesisEvent.stakeToken()
    const stakeToken = stakeTokenAddress == constants.ZERO_ADDRESS ? null : await ERC20.at(stakeTokenAddress)
    stakeToken ? await stakeToken.approve(busdGenesisEvent.address, one.mul(new BN("100000000"))) : null
    const stakeTokenBalance = stakeTokenAddress == constants.ZERO_ADDRESS ? new BN(0) : await stakeToken.balanceOf(accounts[0])

    const xmsBalance = await xms.balanceOf(accounts[0])
    await xmsGenesisEvent.purchase(accounts[0], one.mul(new BN("1000")))
    const xmsNowBalance = await xms.balanceOf(accounts[0])
    console.log("xms reduce: ")
    console.log(xmsNowBalance.sub(xmsBalance).toString())
    const stakeTokenNowBalance = stakeTokenAddress == constants.ZERO_ADDRESS ? new BN(0) : await stakeToken.balanceOf(accounts[0])
    console.log("stake token reduce: ")
    console.log(stakeTokenNowBalance.sub(stakeTokenBalance).toString())
    let balance = await xmsGenesisEvent.balanceOf(accounts[0])
    console.log("commit: ")
    console.log(balance.toString())
    let staked = await xmsGenesisEvent.stakeInfo(accounts[0])
    console.log("stake: ")
    console.log(staked.toString())


  })
  it("purchase, busd genesis event", async () => {
    const busd = await ERC20.at(process.env.DEV_BUSD_ADDRESS)
    await busd.approve(busdGenesisEvent.address, one.mul(new BN("100000000")))

    const stakeTokenAddress = await busdGenesisEvent.stakeToken()
    const stakeToken = stakeTokenAddress == constants.ZERO_ADDRESS ? null : await ERC20.at(stakeTokenAddress)
    stakeToken ? await stakeToken.approve(busdGenesisEvent.address, one.mul(new BN("100000000"))) : null
    const stakeTokenBalance = stakeTokenAddress == constants.ZERO_ADDRESS ? new BN(0) : await stakeToken.balanceOf(accounts[0])

    const busdBalance = await busd.balanceOf(accounts[0])
    await busdGenesisEvent.purchase(accounts[0], one.mul(new BN("1000")))
    const busdNowBalance = await busd.balanceOf(accounts[0])
    console.log("busd reduce: ")
    console.log(busdNowBalance.sub(busdBalance).toString())
    const stakeTokenNowBalance = stakeTokenAddress == constants.ZERO_ADDRESS ? new BN(0) : await stakeToken.balanceOf(accounts[0])
    console.log("stake token reduce: ")
    console.log(stakeTokenNowBalance.sub(stakeTokenBalance).toString())
    let balance = await busdGenesisEvent.balanceOf(accounts[0])
    console.log("commit: ")
    console.log(balance.toString())
    let staked = await busdGenesisEvent.stakeInfo(accounts[0])
    console.log("stake: ")
    console.log(staked.toString())
  })
})