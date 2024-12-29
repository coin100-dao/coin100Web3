/* eslint-disable no-undef */
const { expect } = require("chai");
const { ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");

describe("C100PublicSale Contract on Amoy", function () {
  let coin100, publicSale, mockUSDC;
  let owner;
  const ROUNDING_TOLERANCE = ethers.utils.parseUnits("1", 18);

  before(async function () {
    // Load deployment info
    const deploymentPath = path.join(__dirname, "../deployments/amoy_publicsale_deployment.json");
    if (!fs.existsSync(deploymentPath)) {
      throw new Error("Public Sale deployment info not found. Please deploy to Amoy first.");
    }
    const deployment = JSON.parse(fs.readFileSync(deploymentPath, "utf8"));

    [owner] = await ethers.getSigners();
    console.log("Testing with owner account:", owner.address);

    // Get contract instances
    const COIN100 = await ethers.getContractFactory("COIN100");
    coin100 = await COIN100.attach(deployment.coin100.address);

    const MockERC20 = await ethers.getContractFactory("MockERC20");
    mockUSDC = await MockERC20.attach(deployment.mockUSDC.address);

    const C100PublicSale = await ethers.getContractFactory("C100PublicSale");
    publicSale = await C100PublicSale.attach(deployment.publicSale.address);
  });

  describe("Initial State", function () {
    it("Should have correct initial setup", async function () {
      expect(await publicSale.owner()).to.equal(owner.address);
      expect(await publicSale.c100Token()).to.equal(coin100.address);
      expect(await publicSale.treasury()).to.equal(owner.address);

      const allowedToken = await publicSale.getAllowedToken(mockUSDC.address);
      expect(allowedToken.token).to.equal(mockUSDC.address);
    });

    it("Should have sufficient C100 tokens for sale", async function () {
      const balance = await coin100.balanceOf(publicSale.address);
      expect(balance).to.be.gt(0);
    });
  });

  describe("Token Purchase", function () {
    it("Should allow users to buy C100 with MockUSDC", async function () {
      // Create and fund test buyer
      const buyer = ethers.Wallet.createRandom().connect(ethers.provider);
      await owner.sendTransaction({
        to: buyer.address,
        value: ethers.utils.parseEther("0.1")
      });

      const paymentAmount = ethers.utils.parseUnits("100", 6); // 100 USDC
      await mockUSDC.mint(buyer.address, paymentAmount.mul(2)); // Mint extra for approval

      const allowedToken = await publicSale.getAllowedToken(mockUSDC.address);
      const expectedC100 = paymentAmount.mul(ethers.utils.parseUnits("1", 18)).div(allowedToken.rate);

      // Approve spending
      await mockUSDC.connect(buyer).approve(publicSale.address, paymentAmount);

      // Record initial balances
      const initialBuyerUSDC = await mockUSDC.balanceOf(buyer.address);
      const initialTreasuryUSDC = await mockUSDC.balanceOf(owner.address);
      const initialBuyerC100 = await coin100.balanceOf(buyer.address);

      // Buy tokens
      await expect(
        publicSale.connect(buyer).buyWithToken(mockUSDC.address, paymentAmount)
      ).to.emit(publicSale, "TokenPurchased")
        .withArgs(buyer.address, mockUSDC.address, paymentAmount, expectedC100);

      // Verify balances after purchase
      expect(await mockUSDC.balanceOf(buyer.address)).to.equal(initialBuyerUSDC.sub(paymentAmount));
      expect(await mockUSDC.balanceOf(owner.address)).to.equal(initialTreasuryUSDC.add(paymentAmount));

      const finalBuyerC100 = await coin100.balanceOf(buyer.address);
      const expectedC100AfterFees = expectedC100.mul(98).div(100); // 2% fee
      const c100Difference = finalBuyerC100.sub(initialBuyerC100).sub(expectedC100AfterFees).abs();
      expect(c100Difference).to.be.lt(ROUNDING_TOLERANCE);
    });

    it("Should handle multiple purchases correctly", async function () {
      // Create and fund test buyers
      const buyer1 = ethers.Wallet.createRandom().connect(ethers.provider);
      const buyer2 = ethers.Wallet.createRandom().connect(ethers.provider);

      await owner.sendTransaction({
        to: buyer1.address,
        value: ethers.utils.parseEther("0.1")
      });
      await owner.sendTransaction({
        to: buyer2.address,
        value: ethers.utils.parseEther("0.1")
      });

      const paymentAmount = ethers.utils.parseUnits("50", 6); // 50 USDC each
      await mockUSDC.mint(buyer1.address, paymentAmount.mul(2));
      await mockUSDC.mint(buyer2.address, paymentAmount.mul(2));

      await mockUSDC.connect(buyer1).approve(publicSale.address, paymentAmount);
      await mockUSDC.connect(buyer2).approve(publicSale.address, paymentAmount);

      // Both buyers purchase tokens
      await publicSale.connect(buyer1).buyWithToken(mockUSDC.address, paymentAmount);
      await publicSale.connect(buyer2).buyWithToken(mockUSDC.address, paymentAmount);

      // Verify both buyers received tokens
      const buyer1Balance = await coin100.balanceOf(buyer1.address);
      const buyer2Balance = await coin100.balanceOf(buyer2.address);
      expect(buyer1Balance).to.be.gt(0);
      expect(buyer2Balance).to.be.gt(0);
    });
  });

  describe("Admin Functions", function () {
    it("Should allow adding new payment tokens", async function () {
      // Deploy a new test token
      const NewToken = await ethers.getContractFactory("MockERC20");
      const newToken = await NewToken.deploy("NewToken", "NEW", 18);
      await newToken.deployed();

      // Add new token as payment option
      const rate = ethers.utils.parseUnits("0.002", 18);
      await publicSale.addAllowedToken(
        newToken.address,
        rate,
        "NEW",
        "New Token",
        18
      );

      // Verify token was added
      const allowedToken = await publicSale.getAllowedToken(newToken.address);
      expect(allowedToken.rate).to.equal(rate);
      expect(allowedToken.symbol).to.equal("NEW");
    });

    it("Should allow updating treasury address", async function () {
      const newTreasury = ethers.Wallet.createRandom().address;
      await publicSale.updateTreasury(newTreasury);
      expect(await publicSale.treasury()).to.equal(newTreasury);

      // Reset treasury
      await publicSale.updateTreasury(owner.address);
    });

    it("Should allow pausing and unpausing", async function () {
      const testBuyer = ethers.Wallet.createRandom().connect(ethers.provider);
      await owner.sendTransaction({
        to: testBuyer.address,
        value: ethers.utils.parseEther("0.1")
      });

      const paymentAmount = ethers.utils.parseUnits("10", 6);
      await mockUSDC.mint(testBuyer.address, paymentAmount.mul(2));
      await mockUSDC.connect(testBuyer).approve(publicSale.address, paymentAmount);

      await publicSale.pauseContract();
      await expect(
        publicSale.connect(testBuyer).buyWithToken(mockUSDC.address, paymentAmount)
      ).to.be.revertedWith("EnforcedPause");

      await publicSale.unpauseContract();
      await expect(
        publicSale.connect(testBuyer).buyWithToken(mockUSDC.address, paymentAmount)
      ).to.not.be.reverted;
    });
  });
}); 