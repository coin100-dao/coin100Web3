// test/coin100.test.js
/* global describe, it, beforeEach */
import { expect } from "chai";
import { ethers } from "hardhat";

describe("COIN100 Contract", function () {
  let COIN100, coin100;
  let treasury, admin, user1, user2;
  const initialMarketCap = ethers.utils.parseUnits("1000", 18); // 1000 * 1e18

  beforeEach(async function () {
    [, treasury, admin, user1, user2] = await ethers.getSigners();

    // Deploy COIN100
    COIN100 = await ethers.getContractFactory("COIN100");
    coin100 = await COIN100.deploy(initialMarketCap, treasury.address);
    await coin100.deployed();
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
      // Transfer 100 C100 from treasury to user1
      await coin100.transfer(user1.address, ethers.utils.parseUnits("100", 18));

      const user1Balance = await coin100.balanceOf(user1.address);
      expect(user1Balance).to.equal(ethers.utils.parseUnits("100", 18));

      // User1 transfers 50 C100 to user2
      await coin100.connect(user1).transfer(user2.address, ethers.utils.parseUnits("50", 18));

      const user2Balance = await coin100.balanceOf(user2.address);
      // With 2% fee, user2 should receive 49 tokens (50 - 1 fee)
      expect(user2Balance).to.equal(ethers.utils.parseUnits("49", 18));

      const treasuryBalance = await coin100.balanceOf(treasury.address);
      // Treasury receives 1 token fee
      expect(treasuryBalance).to.equal(initialMarketCap.sub(ethers.utils.parseUnits("100", 18)).add(ethers.utils.parseUnits("1", 18)));
    });

    it("Should not allow transfers when paused", async function () {
      await coin100.pauseContract();
      await expect(
        coin100.transfer(user1.address, ethers.utils.parseUnits("10", 18))
      ).to.be.revertedWith("Pausable: paused");
    });
  });

  describe("Rebase", function () {
    it("Should rebase correctly when market cap increases", async function () {
      // Initial total supply
      const initialSupply = await coin100.totalSupply();

      // Simulate rebase to double the market cap
      const newMarketCap = 2000; // Double
      await coin100.rebase(newMarketCap);

      const newSupply = await coin100.totalSupply();
      expect(newSupply).to.equal(initialSupply.mul(2));

      // Check treasury balance
      const treasuryBalance = await coin100.balanceOf(treasury.address);
      expect(treasuryBalance).to.equal(newSupply);
    });

    it("Should rebase correctly when market cap decreases", async function () {
      // Initial total supply
      const initialSupply = await coin100.totalSupply();

      // Simulate rebase to halve the market cap
      const newMarketCap = 500; // Half
      await coin100.rebase(newMarketCap);

      const newSupply = await coin100.totalSupply();
      expect(newSupply).to.equal(initialSupply.div(2));

      // Check treasury balance
      const treasuryBalance = await coin100.balanceOf(treasury.address);
      expect(treasuryBalance).to.equal(newSupply);
    });

    it("Should not allow rebase before frequency", async function () {
      const newMarketCap = 2000;

      await coin100.rebase(newMarketCap);

      // Attempt to rebase again immediately
      await expect(
        coin100.rebase(newMarketCap)
      ).to.be.revertedWith("Rebase frequency not met");
    });

    it("Should allow rebase after frequency", async function () {
      const newMarketCap = 2000;

      await coin100.rebase(newMarketCap);

      // Increase time beyond rebase frequency (default 1 day)
      await ethers.provider.send("evm_increaseTime", [86400]); // 1 day
      await ethers.provider.send("evm_mine");

      // Rebase again
      await expect(coin100.rebase(newMarketCap))
        .to.emit(coin100, "Rebase")
        .withArgs(
          initialMarketCap.mul(1e18), // oldMarketCapScaled
          ethers.utils.parseUnits("2000", 18),
          ethers.utils.parseUnits("2", 18),
          ethers.utils.parseUnits("1", 18),
          await ethers.provider.getBlockNumber()
        );

      const newSupply = await coin100.totalSupply();
      expect(newSupply).to.equal(initialMarketCap.mul(2));
    });
  });

  describe("Admin Functions", function () {
    it("Should set governor contract", async function () {
      await coin100.setGovernorContract(admin.address);
      expect(await coin100.govContract()).to.equal(admin.address);
    });

    it("Only admin can set governor contract", async function () {
      await expect(
        coin100.connect(user1).setGovernorContract(admin.address)
      ).to.be.revertedWith("Not admin");
    });

    it("Should update treasury address", async function () {
      await coin100.updateTreasuryAddress(admin.address);
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

    it("Only admin can add/remove liquidity pools", async function () {
      const pool = user1.address;

      await expect(
        coin100.connect(user1).addLiquidityPool(pool)
      ).to.be.revertedWith("Not admin");

      await coin100.addLiquidityPool(pool);

      await expect(
        coin100.connect(user1).removeLiquidityPool(pool)
      ).to.be.revertedWith("Not admin");
    });
  });
});
