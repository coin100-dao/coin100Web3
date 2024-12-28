// test/c100publicsale.test.js
/* global describe, it, beforeEach */
import { expect } from "chai";
import { ethers } from "hardhat";

describe("C100PublicSale Contract", function () {
  let COIN100, coin100;
  let C100PublicSale, publicSale;
  let treasury, admin, buyer, mockPaymentToken;
  const initialMarketCap = ethers.utils.parseUnits("1000", 18); // 1000 * 1e18
  const initialRate = ethers.utils.parseUnits("0.001", 18); // 0.001 token per C100

  beforeEach(async function () {
    [, treasury, admin, buyer] = await ethers.getSigners();

    // Deploy COIN100
    COIN100 = await ethers.getContractFactory("COIN100");
    coin100 = await COIN100.deploy(initialMarketCap, treasury.address);
    await coin100.deployed();

    // Deploy a mock payment token (e.g., MockUSDC)
    const MockERC20 = await ethers.getContractFactory("MockERC20");
    mockPaymentToken = await MockERC20.deploy("MockUSDC", "MUSDC", 6);
    await mockPaymentToken.deployed();

    // Mint some MockUSDC to buyer
    await mockPaymentToken.mint(buyer.address, ethers.utils.parseUnits("1000", 6));

    // Deploy C100PublicSale
    C100PublicSale = await ethers.getContractFactory("C100PublicSale");

    const currentTime = Math.floor(Date.now() / 1000);
    const startTime = currentTime + 60; // Starts in 1 minute
    const endTime = startTime + 30 * 24 * 60 * 60; // Ends in 30 days

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
    await coin100.transfer(publicSale.address, ethers.utils.parseUnits("500", 18));
  });

  describe("Deployment", function () {
    it("Should set the right owner and treasury", async function () {
      expect(await publicSale.owner()).to.equal(treasury.address);
      expect(await publicSale.treasury()).to.equal(treasury.address);
    });

    it("Should initialize with correct parameters", async function () {
      expect(await publicSale.c100Token()).to.equal(coin100.address);
      expect(await publicSale.startTime()).to.be.gt(0);
      expect(await publicSale.endTime()).to.be.gt(await publicSale.startTime());
    });
  });

  describe("Purchases", function () {
    beforeEach(async function () {
      // Fast forward time to after ICO start
      await ethers.provider.send("evm_setNextBlockTimestamp", [await publicSale.startTime()]);
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

      // Check buyer's C100 balance
      const buyerC100 = await coin100.balanceOf(buyer.address);
      expect(buyerC100).to.equal(expectedC100);

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
      const futureStart = Math.floor(Date.now() / 1000) + 3600; // 1 hour from now
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
        publicSale.addAllowedToken(
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
      await expect(publicSale.removeAllowedToken(anotherToken.address))
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
      ).to.be.revertedWith("Ownable: caller is not the owner");

      await expect(
        publicSale.connect(nonOwner).removeAllowedToken(mockPaymentToken.address)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("Should finalize ICO and burn unsold tokens", async function () {
      // Fast forward time to after ICO end
      await ethers.provider.send("evm_setNextBlockTimestamp", [await publicSale.endTime()]);
      await ethers.provider.send("evm_mine");

      const unsoldTokens = await coin100.balanceOf(publicSale.address);

      // Finalize
      await expect(publicSale.finalize())
        .to.emit(publicSale, "Finalized")
        .withArgs(unsoldTokens);

      // Check that unsold tokens are burned (sent to dead address)
      const deadAddress = "0x000000000000000000000000000000000000dEaD";
      const deadBalance = await coin100.balanceOf(deadAddress);
      expect(deadBalance).to.equal(unsoldTokens);

      // Check that public sale is finalized
      expect(await publicSale.finalized()).to.be.true;
    });

    it("Only owner can finalize the ICO", async function () {
      await expect(
        publicSale.connect(admin).finalize()
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });
  });
});
