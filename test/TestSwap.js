const {
  BN,           // Big Number support
  constants,    // Common constants, like the zero address and largest integers
  expectEvent,  // Assertions for emitted events
  expectRevert, // Assertions for transactions that should fail
} = require('@openzeppelin/test-helpers');

const XMSToken = artifacts.require("XMSToken");
const USDMToken = artifacts.require("USDMToken");
const LiquidityMiningMaster = artifacts.require("LiquidityMiningMaster");
const LockedTokenVault = artifacts.require("LockedTokenVault");

var one = new BN("1000000000000000000");
contract("Test", (accounts) => {
    before(async () => {

    });
    it("add liquidity", async () => {
        
    });
});