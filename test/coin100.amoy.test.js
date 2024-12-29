/* eslint-disable no-undef */
const { expect } = require("chai");
const { ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");

describe("COIN100 Contract on Amoy", function () {
  let coin100;
  let owner;
  const ROUNDING_TOLERANCE = ethers.utils.parseUnits("1", 18);

  before(async function () {
    // Load deployment info
    const deploymentPath = path.join(__dirname, "../deployments/amoy_coin100_deployment.json");
    if (!fs.existsSync(deploymentPath)) {
      throw new Error("COIN100 deployment info not found. Please deploy to Amoy first.");
    }
    const deployment = JSON.parse(fs.readFileSync(deploymentPath, "utf8"));

    [owner] = await ethers.getSigners();
    console.log("Testing with owner account:", owner.address);

    // Get contract instance
    const COIN100 = await ethers.getContractFactory("COIN100");
    coin100 = await COIN100.attach(deployment.coin100.address);
  });

  describe("Basic Functionality", function () {
    it("Should have correct owner and initial supply", async function () {
      expect(await coin100.owner()).to.equal(owner.address);
      const totalSupply = await coin100.totalSupply();
      expect(totalSupply).to.be.gt(0);
    });

    it("Should transfer tokens between accounts", async function () {
      const initialBalance = await coin100.balanceOf(owner.address);
      expect(initialBalance).to.be.gt(0);

      // Create test accounts
      const testAccount1 = ethers.Wallet.createRandom().connect(ethers.provider);
      const testAccount2 = ethers.Wallet.createRandom().connect(ethers.provider);

      // Fund test accounts with ETH for gas
      await owner.sendTransaction({
        to: testAccount1.address,
        value: ethers.utils.parseEther("0.1")
      });
      await owner.sendTransaction({
        to: testAccount2.address,
        value: ethers.utils.parseEther("0.1")
      });

      // Transfer tokens
      const transferAmount = ethers.utils.parseUnits("100", 18);
      await coin100.transfer(testAccount1.address, transferAmount);

      // Check balances after first transfer
      const account1Balance = await coin100.balanceOf(testAccount1.address);
      const expectedAccount1Balance = transferAmount.mul(98).div(100); // 2% fee
      const account1Difference = account1Balance.sub(expectedAccount1Balance).abs();
      expect(account1Difference).to.be.lt(ROUNDING_TOLERANCE);

      // Connect contract to test account and transfer
      const coin100Connected = coin100.connect(testAccount1);
      await coin100Connected.transfer(testAccount2.address, account1Balance);

      // Check balances after second transfer
      const account2Balance = await coin100.balanceOf(testAccount2.address);
      const expectedAccount2Balance = account1Balance.mul(98).div(100); // 2% fee
      const account2Difference = account2Balance.sub(expectedAccount2Balance).abs();
      expect(account2Difference).to.be.lt(ROUNDING_TOLERANCE);
    });
  });

  describe("Admin Functions", function () {
    it("Should add and remove liquidity pools", async function () {
      // Create test pool addresses
      const pool1 = ethers.Wallet.createRandom().address;
      const pool2 = ethers.Wallet.createRandom().address;

      // Add pools
      await coin100.addLiquidityPool(pool1);
      await coin100.addLiquidityPool(pool2);

      expect(await coin100.getLiquidityPoolsCount()).to.equal(2);
      expect(await coin100.getLiquidityPoolAt(0)).to.equal(pool1);
      expect(await coin100.getLiquidityPoolAt(1)).to.equal(pool2);

      // Remove pool1
      await coin100.removeLiquidityPool(pool1);
      expect(await coin100.getLiquidityPoolsCount()).to.equal(1);
      expect(await coin100.getLiquidityPoolAt(0)).to.equal(pool2);
    });

    it("Should update treasury address", async function () {
      const newTreasury = ethers.Wallet.createRandom().address;
      await coin100.updateTreasuryAddress(newTreasury);
      expect(await coin100.treasury()).to.equal(newTreasury);

      // Reset treasury for other tests
      await coin100.updateTreasuryAddress(owner.address);
    });

    it("Should pause and unpause transfers", async function () {
      const testAccount = ethers.Wallet.createRandom().address;
      await coin100.pauseContract();
      
      await expect(
        coin100.transfer(testAccount, ethers.utils.parseUnits("1", 18))
      ).to.be.revertedWith("EnforcedPause");

      await coin100.unpauseContract();
      await expect(
        coin100.transfer(testAccount, ethers.utils.parseUnits("1", 18))
      ).to.not.be.reverted;
    });
  });

  describe("Rebase Functionality", function () {
    it("Should not allow rebase before frequency period", async function () {
      const lastMarketCap = await coin100.lastMarketCap();
      const newMarketCap = lastMarketCap.mul(12).div(10); // 20% increase

      await expect(
        coin100.rebase(newMarketCap.div(ethers.utils.parseUnits("1", 18)))
      ).to.be.revertedWith("Rebase frequency not met");
    });

    it("Should rebase correctly after frequency period", async function () {
      // Wait for some blocks to pass
      for(let i = 0; i < 5; i++) {
        await owner.sendTransaction({
          to: ethers.Wallet.createRandom().address,
          value: ethers.utils.parseEther("0.0001")
        });
      }

      const initialSupply = await coin100.totalSupply();
      const lastMarketCap = await coin100.lastMarketCap();
      const newMarketCap = lastMarketCap.mul(15).div(10); // 50% increase

      // Perform rebase
      await coin100.rebase(newMarketCap.div(ethers.utils.parseUnits("1", 18)));
      
      const newSupply = await coin100.totalSupply();
      const expectedSupply = initialSupply.mul(15).div(10);
      const difference = newSupply.sub(expectedSupply).abs();
      expect(difference).to.be.lt(ROUNDING_TOLERANCE);
    });
  });
}); 