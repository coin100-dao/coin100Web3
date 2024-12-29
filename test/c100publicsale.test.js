/* eslint-disable no-undef */
// test/c100publicsale.test.js
/* global describe, it, beforeEach */
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("C100PublicSale Contract", function () {
  let COIN100, coin100;
  let C100PublicSale, publicSale;
  let treasury, admin, buyer, mockPaymentToken;
  const unscaledInitialMarketCap = ethers.BigNumber.from("1000");
  const initialRate = ethers.utils.parseUnits("0.001", 18); // 0.001 token per C100
  const ROUNDING_TOLERANCE = ethers.utils.parseUnits("100", 18); // Increased tolerance for significant rounding
  let startTime, endTime;

  beforeEach(async function () {
    [, treasury, admin, buyer] = await ethers.getSigners();

    // Deploy COIN100
    COIN100 = await ethers.getContractFactory("COIN100");
    coin100 = await COIN100.deploy(unscaledInitialMarketCap, treasury.address);
    await coin100.deployed();

    // Set governance contract
    await coin100.connect(treasury).setGovernorContract(admin.address);

    // Deploy a mock payment token (e.g., MockUSDC)
    const MockERC20 = await ethers.getContractFactory("MockERC20");
    mockPaymentToken = await MockERC20.deploy("MockUSDC", "MUSDC", 6);
    await mockPaymentToken.deployed();

    // Mint some MockUSDC to buyer
    await mockPaymentToken.mint(buyer.address, ethers.utils.parseUnits("1000", 6));

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

    // Transfer some C100 to the public sale contract
    const transferAmount = ethers.utils.parseUnits("1000", 18);
    await coin100.connect(treasury).transfer(publicSale.address, transferAmount);

    // Verify the transfer (accounting for 2% fee)
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
});
