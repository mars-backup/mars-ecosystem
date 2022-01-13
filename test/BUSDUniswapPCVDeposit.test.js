const {
    BN,
    expectRevert,
    expectEvent,
    time,
    constants
} = require('@openzeppelin/test-helpers');
const { expect } = require('chai');
const _ = require('lodash');
const { deploy } = require('./deploy');

const zero = new BN(0);
const one = new BN("1000000000000000000");

const MarsSwapPair = artifacts.require('MarsSwapPair');

function expectBnEqual(a, b) {
    expect(a).to.be.bignumber.equals(b);
}

function expectBnWithin(a, b, decimals) {
    const d = new BN(10).pow(new BN(decimals));
    expect(a.sub(b).abs().lt(d)).to.be.true;
}

contract('BUSDUniswapPCVDeposit unit test', function(accounts) {
    const [ owner, minter, feeTo, attacker ] = accounts;
    const fromAttacker = { from: attacker };

    beforeEach(async function() {
        const c = this.contracts = await deploy(accounts);
        this.busdGenesisGroup = c.busdGenesisGroup;
        this.busd = c.busd;
        this.usdm = c.usdm;
        this.core = c.core;
        this.lpMining = c.lpMining;
        this.busd2usdm = await MarsSwapPair.at(c.busd2usdm);
        this.busdUniswapPCVDeposit = c.busdUniswapPCVDeposit;

        await this.core.grantPCVController(owner);
    });

    describe("deposit", function() {
        it("postGenesis", async function() {
            await expectRevert(
                this.busdUniswapPCVDeposit.deposit(100),
                "CoreRef::postGenesis: Still in genesis period."
            );
        });

        describe("after launch", function() {
            beforeEach(async function() {
                const amount = one.muln(10000);
                await this.busdGenesisGroup.initGenesis();
                await this.busd.mint(owner, amount);
                await this.busd.approve(this.busdGenesisGroup.address, amount);
                await this.busdGenesisGroup.purchase(owner, amount);
                expectBnEqual(await this.busd.balanceOf(owner), zero);
                expectBnEqual(await this.busdGenesisGroup.balanceOf(owner), amount);
                await time.increase(101);
                const receipt = await this.busdGenesisGroup.launch();
                expectEvent.inLogs(receipt.logs, 'Launch', {});
            });

            it("whenNotPaused", async function() {
                await this.busdUniswapPCVDeposit.pause();
                await expectRevert(
                    this.busdUniswapPCVDeposit.deposit(100),
                    "Pausable: paused."
                );
            });
    
            it("No need BNB", async function() {
                await expectRevert(
                    this.busdUniswapPCVDeposit.deposit(100, { value: 100 }),
                    "BUSDUniswapPCVDeposit::deposit: No need BNB"
                );
            });
    
            it("success", async function() {
                const amount = one.muln(1000000);
                await this.busd.mint(owner, amount);
                await this.busd.transfer(this.busdUniswapPCVDeposit.address, amount);
                const receipt = await this.busdUniswapPCVDeposit.deposit(amount)
                expectEvent.inLogs(receipt.logs, 'Deposit', {
                    from: owner,
                    amount
                });
                expectBnEqual(
                    await this.usdm.balanceOf(this.busdUniswapPCVDeposit.address),
                    zero
                );
                expectBnEqual(
                    await this.busd.balanceOf(this.busdUniswapPCVDeposit.address),
                    zero
                );
            });
        });
    });

    describe("withdraw", function() {
        it("onlyPCVController", async function() {
            await expectRevert(
                this.busdUniswapPCVDeposit.withdraw(minter, 10000, fromAttacker),
                "CoreRef::onlyPCVController: Caller is not a PCV controller."
            );
        });

        it("success", async function() {
            const amount = one.muln(10000);
            await this.busd.mint(this.busdUniswapPCVDeposit.address, amount);
            const receipt = await this.busdUniswapPCVDeposit.withdraw(minter, amount);
            expectEvent.inLogs(receipt.logs, 'Withdrawal', {
                caller: owner,
                to: minter,
                amount
            });
        });
    });

    describe("removeLiquidity", function() {
        beforeEach(async function() {
            const amount = one.muln(10000);
            await this.busdGenesisGroup.initGenesis();
            await this.busd.mint(owner, amount);
            await this.busd.approve(this.busdGenesisGroup.address, amount);
            await this.busdGenesisGroup.purchase(owner, amount);
            expectBnEqual(await this.busd.balanceOf(owner), zero);
            expectBnEqual(await this.busdGenesisGroup.balanceOf(owner), amount);
            await time.increase(101);
            const receipt = await this.busdGenesisGroup.launch();
            expectEvent.inLogs(receipt.logs, 'Launch', {});
        });

        it("onlyPCVController", async function() {
            await expectRevert(
                this.busdUniswapPCVDeposit.removeLiquidity(100, 1, 1, fromAttacker),
                "CoreRef::onlyPCVController: Caller is not a PCV controller."
            );
        });

        it("success", async function() {
            const liquidity = await this.busd2usdm.balanceOf(this.busdUniswapPCVDeposit.address);
            await this.busdUniswapPCVDeposit.removeLiquidity(liquidity, one, one.muln(2));
            expectBnEqual(
                await this.busd2usdm.balanceOf(this.busdUniswapPCVDeposit.address),
                zero
            );
            expectBnEqual(
                await this.usdm.balanceOf(this.busdUniswapPCVDeposit.address),
                zero
            );
        });
    });

    describe("harvest", function() {
        beforeEach(async function() {
            const amount = one.muln(10000);
            await this.busdGenesisGroup.initGenesis();
            await this.busd.mint(owner, amount);
            await this.busd.approve(this.busdGenesisGroup.address, amount);
            await this.busdGenesisGroup.purchase(owner, amount);
            expectBnEqual(await this.busd.balanceOf(owner), zero);
            expectBnEqual(await this.busdGenesisGroup.balanceOf(owner), amount);
            await time.increase(101);
            const receipt = await this.busdGenesisGroup.launch();
            expectEvent.inLogs(receipt.logs, 'Launch', {});
        });

        it("onlyPCVController", async function() {
            await expectRevert(
                this.busdUniswapPCVDeposit.harvest(fromAttacker),
                "CoreRef::onlyPCVController: Caller is not a PCV controller."
            );
        });

        it("success", async function() {
            const liquidity = await this.busd2usdm.balanceOf(this.busdUniswapPCVDeposit.address);
            await this.busdUniswapPCVDeposit.depositLpMining(liquidity);
            await time.advanceBlock();
            await this.busdUniswapPCVDeposit.harvest();
        });
    });

    describe("depositLpMining", function() {
        beforeEach(async function() {
            const amount = one.muln(10000);
            await this.busdGenesisGroup.initGenesis();
            await this.busd.mint(owner, amount);
            await this.busd.approve(this.busdGenesisGroup.address, amount);
            await this.busdGenesisGroup.purchase(owner, amount);
            expectBnEqual(await this.busd.balanceOf(owner), zero);
            expectBnEqual(await this.busdGenesisGroup.balanceOf(owner), amount);
            await time.increase(101);
            const receipt = await this.busdGenesisGroup.launch();
            expectEvent.inLogs(receipt.logs, 'Launch', {});
        });

        it("onlyPCVController", async function() {
            const liquidity = await this.busd2usdm.balanceOf(this.busdUniswapPCVDeposit.address);
            await expectRevert(
                this.busdUniswapPCVDeposit.depositLpMining(liquidity, fromAttacker),
                "CoreRef::onlyPCVController: Caller is not a PCV controller."
            );
        });

        it("success", async function() {
            const liquidity = await this.busd2usdm.balanceOf(this.busdUniswapPCVDeposit.address);
            await this.busdUniswapPCVDeposit.depositLpMining(liquidity);
            expectBnEqual(
                await this.busd2usdm.balanceOf(this.busdUniswapPCVDeposit.address),
                zero
            );
        });
    });

    describe("withdrawLpMining", function() {
        beforeEach(async function() {
            const amount = one.muln(10000);
            await this.busdGenesisGroup.initGenesis();
            await this.busd.mint(owner, amount);
            await this.busd.approve(this.busdGenesisGroup.address, amount);
            await this.busdGenesisGroup.purchase(owner, amount);
            expectBnEqual(await this.busd.balanceOf(owner), zero);
            expectBnEqual(await this.busdGenesisGroup.balanceOf(owner), amount);
            await time.increase(101);
            const receipt = await this.busdGenesisGroup.launch();
            expectEvent.inLogs(receipt.logs, 'Launch', {});
        });

        it("onlyPCVController", async function() {
            const liquidity = await this.busd2usdm.balanceOf(this.busdUniswapPCVDeposit.address);
            await expectRevert(
                this.busdUniswapPCVDeposit.withdrawLpMining(liquidity, fromAttacker),
                "CoreRef::onlyPCVController: Caller is not a PCV controller."
            );
        });

        it("success", async function() {
            const liquidity = await this.busd2usdm.balanceOf(this.busdUniswapPCVDeposit.address);
            await this.busdUniswapPCVDeposit.depositLpMining(liquidity);
            await this.busdUniswapPCVDeposit.withdrawLpMining(liquidity);
            expectBnEqual(
                await this.busd2usdm.balanceOf(this.busdUniswapPCVDeposit.address),
                liquidity
            );
        });
    });
});