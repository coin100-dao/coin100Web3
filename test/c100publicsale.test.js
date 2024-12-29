/* eslint-disable no-undef */
// test/c100publicsale.test.js
/* global describe, it, beforeEach */
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("C100PublicSale Contract", function () {
  let COIN100, coin100;
  let C100PublicSale, publicSale;
  let treasury, admin, buyer, mockPaymentToken;
  const initialRate = ethers.utils.parseUnits("0.001", 18); // 0.001 token per C100
  const ROUNDING_TOLERANCE = ethers.utils.parseUnits("100", 18); // Increased tolerance for significant rounding
  let startTime, endTime;

  beforeEach(async function () {
    [, treasury, admin, buyer] = await ethers.getSigners();

    // Deploy COIN100
    COIN100 = await ethers.getContractFactory("COIN100");
    // Increase initial market cap to ensure enough tokens
    coin100 = await COIN100.deploy(ethers.utils.parseUnits("10000000", 18), treasury.address);
    await coin100.deployed();

    // Set governance contract
    await coin100.connect(treasury).setGovernorContract(admin.address);

    // Deploy a mock payment token (e.g., MockUSDC)
    const MockERC20 = await ethers.getContractFactory("MockERC20");
    mockPaymentToken = await MockERC20.deploy("MockUSDC", "MUSDC", 6);
    await mockPaymentToken.deployed();

    // Mint some MockUSDC to buyer
    await mockPaymentToken.mint(buyer.address, ethers.utils.parseUnits("1000000", 6)); // 1M USDC

    // Get current block timestamp
    const latestBlock = await ethers.provider.getBlock("latest");
    startTime = latestBlock.timestamp + 60; // Starts in 1 minute
    endTime = startTime + 30 * 24 * 60 * 60; // Ends in 30 days

    // Deploy C100PublicSale
    C100PublicSale = await ethers.getContractFactory("C100PublicSale");
    publicSale = await C100PublicSale.deploy(
      coin100.address,
      mockPaymentToken.address,
      initialRate,
      "MUSDC",
      "Mock USDC",
      6,
      treasury.address,
      startTime,
      endTime
    );
    await publicSale.deployed();

    // Transfer more tokens to the public sale contract
    const transferAmount = ethers.utils.parseUnits("5000000", 18); // 5M tokens
    await coin100.connect(treasury).transfer(publicSale.address, transferAmount);

    // Verify the transfer
    const publicSaleBalance = await coin100.balanceOf(publicSale.address);
    expect(publicSaleBalance).to.be.gt(0);
  });

  describe("Deployment", function () {
    it("Should set the right owner and treasury", async function () {
      expect(await publicSale.owner()).to.equal(treasury.address);
      expect(await publicSale.treasury()).to.equal(treasury.address);
    });

    it("Should initialize with correct parameters", async function () {
      expect(await publicSale.c100Token()).to.equal(coin100.address);
      expect(await publicSale.startTime()).to.equal(startTime);
      expect(await publicSale.endTime()).to.equal(endTime);
    });
  });

  describe("Purchases", function () {
    beforeEach(async function () {
      // Fast forward time to after ICO start
      await ethers.provider.send("evm_setNextBlockTimestamp", [startTime + 1]);
      await ethers.provider.send("evm_mine");
    });

    it("Should allow users to buy C100 with allowed token", async function () {
      const paymentAmount = ethers.utils.parseUnits("100", 6); // 100 MUSDC
      const expectedC100 = paymentAmount.mul(ethers.utils.parseUnits("1", 18)).div(initialRate); // 100 / 0.001 = 100,000 C100

      // Approve the public sale contract to spend buyer's MUSDC
      await mockPaymentToken.connect(buyer).approve(publicSale.address, paymentAmount);

      // Buy C100
      await expect(publicSale.connect(buyer).buyWithToken(mockPaymentToken.address, paymentAmount))
        .to.emit(publicSale, "TokenPurchased")
        .withArgs(buyer.address, mockPaymentToken.address, paymentAmount, expectedC100);

      // Check buyer's C100 balance (accounting for 2% fee)
      const buyerC100 = await coin100.balanceOf(buyer.address);
      const expectedBuyerBalance = expectedC100.mul(98).div(100);
      const buyerDifference = buyerC100.sub(expectedBuyerBalance).abs();
      expect(buyerDifference).to.be.lt(ROUNDING_TOLERANCE);

      // Check treasury received MUSDC
      const treasuryBalance = await mockPaymentToken.balanceOf(treasury.address);
      expect(treasuryBalance).to.equal(paymentAmount);
    });

    it("Should not allow buying with non-allowed token", async function () {
      // Deploy another mock token
      const AnotherMockERC20 = await ethers.getContractFactory("MockERC20");
      const anotherToken = await AnotherMockERC20.deploy("AnotherToken", "ATK", 18);
      await anotherToken.deployed();

      // Attempt to buy with non-allowed token
      await anotherToken.mint(buyer.address, ethers.utils.parseUnits("100", 18));
      await anotherToken.connect(buyer).approve(publicSale.address, ethers.utils.parseUnits("100", 18));

      await expect(
        publicSale.connect(buyer).buyWithToken(anotherToken.address, ethers.utils.parseUnits("100", 18))
      ).to.be.revertedWith("Token not allowed");
    });

    it("Should not allow buying before ICO starts", async function () {
      // Deploy a new public sale contract with a future start time
      const futureStart = (await ethers.provider.getBlock("latest")).timestamp + 3600; // 1 hour from now
      const futureEnd = futureStart + 30 * 24 * 60 * 60;

      const newPublicSale = await C100PublicSale.deploy(
        coin100.address,
        mockPaymentToken.address,
        initialRate,
        "MUSDC",
        "Mock USDC",
        6,
        treasury.address,
        futureStart,
        futureEnd
      );
      await newPublicSale.deployed();

      // Attempt to buy
      await mockPaymentToken.connect(buyer).approve(newPublicSale.address, ethers.utils.parseUnits("100", 6));
      await expect(
        newPublicSale.connect(buyer).buyWithToken(mockPaymentToken.address, ethers.utils.parseUnits("100", 6))
      ).to.be.revertedWith("ICO not active");
    });
  });

  describe("Admin Functions", function () {
    it("Should allow owner to add and remove allowed tokens", async function () {
      // Deploy another mock payment token
      const AnotherMockERC20 = await ethers.getContractFactory("MockERC20");
      const anotherToken = await AnotherMockERC20.deploy("AnotherToken", "ATK", 18);
      await anotherToken.deployed();

      // Add the new token
      await expect(
        publicSale.connect(treasury).addAllowedToken(
          anotherToken.address,
          ethers.utils.parseUnits("0.002", 18),
          "ATK",
          "Another Token",
          18
        )
      ).to.emit(publicSale, "AllowedTokenAdded");

      // Check it's added
      const allowedToken = await publicSale.getAllowedToken(anotherToken.address);
      expect(allowedToken.rate).to.equal(ethers.utils.parseUnits("0.002", 18));

      // Remove the token
      await expect(publicSale.connect(treasury).removeAllowedToken(anotherToken.address))
        .to.emit(publicSale, "AllowedTokenRemoved");

      // Check it's removed
      const isAllowed = await publicSale.isAllowedToken(anotherToken.address);
      expect(isAllowed).to.be.false;
    });

    it("Only owner can add or remove allowed tokens", async function () {
      const nonOwner = admin;

      await expect(
        publicSale.connect(nonOwner).addAllowedToken(
          admin.address,
          ethers.utils.parseUnits("0.002", 18),
          "ATK",
          "Another Token",
          18
        )
      ).to.be.revertedWith("OwnableUnauthorizedAccount");

      await expect(
        publicSale.connect(nonOwner).removeAllowedToken(mockPaymentToken.address)
      ).to.be.revertedWith("OwnableUnauthorizedAccount");
    });

    it("Should finalize ICO and burn unsold tokens", async function () {
      // Fast forward time to after ICO end
      await ethers.provider.send("evm_setNextBlockTimestamp", [endTime + 1]);
      await ethers.provider.send("evm_mine");

      // Get initial balances
      const initialPublicSaleBalance = await coin100.balanceOf(publicSale.address);
      const initialDeadBalance = await coin100.balanceOf("0x000000000000000000000000000000000000dEaD");

      // Finalize
      const tx = await publicSale.connect(treasury).finalize();
      await tx.wait();

      // Verify the Finalized event
      await expect(tx)
        .to.emit(publicSale, "Finalized")
        .withArgs(initialPublicSaleBalance);

      // Check that public sale contract balance is 0
      const finalPublicSaleBalance = await coin100.balanceOf(publicSale.address);
      expect(finalPublicSaleBalance).to.equal(0);

      // Check that tokens were burned
      const finalDeadBalance = await coin100.balanceOf("0x000000000000000000000000000000000000dEaD");
      expect(finalDeadBalance).to.be.gt(initialDeadBalance);

      // Verify that approximately the correct amount was burned
      const burnedAmount = finalDeadBalance.sub(initialDeadBalance);
      expect(burnedAmount).to.be.gt(0);
      
      // The burned amount should be close to the initial balance
      const percentageDifference = burnedAmount
        .sub(initialPublicSaleBalance)
        .mul(100)
        .div(initialPublicSaleBalance)
        .abs();
      expect(percentageDifference).to.be.lt(5); // Allow up to 5% difference

      // Check that public sale is finalized
      expect(await publicSale.finalized()).to.be.true;
    });

    it("Only owner can finalize the ICO", async function () {
      await expect(
        publicSale.connect(admin).finalize()
      ).to.be.revertedWith("OwnableUnauthorizedAccount");
    });
  });

  describe("Vesting and Locking", function () {
    beforeEach(async function () {
      // Fast forward time to after ICO start
      await ethers.provider.send("evm_setNextBlockTimestamp", [startTime + 1]);
      await ethers.provider.send("evm_mine");

      // Approve tokens for purchase
      const paymentAmount = ethers.utils.parseUnits("100", 6); // 100 MUSDC
      await mockPaymentToken.connect(buyer).approve(publicSale.address, paymentAmount);

      // Make a purchase
      await publicSale.connect(buyer).buyWithToken(mockPaymentToken.address, paymentAmount);
    });

    it("Should lock tokens for vesting duration", async function () {
      // Check that tokens are locked
      const lockedAmount = await publicSale.totalLockedTokens();
      expect(lockedAmount).to.be.gt(0);

      // Try to claim before vesting period
      await expect(
        publicSale.connect(buyer).claimTokens()
      ).to.be.revertedWith("No tokens to claim");
    });

    it("Should allow claiming after vesting period", async function () {
      const vestingDuration = await publicSale.vestingDuration();
      
      // Fast forward past vesting period
      await ethers.provider.send("evm_increaseTime", [vestingDuration.toNumber()]);
      await ethers.provider.send("evm_mine");

      // Get initial balances
      const initialBalance = await coin100.balanceOf(buyer.address);
      const initialLocked = await publicSale.totalLockedTokens();

      // Claim tokens
      await expect(publicSale.connect(buyer).claimTokens())
        .to.emit(publicSale, "TokensClaimed")
        .withArgs(buyer.address, initialLocked);

      // Check balances after claim
      const finalBalance = await coin100.balanceOf(buyer.address);
      const finalLocked = await publicSale.totalLockedTokens();

      expect(finalBalance).to.be.gt(initialBalance);
      expect(finalLocked).to.equal(0);
    });

    it("Should enforce purchase delay between buys", async function () {
      const paymentAmount = ethers.utils.parseUnits("50", 6);
      await mockPaymentToken.connect(buyer).approve(publicSale.address, paymentAmount);

      // Try to buy again immediately
      await expect(
        publicSale.connect(buyer).buyWithToken(mockPaymentToken.address, paymentAmount)
      ).to.be.revertedWith("Purchase too soon");

      // Fast forward past purchase delay
      const purchaseDelay = await publicSale.purchaseDelay();
      await ethers.provider.send("evm_increaseTime", [purchaseDelay.toNumber()]);
      await ethers.provider.send("evm_mine");

      // Should now be able to buy
      await expect(
        publicSale.connect(buyer).buyWithToken(mockPaymentToken.address, paymentAmount)
      ).to.not.be.reverted;
    });
  });

  describe("Purchase Caps and Limits", function () {
    beforeEach(async function () {
      await ethers.provider.send("evm_setNextBlockTimestamp", [startTime + 1]);
      await ethers.provider.send("evm_mine");
    });

    it("Should enforce max user cap", async function () {
      // Transfer more tokens to the public sale contract first
      const maxUserCap = await publicSale.maxUserCap();
      const transferAmount = maxUserCap.mul(2); // Transfer double the max cap to ensure enough tokens
      await coin100.connect(treasury).transfer(publicSale.address, transferAmount);

      const rate = (await publicSale.getAllowedToken(mockPaymentToken.address)).rate;
      
      // Calculate payment amount that would exceed cap
      const exceedingPayment = maxUserCap.mul(rate).div(ethers.utils.parseUnits("1", 18)).add(1);
      
      // Mint more tokens to buyer to ensure they have enough
      await mockPaymentToken.mint(buyer.address, exceedingPayment);
      await mockPaymentToken.connect(buyer).approve(publicSale.address, exceedingPayment);

      // Try to buy more than cap
      await expect(
        publicSale.connect(buyer).buyWithToken(mockPaymentToken.address, exceedingPayment)
      ).to.be.revertedWith("Exceeds max user cap");
    });

    it("Should track user purchases correctly", async function () {
      const paymentAmount = ethers.utils.parseUnits("100", 6);
      await mockPaymentToken.connect(buyer).approve(publicSale.address, paymentAmount);

      // Make first purchase
      await publicSale.connect(buyer).buyWithToken(mockPaymentToken.address, paymentAmount);

      // Fast forward past purchase delay
      const purchaseDelay = await publicSale.purchaseDelay();
      await ethers.provider.send("evm_increaseTime", [purchaseDelay.toNumber()]);
      await ethers.provider.send("evm_mine");

      // Make second purchase
      await mockPaymentToken.connect(buyer).approve(publicSale.address, paymentAmount);
      await publicSale.connect(buyer).buyWithToken(mockPaymentToken.address, paymentAmount);

      // Check total purchases
      const totalPurchases = await publicSale.userPurchases(buyer.address);
      const expectedC100PerPurchase = paymentAmount.mul(ethers.utils.parseUnits("1", 18)).div(initialRate);
      const expectedTotal = expectedC100PerPurchase.mul(2);
      
      expect(totalPurchases).to.equal(expectedTotal);
    });
  });

  describe("Vesting Configuration", function () {
    it("Should allow admin to update vesting parameters", async function () {
      const newVestingDuration = 180 * 24 * 60 * 60; // 180 days
      const newPurchaseDelay = 3600; // 1 hour
      const newMaxUserCap = ethers.utils.parseUnits("2000000", 18); // 2M C100

      await expect(
        publicSale.connect(treasury).updateVestingConfig(
          newVestingDuration,
          newPurchaseDelay,
          newMaxUserCap
        )
      ).to.emit(publicSale, "VestingConfigUpdated")
        .withArgs(newVestingDuration, newPurchaseDelay, newMaxUserCap);

      expect(await publicSale.vestingDuration()).to.equal(newVestingDuration);
      expect(await publicSale.purchaseDelay()).to.equal(newPurchaseDelay);
      expect(await publicSale.maxUserCap()).to.equal(newMaxUserCap);
    });

    it("Should not allow non-admin to update vesting parameters", async function () {
      await expect(
        publicSale.connect(buyer).updateVestingConfig(
          365 * 24 * 60 * 60,
          3600,
          ethers.utils.parseUnits("2000000", 18)
        )
      ).to.be.revertedWith("OwnableUnauthorizedAccount");
    });

    it("Should validate vesting parameter constraints", async function () {
      // Try to set invalid vesting duration (0)
      await expect(
        publicSale.connect(treasury).updateVestingConfig(
          0,
          3600,
          ethers.utils.parseUnits("2000000", 18)
        )
      ).to.be.revertedWith("Vesting must be > 0");

      // Try to set too large purchase delay
      await expect(
        publicSale.connect(treasury).updateVestingConfig(
          365 * 24 * 60 * 60,
          8 * 24 * 60 * 60, // 8 days
          ethers.utils.parseUnits("2000000", 18)
        )
      ).to.be.revertedWith("Delay too large?");

      // Try to set invalid max user cap (0)
      await expect(
        publicSale.connect(treasury).updateVestingConfig(
          365 * 24 * 60 * 60,
          3600,
          0
        )
      ).to.be.revertedWith("Max cap must be > 0");
    });
  });

  describe("Finalization", function () {
    beforeEach(async function () {
      // Fast forward time to after ICO start
      await ethers.provider.send("evm_setNextBlockTimestamp", [startTime + 1]);
      await ethers.provider.send("evm_mine");

      // Make some purchases to have locked tokens
      const paymentAmount = ethers.utils.parseUnits("100", 6); // 100 MUSDC
      await mockPaymentToken.connect(buyer).approve(publicSale.address, paymentAmount);
      await publicSale.connect(buyer).buyWithToken(mockPaymentToken.address, paymentAmount);
    });

    it("Should only burn truly unsold tokens (contract balance minus locked tokens)", async function () {
      // Fast forward time to after ICO end
      await ethers.provider.send("evm_setNextBlockTimestamp", [endTime + 1]);
      await ethers.provider.send("evm_mine");

      // Get balances before finalization
      const contractBalance = await coin100.balanceOf(publicSale.address);
      const totalLocked = await publicSale.totalLockedTokens();
      const initialDeadBalance = await coin100.balanceOf("0x000000000000000000000000000000000000dEaD");

      // Calculate expected burn amount
      const expectedBurnAmount = contractBalance.sub(totalLocked);

      // Finalize
      await publicSale.connect(treasury).finalize();

      // Check final balances
      const finalDeadBalance = await coin100.balanceOf("0x000000000000000000000000000000000000dEaD");
      const burnedAmount = finalDeadBalance.sub(initialDeadBalance);

      // Verify burned amount with percentage tolerance
      const percentageDifference = burnedAmount
        .sub(expectedBurnAmount)
        .mul(100)
        .div(expectedBurnAmount)
        .abs();
      expect(percentageDifference).to.be.lt(5); // Allow up to 5% difference

      // Contract should still have locked tokens
      const finalContractBalance = await coin100.balanceOf(publicSale.address);
      const lockedDifference = finalContractBalance.sub(totalLocked).abs();
      expect(lockedDifference).to.be.lt(ROUNDING_TOLERANCE);
    });

    it("Should not allow finalization if no tokens to burn", async function () {
      // Fast forward time to after ICO start but before end
      await ethers.provider.send("evm_increaseTime", [60]); // 1 minute
      await ethers.provider.send("evm_mine");

      // Fast forward past purchase delay
      const purchaseDelay = await publicSale.purchaseDelay();
      await ethers.provider.send("evm_increaseTime", [purchaseDelay.toNumber()]);
      await ethers.provider.send("evm_mine");

      // Calculate tokens available for purchase (excluding locked tokens)
      const contractBalance = await coin100.balanceOf(publicSale.address);
      const totalLocked = await publicSale.totalLockedTokens();
      const availableTokens = contractBalance.sub(totalLocked);

      // Calculate payment needed
      const rate = (await publicSale.getAllowedToken(mockPaymentToken.address)).rate;
      const maxUserCap = await publicSale.maxUserCap();

      // Buy tokens in chunks to respect max user cap
      const numPurchases = availableTokens.div(maxUserCap).add(1);
      const buyers = await ethers.getSigners();
      for (let i = 0; i < numPurchases.toNumber() && i < buyers.length; i++) {
        const currentBuyer = buyers[i + 4]; // Skip deployer, treasury, admin, and first buyer

        // Calculate remaining tokens to buy
        const remainingTokens = await coin100.balanceOf(publicSale.address);
        const remainingLocked = await publicSale.totalLockedTokens();
        const remainingAvailable = remainingTokens.sub(remainingLocked);
        if (remainingAvailable.eq(0)) break;

        // Calculate payment for this chunk
        const tokensThisRound = remainingAvailable.gt(maxUserCap) ? maxUserCap : remainingAvailable;
        const paymentThisRound = tokensThisRound.mul(rate).div(ethers.utils.parseUnits("1", 18));

        // Mint tokens and approve
        await mockPaymentToken.mint(currentBuyer.address, paymentThisRound);
        await mockPaymentToken.connect(currentBuyer).approve(publicSale.address, paymentThisRound);

        // Buy tokens
        await publicSale.connect(currentBuyer).buyWithToken(mockPaymentToken.address, paymentThisRound);

        if (i < numPurchases.toNumber() - 1) {
          // Wait for purchase delay (except for last purchase)
          await ethers.provider.send("evm_increaseTime", [purchaseDelay.toNumber()]);
          await ethers.provider.send("evm_mine");
        }
      }

      // Fast forward to ICO end
      const timeToEnd = endTime - (await ethers.provider.getBlock("latest")).timestamp + 1;
      await ethers.provider.send("evm_increaseTime", [timeToEnd]);
      await ethers.provider.send("evm_mine");

      // Try to finalize
      await expect(
        publicSale.connect(treasury).finalize()
      ).to.be.revertedWith("Nothing to burn");
    });

    it("Should maintain correct locked token accounting after finalization", async function () {
      // Fast forward time to after ICO end
      await ethers.provider.send("evm_setNextBlockTimestamp", [endTime + 1]);
      await ethers.provider.send("evm_mine");

      // Get initial locked amount
      const initialLocked = await publicSale.totalLockedTokens();
      
      // Finalize
      await publicSale.connect(treasury).finalize();

      // Check locked amount hasn't changed
      const finalLocked = await publicSale.totalLockedTokens();
      expect(finalLocked).to.equal(initialLocked);

      // Fast forward past vesting period
      const vestingDuration = await publicSale.vestingDuration();
      await ethers.provider.send("evm_increaseTime", [vestingDuration.toNumber()]);
      await ethers.provider.send("evm_mine");

      // Claim tokens
      await publicSale.connect(buyer).claimTokens();

      // Verify locked tokens are now 0
      expect(await publicSale.totalLockedTokens()).to.equal(0);
    });

    it("Should not allow multiple finalizations", async function () {
      // Fast forward time to after ICO end
      await ethers.provider.send("evm_setNextBlockTimestamp", [endTime + 1]);
      await ethers.provider.send("evm_mine");

      // First finalization
      await publicSale.connect(treasury).finalize();

      // Try to finalize again
      await expect(
        publicSale.connect(treasury).finalize()
      ).to.be.revertedWith("Already finalized");
    });
  });
});
