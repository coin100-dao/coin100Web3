/* eslint-disable no-undef */
const { ethers } = require("hardhat");

async function main() {
  const [deployer, treasury, buyer] = await ethers.getSigners();
  console.log("Testing with accounts:");
  console.log("- Deployer:", deployer.address);
  console.log("- Treasury:", treasury.address);
  console.log("- Buyer:", buyer.address);

  // 1. Deploy COIN100
  console.log("\nDeploying COIN100...");
  const COIN100 = await ethers.getContractFactory("COIN100");
  const initialMarketCap = ethers.utils.parseUnits("3316185190709", 18);
  const coin100 = await COIN100.deploy(initialMarketCap, treasury.address);
  await coin100.deployed();
  console.log("COIN100 deployed to:", coin100.address);

  // 2. Deploy Mock USDC
  console.log("\nDeploying Mock USDC...");
  const MockERC20 = await ethers.getContractFactory("MockERC20");
  const mockUsdc = await MockERC20.deploy("Mock USDC", "MUSDC", 6);
  await mockUsdc.deployed();
  console.log("Mock USDC deployed to:", mockUsdc.address);

  // 3. Deploy Public Sale
  console.log("\nDeploying Public Sale...");
  const now = Math.floor(Date.now() / 1000);
  const startTime = now + 60;
  const endTime = startTime + (30 * 24 * 60 * 60);
  
  const C100PublicSale = await ethers.getContractFactory("C100PublicSale");
  const publicSale = await C100PublicSale.deploy(
    coin100.address,
    mockUsdc.address,
    ethers.utils.parseUnits("0.001", 18),
    "MUSDC",
    "Mock USDC",
    6,
    treasury.address,
    startTime,
    endTime
  );
  await publicSale.deployed();
  console.log("Public Sale deployed to:", publicSale.address);

  // 4. Setup for testing
  console.log("\nSetting up test scenario...");
  
  // Mint 1000 MUSDC to buyer
  const mintAmount = ethers.utils.parseUnits("1000", 6); // 1000 USDC
  await mockUsdc.mint(buyer.address, mintAmount);
  console.log(`Minted ${ethers.utils.formatUnits(mintAmount, 6)} MUSDC to buyer`);

  // Transfer some C100 to public sale contract
  const saleAllocation = ethers.utils.parseUnits("1000000", 18); // 1M C100
  await coin100.connect(treasury).transfer(publicSale.address, saleAllocation);
  console.log(`Transferred ${ethers.utils.formatUnits(saleAllocation, 18)} C100 to public sale contract`);

  // 5. Test buying tokens
  console.log("\nTesting token purchase...");
  
  // Wait for sale to start
  console.log("Waiting for sale to start...");
  await ethers.provider.send("evm_increaseTime", [65]); // Wait 65 seconds
  await ethers.provider.send("evm_mine");

  // Approve and buy
  const purchaseAmount = ethers.utils.parseUnits("100", 6); // 100 USDC
  await mockUsdc.connect(buyer).approve(publicSale.address, purchaseAmount);
  console.log(`Approved ${ethers.utils.formatUnits(purchaseAmount, 6)} MUSDC for spending`);

  const buyTx = await publicSale.connect(buyer).buyWithToken(mockUsdc.address, purchaseAmount);
  const receipt = await buyTx.wait();
  
  // Find the TokenPurchased event
  const event = receipt.events?.find(e => e.event === 'TokenPurchased');
  if (event) {
    const [buyerAddr, paymentToken, paymentAmount, c100Amount] = event.args;
    console.log("\nPurchase successful!");
    console.log("- Buyer:", buyerAddr);
    console.log("- Payment Token:", paymentToken);
    console.log("- MUSDC Spent:", ethers.utils.formatUnits(paymentAmount, 6));
    console.log("- C100 Received:", ethers.utils.formatUnits(c100Amount, 18));
  }

  // 6. Check final balances
  console.log("\nFinal balances:");
  const buyerC100Balance = await coin100.balanceOf(buyer.address);
  const buyerUsdcBalance = await mockUsdc.balanceOf(buyer.address);
  const treasuryUsdcBalance = await mockUsdc.balanceOf(treasury.address);
  
  console.log(`Buyer C100: ${ethers.utils.formatUnits(buyerC100Balance, 18)}`);
  console.log(`Buyer MUSDC: ${ethers.utils.formatUnits(buyerUsdcBalance, 6)}`);
  console.log(`Treasury MUSDC: ${ethers.utils.formatUnits(treasuryUsdcBalance, 6)}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  }); 