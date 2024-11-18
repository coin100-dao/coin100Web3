const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("COIN100Token", function () {
  let COIN100Token;
  let coin100;
  let owner;
  let addr1;
  let addr2;
  let developerTreasury;
  let liquidityPool;
  let marketingWallet;
  let stakingRewards;
  let communityTreasury;
  let reserveWallet;

  beforeEach(async function () {
    [owner, addr1, addr2, developerTreasury, liquidityPool, marketingWallet, stakingRewards, communityTreasury, reserveWallet] = await ethers.getSigners();

    COIN100Token = await ethers.getContractFactory("COIN100Token");
    coin100 = await COIN100Token.deploy(
      developerTreasury.address, // COIN100 Developer Treasury
      liquidityPool.address,     // COIN100 Liquidity Pool
      marketingWallet.address,   // COIN100 Marketing
      stakingRewards.address,    // COIN100 Staking Rewards
      communityTreasury.address,// COIN100 Community Governance
      reserveWallet.address      // COIN100 Reserve Wallet
    );
    await coin100.deployed();
  });

  it("Should have correct total supply", async function () {
    expect(await coin100.totalSupply()).to.equal(ethers.utils.parseUnits("1000000000", 18));
  });

  it("Should allocate tokens correctly upon deployment", async function () {
    const publicSaleAmount = ethers.utils.parseUnits("500000000", 18);
    const developerAmount = ethers.utils.parseUnits("100000000", 18);
    const liquidityAmount = ethers.utils.parseUnits("200000000", 18);
    const marketingAmount = ethers.utils.parseUnits("70000000", 18);
    const stakingAmount = ethers.utils.parseUnits("50000000", 18);
    const communityAmount = ethers.utils.parseUnits("30000000", 18);
    const reserveAmount = ethers.utils.parseUnits("50000000", 18);

    expect(await coin100.balanceOf(owner.address)).to.equal(publicSaleAmount);
    expect(await coin100.balanceOf(developerTreasury.address)).to.equal(developerAmount);
    expect(await coin100.balanceOf(liquidityPool.address)).to.equal(liquidityAmount);
    expect(await coin100.balanceOf(marketingWallet.address)).to.equal(marketingAmount);
    expect(await coin100.balanceOf(stakingRewards.address)).to.equal(stakingAmount);
    expect(await coin100.balanceOf(communityTreasury.address)).to.equal(communityAmount);
    expect(await coin100.balanceOf(reserveWallet.address)).to.equal(reserveAmount);
  });

  it("Should apply transfer fees correctly", async function () {
    // Owner transfers 1000 tokens to addr1
    await coin100.transfer(addr1.address, ethers.utils.parseUnits("1000", 18));

    // Calculate expected fees
    const transferFee = ethers.utils.parseUnits("3", 18); // 0.3% of 1000
    const developerFee = ethers.utils.parseUnits("0.6", 18); // 0.2% of 1000
    const liquidityFee = ethers.utils.parseUnits("0.48", 18); // 0.16% of 1000
    const communityFee = ethers.utils.parseUnits("0.36", 18); // 0.12% of 1000
    const receivedAmount = ethers.utils.parseUnits("997", 18); // 1000 - 3

    expect(await coin100.balanceOf(addr1.address)).to.equal(receivedAmount);
    expect(await coin100.balanceOf(developerTreasury.address)).to.equal(ethers.utils.parseUnits("100000000", 18).add(developerFee));
    expect(await coin100.balanceOf(liquidityPool.address)).to.equal(ethers.utils.parseUnits("200000000", 18).add(liquidityFee));
    expect(await coin100.balanceOf(communityTreasury.address)).to.equal(ethers.utils.parseUnits("30000000", 18).add(communityFee));
  });

  it("Should allow owner to update fees", async function () {
    // Update transfer fee to 0.5%
    await coin100.updateTransferFee(50); // 0.5%

    // Verify update
    expect(await coin100.transferFee()).to.equal(50);
  });

  it("Should prevent non-owner from updating fees", async function () {
    await expect(
      coin100.connect(addr1).updateTransferFee(50)
    ).to.be.revertedWith("Ownable: caller is not the owner");
  });
});
