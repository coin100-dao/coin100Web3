/* eslint-disable no-undef */
// test/coin100.test.js
/* global describe, it, beforeEach */
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("COIN100 Contract", function () {
  let COIN100, coin100;
  let treasury, admin, user1, user2;
  const initialMarketCap = ethers.utils.parseUnits("3316185190709", 18); // 3316185190709 * 1e18
  const unscaledInitialMarketCap = ethers.BigNumber.from("3316185190709");
  const ROUNDING_TOLERANCE = ethers.utils.parseUnits("1", 15); // Allow for even larger rounding differences

  beforeEach(async function () {
    [, treasury, admin, user1, user2] = await ethers.getSigners();

    // Deploy COIN100
    COIN100 = await ethers.getContractFactory("COIN100");
    coin100 = await COIN100.deploy(unscaledInitialMarketCap, treasury.address);
    await coin100.deployed();

    // Set governance contract
    await coin100.connect(treasury).setGovernorContract(admin.address);
  });

  describe("Deployment", function () {
    it("Should set the right owner and treasury", async function () {
      expect(await coin100.owner()).to.equal(treasury.address);
      expect(await coin100.treasury()).to.equal(treasury.address);
    });

    it("Should assign the total supply to the treasury", async function () {
      const treasuryBalance = await coin100.balanceOf(treasury.address);
      const totalSupply = await coin100.totalSupply();
      expect(treasuryBalance).to.equal(totalSupply);
    });
  });

  describe("Transfers", function () {
    it("Should transfer tokens between accounts with fees", async function () {
      const initialTreasuryBalance = await coin100.balanceOf(treasury.address);

      // Transfer 100 C100 from treasury to user1
      await coin100.connect(treasury).transfer(user1.address, ethers.utils.parseUnits("100", 18));

      const user1Balance = await coin100.balanceOf(user1.address);
      expect(user1Balance).to.equal(ethers.utils.parseUnits("98", 18)); // 2% fee

      // User1 transfers 50 C100 to user2
      await coin100.connect(user1).transfer(user2.address, ethers.utils.parseUnits("50", 18));

      const user2Balance = await coin100.balanceOf(user2.address);
      // With 2% fee, user2 should receive 49 tokens (50 - 1 fee)
      expect(user2Balance).to.equal(ethers.utils.parseUnits("49", 18));

      const treasuryBalance = await coin100.balanceOf(treasury.address);
      // Initial balance - 100 (first transfer) + 2 (fee from first transfer) - 50 (second transfer) + 1 (fee from second transfer)
      const expectedBalance = initialTreasuryBalance
        .sub(ethers.utils.parseUnits("100", 18))
        .add(ethers.utils.parseUnits("2", 18))
        .sub(ethers.utils.parseUnits("50", 18))
        .add(ethers.utils.parseUnits("1", 18));

      // Allow for rounding differences
      const difference = treasuryBalance.sub(expectedBalance).abs();
      expect(difference).to.be.lt(ROUNDING_TOLERANCE);
    });

    it("Should not allow transfers when paused", async function () {
      await coin100.connect(admin).pauseContract();
      await expect(
        coin100.connect(treasury).transfer(user1.address, ethers.utils.parseUnits("10", 18))
      ).to.be.revertedWith("EnforcedPause");
    });
  });

  describe("Rebase", function () {
    beforeEach(async function () {
      // Increase time to allow first rebase
      await ethers.provider.send("evm_increaseTime", [86400]); // 1 day
      await ethers.provider.send("evm_mine");
    });

    it("Should rebase correctly when market cap increases", async function () {
      // Initial total supply
      const initialSupply = await coin100.totalSupply();

      // Simulate rebase to double the market cap (max allowed is +100%)
      const newMarketCap = unscaledInitialMarketCap.mul(2);
      await coin100.connect(admin).rebase(newMarketCap);

      const newSupply = await coin100.totalSupply();
      // Allow for rounding differences
      const difference = newSupply.sub(initialSupply.mul(2)).abs();
      expect(difference).to.be.lt(ROUNDING_TOLERANCE);

      // Check treasury balance
      const treasuryBalance = await coin100.balanceOf(treasury.address);
      expect(treasuryBalance).to.equal(newSupply);
    });

    it("Should rebase correctly when market cap decreases", async function () {
      // Initial total supply
      const initialSupply = await coin100.totalSupply();

      // Simulate rebase to 75% of the market cap (within -50% limit)
      const newMarketCap = unscaledInitialMarketCap.mul(75).div(100);
      await coin100.connect(admin).rebase(newMarketCap);

      const newSupply = await coin100.totalSupply();
      // Allow for rounding differences
      const difference = newSupply.sub(initialSupply.mul(75).div(100)).abs();
      expect(difference).to.be.lt(ROUNDING_TOLERANCE);

      // Check treasury balance
      const treasuryBalance = await coin100.balanceOf(treasury.address);
      expect(treasuryBalance).to.equal(newSupply);
    });

    it("Should not allow rebase before frequency", async function () {
      const newMarketCap = unscaledInitialMarketCap.mul(2);
      await coin100.connect(admin).rebase(newMarketCap);

      // Attempt to rebase again immediately
      await expect(
        coin100.connect(admin).rebase(newMarketCap)
      ).to.be.revertedWith("Rebase frequency not met");
    });

    it("Should allow rebase after frequency", async function () {
      const newMarketCap = unscaledInitialMarketCap.mul(2);

      await coin100.connect(admin).rebase(newMarketCap);

      // Increase time beyond rebase frequency (default 1 day)
      await ethers.provider.send("evm_increaseTime", [86400]); // 1 day
      await ethers.provider.send("evm_mine");

      // Get the block timestamp for the next rebase
      const nextBlock = await ethers.provider.getBlock("latest");

      // Rebase again with the same market cap (no change)
      await expect(coin100.connect(admin).rebase(newMarketCap))
        .to.emit(coin100, "Rebase")
        .withArgs(
          newMarketCap.mul(ethers.utils.parseUnits("1", 18)), // oldMarketCapScaled
          newMarketCap.mul(ethers.utils.parseUnits("1", 18)), // newMarketCapScaled
          ethers.utils.parseUnits("1", 18), // rebaseFactor (no change)
          ethers.utils.parseUnits("1", 18), // rebaseFactorScaled
          nextBlock.timestamp // block timestamp
        );

      const newSupply = await coin100.totalSupply();
      // Allow for rounding differences
      const difference = newSupply.sub(initialMarketCap.mul(2)).abs();
      expect(difference).to.be.lt(ROUNDING_TOLERANCE);
    });
  });

  describe("Admin Functions", function () {
    it("Should set governor contract", async function () {
      await coin100.connect(treasury).setGovernorContract(admin.address);
      expect(await coin100.govContract()).to.equal(admin.address);
    });

    it("Only owner can set governor contract", async function () {
      await expect(
        coin100.connect(user1).setGovernorContract(admin.address)
      ).to.be.revertedWith("OwnableUnauthorizedAccount");
    });

    it("Should update treasury address", async function () {
      await coin100.connect(admin).updateTreasuryAddress(admin.address);
      expect(await coin100.treasury()).to.equal(admin.address);
    });

    it("Only admin can update treasury address", async function () {
      await expect(
        coin100.connect(user1).updateTreasuryAddress(admin.address)
      ).to.be.revertedWith("Not admin");
    });

    it("Should add and remove liquidity pools", async function () {
      const pool1 = user1.address;
      const pool2 = user2.address;

      await coin100.connect(admin).addLiquidityPool(pool1);
      await coin100.connect(admin).addLiquidityPool(pool2);

      expect(await coin100.getLiquidityPoolsCount()).to.equal(2);
      expect(await coin100.getLiquidityPoolAt(0)).to.equal(pool1);
      expect(await coin100.getLiquidityPoolAt(1)).to.equal(pool2);

      // Remove pool1
      await coin100.connect(admin).removeLiquidityPool(pool1);
      expect(await coin100.getLiquidityPoolsCount()).to.equal(1);
      expect(await coin100.getLiquidityPoolAt(0)).to.equal(pool2);
    });

    it("Only admin can add/remove liquidity pools", async function () {
      const pool = user1.address;

      await expect(
        coin100.connect(user1).addLiquidityPool(pool)
      ).to.be.revertedWith("Not admin");

      await coin100.connect(admin).addLiquidityPool(pool);

      await expect(
        coin100.connect(user1).removeLiquidityPool(pool)
      ).to.be.revertedWith("Not admin");
    });
  });
});
