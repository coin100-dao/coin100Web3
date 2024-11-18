## **Table of Contents**

1. Introduction  
2. Prerequisites  
3. Setting Up the Development Environment  
   * 3.1. Install Node.js and npm  
   * 3.2. Initialize a New Node.js Project  
   * 3.3. Install Development Dependencies  
   * 3.4. Install Essential Libraries  
4. Creating and Managing Wallets  
   * 4.1. Choose a Wallet Provider  
   * 4.2. Import and Rename Wallets  
   * 4.3. Fund the Wallets on the Testnet  
5. Writing the Solidity Smart Contracts  
   * 5.1. Project Structure Overview  
   * 5.2. Writing the COIN100 Token Contract  
   * 5.3. Writing the COIN100 Developer Treasury Vesting Contract  
   * 5.4. Writing the COIN100 Community Governance Contract  
   * 5.5. Writing the COIN100 Staking Rewards Contract  
6. Configuring Hardhat for Deployment  
   * 6.1. Update `hardhat.config.js`  
   * 6.2. Set Up Environment Variables  
   * 6.3. Install Additional Dependencies  
7. Deploying Contracts to the Amoy Testnet  
   * 7.1. Writing Deployment Scripts  
   * 7.2. Deploying Contracts  
   * 7.3. Verify Deployments  
8. Testing Smart Contracts on the Amoy Testnet  
   * 8.1. Writing Unit Tests  
   * 8.2. Running Unit Tests  
   * 8.3. Manual Testing on Amoy Testnet  
9. Managing and Securing Wallets  
   * 9.1. Securing Private Keys  
   * 9.2. Setting Up Multi-Signature Wallets  
   * 9.3. Monitoring and Maintenance  
10. Finalizing and Preparing for Mainnet Deployment  
    * 10.1. Review and Optimize Contracts  
    * 10.2. Update Configuration for Mainnet  
    * 10.3. Deploy to Polygon Mainnet  
    * 10.4. Post-Deployment Steps  
11. Conclusion

---

## **1\. Introduction**

**COIN100** is a decentralized cryptocurrency index fund built on the Polygon network. It represents the top 100 cryptocurrencies by market capitalization, offering users a diversified portfolio that mirrors the performance of the overall crypto market. Inspired by traditional index funds like the S\&P 500, COIN100 aims to provide a secure, transparent, and efficient investment vehicle for both novice and experienced crypto investors.

**Ultimate Goal:** To dynamically track and reflect the top 100 cryptocurrencies by market capitalization, ensuring that COIN100 remains a relevant and accurate representation of the cryptocurrency market.

---

## **2\. Prerequisites**

Before starting the development process, ensure you have the following:

* **Basic Knowledge of:**  
  * JavaScript/TypeScript  
  * Solidity (Smart Contract Programming)  
  * Blockchain Concepts  
* **Tools Installed:**  
  * **Node.js** (v14.x or later)  
  * **npm** (Node Package Manager)  
  * **MetaMask** (Browser Extension)  
  * **Git** (Version Control)  
* **Accounts:**  
  * **Infura** or another RPC provider account for accessing Polygon's networks  
  * **GitHub** account (optional, for version control and collaboration)

---

## **3\. Setting Up the Development Environment**

### **3.1. Install Node.js and npm**

1. **Download Node.js:**  
   * Visit the [official Node.js website](https://nodejs.org/) and download the LTS (Long Term Support) version suitable for your operating system.  
2. **Install Node.js:**  
   * Follow the installation instructions specific to your OS.  
3. **Verify Installation:**

Open your terminal or command prompt and run:  
bash  
Copy code  
`node -v`

`npm -v`

*   
  * You should see the versions of Node.js and npm installed.

### **3.2. Initialize a New Node.js Project**

**Create a Project Directory:**  
bash  
Copy code  
`mkdir coin100`

`cd coin100`

1.   
2. **Initialize npm:**

This will create a `package.json` file to manage your project's dependencies.  
bash  
Copy code  
`npm init -y`

* 

### **3.3. Install Development Dependencies**

To develop smart contracts, you'll need a development environment and various libraries. We'll use **Hardhat**, a popular Ethereum development environment.

**Install Hardhat:**  
bash  
Copy code  
`npm install --save-dev hardhat`

1. 

**Initialize Hardhat in Your Project:**  
bash  
Copy code  
`npx hardhat`

2.   
   * You'll be prompted with several options. Choose **"Create a basic sample project"** and follow the on-screen instructions.  
   * This will set up a basic project structure with sample contracts, tests, and configuration files.

### **3.4. Install Essential Libraries**

Here are the key libraries you'll need for developing and deploying your smart contracts:

1. **Ethers.js:**

A library for interacting with the Ethereum blockchain.  
bash  
Copy code  
`npm install --save ethers`

*   
2. **Hardhat Plugins:**

**Hardhat Ethers:** Integrates Ethers.js with Hardhat.  
bash  
Copy code  
`npm install --save-dev @nomiclabs/hardhat-ethers ethers`

* 

**Hardhat Waffle:** For smart contract testing.  
bash  
Copy code  
`npm install --save-dev @nomiclabs/hardhat-waffle ethereum-waffle chai`

* 

**Dotenv:** To manage environment variables securely.  
bash  
Copy code  
`npm install --save dotenv`

*   
3. **OpenZeppelin Contracts:**

A library of secure and community-vetted smart contracts.  
bash  
Copy code  
`npm install @openzeppelin/contracts`

*   
4. **Solidity Compiler:**

Ensure compatibility with your smart contracts.  
bash  
Copy code  
`npm install --save-dev solc`

* 

---

## **4\. Creating and Managing Wallets**

Before diving into smart contract development, it's essential to set up and manage the necessary wallets that will control various aspects of the COIN100 ecosystem.

### **4.1. Choose a Wallet Provider**

For development and testing purposes, **MetaMask** is highly recommended due to its user-friendly interface and wide adoption.

* **Download MetaMask:**  
  * Visit the [MetaMask website](https://metamask.io/) and install the extension for your browser.

### **4.2. Import and Rename Wallets**

Since you have specific wallet addresses for each role, you can import them directly into MetaMask if you have their private keys or seed phrases.

**Wallet Addresses for Reference:**

**COIN100 Owner Wallet:**  
Copy code  
`0x8a823C6506eE5aB3d2eD641Ca25838431F3ecA4C`

* 

**COIN100 Developer Treasury Wallet:**  
Copy code  
`0x4f2ee2Cf708F6641d5C7e6aD3128d15d91d15e60`

* 

**COIN100 Liquidity Pool Wallet:**  
Copy code  
`0x799f59a724Cc6a745083cE8A160ba7D13FD471A0`

* 

**COIN100 Marketing Wallet:**  
Copy code  
`0x9Bb4346295797f5d38A1F18FDfe946e372A7be4a`

* 

**COIN100 Staking Rewards Wallet:**  
Copy code  
`0x3D8029660048e7E0a7bD04623802Ab815cc84CF8`

* 

**COIN100 Reserve Wallet:**  
Copy code  
`0xE51edf567dc8162d1EAe53764A864f34deB0DdE9`

* 

**COIN100 Community Treasury Wallet:**  
Copy code  
`0xYourCommunityTreasuryAddress`

* *(Replace `0xYourCommunityTreasuryAddress` with the actual Community Treasury wallet address.)*

**Steps to Import Each Wallet:**

1. **Import Wallet:**  
   * In MetaMask, click on the account icon.  
   * Select **"Import Account"**.  
   * Choose **"Private Key"** or **"JSON File"** based on your available credentials.  
   * Enter the private key or upload the JSON file for the respective wallet.  
2. **Rename the Wallet:**  
   * After importing, rename each account accordingly:  
     * **COIN100 Owner**  
     * **COIN100 Developer Treasury**  
     * **COIN100 Liquidity Pool**  
     * **COIN100 Marketing**  
     * **COIN100 Staking Rewards**  
     * **COIN100 Reserve**  
     * **COIN100 Community Treasury**

### **4.3. Fund the Wallets on the Testnet**

Before deploying contracts, ensure each wallet has sufficient testnet MATIC for gas fees.

1. **Switch to the Amoy Testnet:**  
   * In MetaMask, click on the network dropdown (default is "Ethereum Mainnet").  
   * Select **"Amoy Testnet"**.  
   * **Note:** If Amoy Testnet is not listed, you may need to add it manually by providing the network details.  
2. **Obtain Test MATIC:**  
   * Visit the Amoy Testnet Faucet *(Replace with the actual Amoy Testnet faucet URL)* to request test MATIC.  
   * Enter each wallet address and request funds sequentially:  
     * **COIN100 Owner Wallet:** `0x8a823C6506eE5aB3d2eD641Ca25838431F3ecA4C`  
     * **COIN100 Developer Treasury Wallet:** `0x4f2ee2Cf708F6641d5C7e6aD3128d15d91d15e60`  
     * **COIN100 Liquidity Pool Wallet:** `0x799f59a724Cc6a745083cE8A160ba7D13FD471A0`  
     * **COIN100 Marketing Wallet:** `0x9Bb4346295797f5d38A1F18FDfe946e372A7be4a`  
     * **COIN100 Staking Rewards Wallet:** `0x3D8029660048e7E0a7bD04623802Ab815cc84CF8`  
     * **COIN100 Reserve Wallet:** `0xE51edf567dc8162d1EAe53764A864f34deB0DdE9`  
     * **COIN100 Community Treasury Wallet:** `0xYourCommunityTreasuryAddress` *(Replace `0xYourCommunityTreasuryAddress` with the actual Community Treasury wallet address.)*

---

## **5\. Writing the Solidity Smart Contracts**

With wallets set up, the next step is to write the smart contracts that define the COIN100 token and its associated functionalities. We'll use **Hardhat** as our development environment and **OpenZeppelin** for secure contract templates.

### **5.1. Project Structure Overview**

Your project directory (`coin100/`) should have the following structure after initializing Hardhat:

bash

Copy code

`coin100/`

`├── contracts/`

`│   ├── COIN100Token.sol`

`│   ├── COIN100DeveloperTreasury.sol`

`│   ├── COIN100CommunityGovernance.sol`

`│   └── COIN100StakingRewards.sol`

`├── scripts/`

`│   └── deploy.js`

`├── test/`

`│   └── COIN100Token.test.js`

`├── hardhat.config.js`

`├── package.json`

`└── .env`


## **6\. Configuring Hardhat for Deployment**

Before deploying the contracts, ensure that Hardhat is correctly configured to interact with the **Amoy Testnet**.

### **6.1. Update `hardhat.config.js`**

Open `hardhat.config.js` and update it to include network configurations and necessary plugins.

**hardhat.config.js**

javascript

Copy code

`require("@nomiclabs/hardhat-waffle");`

`require("@nomiclabs/hardhat-ethers");`

`require("dotenv").config();`

`module.exports = {`

  `solidity: "0.8.18",`

  `networks: {`

    `amoy: { // Amoy Testnet configuration`

      `url: process.env.AMOY_RPC_URL,`

      ``accounts: [`0x${process.env.PRIVATE_KEY}`],``

    `},`

  `},`

`};`

**Note:** Replace `"amoy"` with the correct network name if different. Ensure that Amoy Testnet is supported by your RPC provider.

### **6.2. Set Up Environment Variables**

Create a `.env` file in the root directory to store sensitive information.

**.env**

env

Copy code

`AMOY_RPC_URL=https://amoy-testnet.rpc.url # Replace with the actual Amoy Testnet RPC URL`

`PRIVATE_KEY=YOUR_PRIVATE_KEY # Private key of the COIN100 Owner Wallet (0x8a823C6506eE5aB3d2eD641Ca25838431F3ecA4C)`

**Important:**

* **Never share your `.env` file or expose your private key.**  
* Replace `https://amoy-testnet.rpc.url` with the actual RPC URL for the Amoy Testnet provided by your RPC provider.  
* Replace `YOUR_PRIVATE_KEY` with the private key of your **COIN100 Owner Wallet** (`0x8a823C6506eE5aB3d2eD641Ca25838431F3ecA4C`).

### **6.3. Install Additional Dependencies**

Ensure all necessary dependencies are installed.

bash

Copy code

`npm install --save-dev @nomiclabs/hardhat-ethers @nomiclabs/hardhat-waffle ethers dotenv`

`npm install @openzeppelin/contracts`

---

## **7\. Deploying Contracts to the Amoy Testnet**

With contracts written and Hardhat configured, proceed to deploy them to the **Amoy Testnet**.

### **7.1. Writing Deployment Scripts**

Create a deployment script `deploy.js` in the `scripts/` directory.

**deploy.js**

javascript

Copy code

`const hre = require("hardhat");`

`async function main() {`

  `// Deploy COIN100Token`

  `const COIN100Token = await hre.ethers.getContractFactory("COIN100Token");`


  `// Wallet Addresses`

  `const developerTreasury = "0x4f2ee2Cf708F6641d5C7e6aD3128d15d91d15e60"; // COIN100 Developer Treasury`

  `const liquidityPool = "0x799f59a724Cc6a745083cE8A160ba7D13FD471A0"; // COIN100 Liquidity Pool`

  `const marketingWallet = "0x9Bb4346295797f5d38A1F18FDfe946e372A7be4a"; // COIN100 Marketing`

  `const stakingRewards = "0x3D8029660048e7E0a7bD04623802Ab815cc84CF8"; // COIN100 Staking Rewards`

  `const communityTreasury = "0xYourCommunityTreasuryAddress"; // COIN100 Community Treasury`

  `const reserveWallet = "0xE51edf567dc8162d1EAe53764A864f34deB0DdE9"; // COIN100 Reserve Wallet`

  `// Deploy COIN100Token`

  `const coin100 = await COIN100Token.deploy(`

    `developerTreasury,   // COIN100 Developer Treasury`

    `liquidityPool,       // COIN100 Liquidity Pool`

    `marketingWallet,     // COIN100 Marketing`

    `stakingRewards,      // COIN100 Staking Rewards`

    `communityTreasury,   // COIN100 Community Treasury`

    `reserveWallet        // COIN100 Reserve Wallet`

  `);`

  `await coin100.deployed();`

  `console.log("COIN100Token deployed to:", coin100.address);`

  `// Deploy COIN100DeveloperTreasury`

  `const COIN100DeveloperTreasury = await hre.ethers.getContractFactory("COIN100DeveloperTreasury");`

  `const developerTreasuryContract = await COIN100DeveloperTreasury.deploy(`

    `coin100.address,`

    `hre.ethers.utils.parseUnits("100000000", 18) // 100,000,000 COIN100`

  `);`

  `await developerTreasuryContract.deployed();`

  `console.log("COIN100DeveloperTreasury deployed to:", developerTreasuryContract.address);`

  `// Deploy COIN100CommunityGovernance`

  `const COIN100CommunityGovernance = await hre.ethers.getContractFactory("COIN100CommunityGovernance");`

  `const communityGovernance = await COIN100CommunityGovernance.deploy(`

    `coin100.address,`

    `communityTreasury,`

    `100 // Example: 100 required votes`

  `);`

  `await communityGovernance.deployed();`

  `console.log("COIN100CommunityGovernance deployed to:", communityGovernance.address);`

  `// Deploy COIN100StakingRewards`

  `const COIN100StakingRewards = await hre.ethers.getContractFactory("COIN100StakingRewards");`

  `const stakingRewardsContract = await COIN100StakingRewards.deploy(`

    `coin100.address,`

    `coin100.address // Staking COIN100`

  `);`

  `await stakingRewardsContract.deployed();`

  `console.log("COIN100StakingRewards deployed to:", stakingRewardsContract.address);`

`}`

`main()`

  `.then(() => process.exit(0))`

  `.catch((error) => {`

    `console.error("Error deploying contracts:", error);`

    `process.exit(1);`

  `});`

**Explanation:**

* **Wallet Addresses:**  
  1. **COIN100 Owner Wallet:** `0x8a823C6506eE5aB3d2eD641Ca25838431F3ecA4C`  
  2. **COIN100 Developer Treasury Wallet:** `0x4f2ee2Cf708F6641d5C7e6aD3128d15d91d15e60`  
  3. **COIN100 Liquidity Pool Wallet:** `0x799f59a724Cc6a745083cE8A160ba7D13FD471A0`  
  4. **COIN100 Marketing Wallet:** `0x9Bb4346295797f5d38A1F18FDfe946e372A7be4a`  
  5. **COIN100 Staking Rewards Wallet:** `0x3D8029660048e7E0a7bD04623802Ab815cc84CF8`  
  6. **COIN100 Reserve Wallet:** `0xE51edf567dc8162d1EAe53764A864f34deB0DdE9`  
  7. **COIN100 Community Treasury Wallet:** `0xYourCommunityTreasuryAddress` *(Replace with actual address)*  
* **Deployment Steps:**  
  1. **COIN100Token:** Deploys the main token contract with specified allocations.  
  2. **COIN100DeveloperTreasury:** Deploys the vesting contract for the COIN100 Developer Treasury with a total allocation of 100,000,000 COIN100.  
  3. **COIN100CommunityGovernance:** Deploys the governance contract for the COIN100 Community Treasury, requiring 100 votes to execute proposals.  
  4. **COIN100StakingRewards:** Deploys the staking rewards contract, allowing users to stake COIN100 tokens to earn rewards.

### **7.2. Deploying Contracts**

1. **Ensure Testnet MATIC Availability:**  
   * Verify that your **COIN100 Owner Wallet** (`0x8a823C6506eE5aB3d2eD641Ca25838431F3ecA4C`) has sufficient testnet MATIC on the Amoy Testnet for deployment costs.

**Run the Deployment Script:**  
bash  
Copy code  
`npx hardhat run scripts/deploy.js --network amoy`

2.   
3. **Output:**  
   * Upon successful deployment, the console will display the deployed contract addresses.

vbnet  
Copy code  
`COIN100Token deployed to: 0x...`

`COIN100DeveloperTreasury deployed to: 0x...`

`COIN100CommunityGovernance deployed to: 0x...`

`COIN100StakingRewards deployed to: 0x...`

4. 

### **7.3. Verify Deployments**

1. **Check on Amoy Testnet Explorer:**  
   * Visit the Amoy Testnet blockchain explorer *(Replace with the actual Amoy Testnet explorer URL)*.  
   * Enter the deployed contract addresses to view contract details and verify successful deployment.

---

## **8\. Testing Smart Contracts on the Amoy Testnet**

Thorough testing ensures that all functionalities work as intended before deploying to the mainnet.

### **8.1. Writing Unit Tests**

Create a test file `COIN100Token.test.js` in the `test/` directory.

**COIN100Token.test.js**

javascript

Copy code

`const { expect } = require("chai");`

`const { ethers } = require("hardhat");`

`describe("COIN100Token", function () {`

  `let COIN100Token;`

  `let coin100;`

  `let owner;`

  `let addr1;`

  `let addr2;`

  `let developerTreasury;`

  `let liquidityPool;`

  `let marketingWallet;`

  `let stakingRewards;`

  `let communityTreasury;`

  `let reserveWallet;`

  `beforeEach(async function () {`

    `[owner, addr1, addr2, developerTreasury, liquidityPool, marketingWallet, stakingRewards, communityTreasury, reserveWallet] = await ethers.getSigners();`

    `COIN100Token = await ethers.getContractFactory("COIN100Token");`

    `coin100 = await COIN100Token.deploy(`

      `developerTreasury.address, // COIN100 Developer Treasury`

      `liquidityPool.address,     // COIN100 Liquidity Pool`

      `marketingWallet.address,   // COIN100 Marketing`

      `stakingRewards.address,    // COIN100 Staking Rewards`

      `communityTreasury.address,// COIN100 Community Governance`

      `reserveWallet.address      // COIN100 Reserve Wallet`

    `);`

    `await coin100.deployed();`

  `});`

  `it("Should have correct total supply", async function () {`

    `expect(await coin100.totalSupply()).to.equal(ethers.utils.parseUnits("1000000000", 18));`

  `});`

  `it("Should allocate tokens correctly upon deployment", async function () {`

    `const publicSaleAmount = ethers.utils.parseUnits("500000000", 18);`

    `const developerAmount = ethers.utils.parseUnits("100000000", 18);`

    `const liquidityAmount = ethers.utils.parseUnits("200000000", 18);`

    `const marketingAmount = ethers.utils.parseUnits("70000000", 18);`

    `const stakingAmount = ethers.utils.parseUnits("50000000", 18);`

    `const communityAmount = ethers.utils.parseUnits("30000000", 18);`

    `const reserveAmount = ethers.utils.parseUnits("50000000", 18);`

    `expect(await coin100.balanceOf(owner.address)).to.equal(publicSaleAmount);`

    `expect(await coin100.balanceOf(developerTreasury.address)).to.equal(developerAmount);`

    `expect(await coin100.balanceOf(liquidityPool.address)).to.equal(liquidityAmount);`

    `expect(await coin100.balanceOf(marketingWallet.address)).to.equal(marketingAmount);`

    `expect(await coin100.balanceOf(stakingRewards.address)).to.equal(stakingAmount);`

    `expect(await coin100.balanceOf(communityTreasury.address)).to.equal(communityAmount);`

    `expect(await coin100.balanceOf(reserveWallet.address)).to.equal(reserveAmount);`

  `});`

  `it("Should apply transfer fees correctly", async function () {`

    `// Owner transfers 1000 tokens to addr1`

    `await coin100.transfer(addr1.address, ethers.utils.parseUnits("1000", 18));`

    `// Calculate expected fees`

    `const transferFee = ethers.utils.parseUnits("3", 18); // 0.3% of 1000`

    `const developerFee = ethers.utils.parseUnits("0.6", 18); // 0.2% of 1000`

    `const liquidityFee = ethers.utils.parseUnits("0.48", 18); // 0.16% of 1000`

    `const communityFee = ethers.utils.parseUnits("0.36", 18); // 0.12% of 1000`

    `const receivedAmount = ethers.utils.parseUnits("997", 18); // 1000 - 3`

    `expect(await coin100.balanceOf(addr1.address)).to.equal(receivedAmount);`

    `expect(await coin100.balanceOf(developerTreasury.address)).to.equal(ethers.utils.parseUnits("100000000", 18).add(developerFee));`

    `expect(await coin100.balanceOf(liquidityPool.address)).to.equal(ethers.utils.parseUnits("200000000", 18).add(liquidityFee));`

    `expect(await coin100.balanceOf(communityTreasury.address)).to.equal(ethers.utils.parseUnits("30000000", 18).add(communityFee));`

  `});`

  `it("Should allow owner to update fees", async function () {`

    `// Update transfer fee to 0.5%`

    `await coin100.updateTransferFee(50); // 0.5%`

    `// Verify update`

    `expect(await coin100.transferFee()).to.equal(50);`

  `});`

  `it("Should prevent non-owner from updating fees", async function () {`

    `await expect(`

      `coin100.connect(addr1).updateTransferFee(50)`

    `).to.be.revertedWith("Ownable: caller is not the owner");`

  `});`

`});`

**Explanation:**

* **Test Cases:**  
  * **Total Supply:** Verifies that the total supply is correctly set to 1,000,000,000 COIN100.  
  * **Allocation:** Checks that tokens are allocated correctly to each designated wallet upon deployment.  
  * **Transfer Fees:** Ensures that transfer fees are correctly applied and distributed to the respective wallets.  
  * **Fee Management:** Validates that only the owner can update transfer fees and that unauthorized attempts are reverted.

### **8.2. Running Unit Tests**

Execute the tests using Hardhat:

bash

Copy code

`npx hardhat test`

**Expected Output:**

All tests should pass, indicating that the contract behaves as expected.

scss

Copy code

 `COIN100Token`

    `✔ Should have correct total supply (XXX ms)`

    `✔ Should allocate tokens correctly upon deployment (XXX ms)`

    `✔ Should apply transfer fees correctly (XXX ms)`

    `✔ Should allow owner to update fees (XXX ms)`

    `✔ Should prevent non-owner from updating fees (XXX ms)`

  `5 passing (X.Xs)`

### **8.3. Manual Testing on Amoy Testnet**

Beyond automated tests, it's beneficial to perform manual testing to interact with deployed contracts.

#### **8.3.1. Interacting via Hardhat Console**

**Open Hardhat Console:**  
bash  
Copy code  
`npx hardhat console --network amoy`

1. 

**Interact with COIN100Token:**  
javascript  
Copy code  
`const [owner, addr1, addr2] = await ethers.getSigners();`

`const COIN100Token = await ethers.getContractFactory("COIN100Token");`

`const coin100 = await COIN100Token.attach("DEPLOYED_COIN100_ADDRESS"); // Replace with actual COIN100Token address`

`// Check balances`

`const ownerBalance = await coin100.balanceOf(owner.address);`

`console.log("Owner Balance:", ethers.utils.formatUnits(ownerBalance, 18));`

`// Transfer tokens`

`await coin100.transfer(addr1.address, ethers.utils.parseUnits("1000", 18));`

`const addr1Balance = await coin100.balanceOf(addr1.address);`

`console.log("Addr1 Balance:", ethers.utils.formatUnits(addr1Balance, 18));`

2.   
3. **Verify Fee Distribution:**  
   * Check the balances of COIN100 Developer Treasury, Liquidity Pool, and Community Treasury to ensure fees are correctly distributed.

javascript  
Copy code  
`const developerTreasuryBalance = await coin100.balanceOf("0x4f2ee2Cf708F6641d5C7e6aD3128d15d91d15e60"); // COIN100 Developer Treasury`

`const liquidityPoolBalance = await coin100.balanceOf("0x799f59a724Cc6a745083cE8A160ba7D13FD471A0"); // COIN100 Liquidity Pool`

`const communityTreasuryBalance = await coin100.balanceOf("0xYourCommunityTreasuryAddress"); // COIN100 Community Governance`

`console.log("Developer Treasury Balance:", ethers.utils.formatUnits(developerTreasuryBalance, 18));`

`console.log("Liquidity Pool Balance:", ethers.utils.formatUnits(liquidityPoolBalance, 18));`

`console.log("Community Treasury Balance:", ethers.utils.formatUnits(communityTreasuryBalance, 18));`

4. 

#### **8.3.2. Using Amoy Testnet Explorer Interface**

1. **View Transactions:**  
   * Navigate to the contract address on the Amoy Testnet blockchain explorer *(Replace with the actual Amoy Testnet explorer URL)*.  
   * Review transactions to ensure proper functionality.  
2. **Interact with Contracts:**  
   * Use the **"Write Contract"** and **"Read Contract"** tabs to manually invoke and verify contract functions.

---

## **9\. Managing and Securing Wallets**

Proper wallet management is crucial for the security and smooth operation of the COIN100 ecosystem.

### **9.1. Securing Private Keys**

1. **Store Securely:**  
   * Use hardware wallets (e.g., Ledger, Trezor) for storing private keys of critical wallets like COIN100 Developer Treasury and COIN100 Community Governance.  
2. **Backup:**  
   * Ensure that seed phrases are backed up securely and are not stored digitally.  
3. **Access Control:**  
   * Limit access to private keys to essential personnel only.  
   * Consider using multi-signature wallets for high-value accounts.

### **9.2. Setting Up Multi-Signature Wallets**

For enhanced security, especially for Treasury wallets, consider implementing multi-signature (multi-sig) wallets.

1. **Choose a Multi-Sig Solution:**  
   * **Gnosis Safe** is a popular choice on the Polygon network.  
2. **Deploy Multi-Sig Wallet:**  
   * Visit [Gnosis Safe](https://gnosis-safe.io/) and create a new Safe on the Amoy Testnet.  
   * Define the required number of signatures (e.g., 2 out of 3\) for transactions.  
3. **Assign Roles:**  
   * Assign trusted team members as signatories for critical wallets.  
4. **Integrate with Contracts:**  
   * Update the smart contracts to interact with the multi-sig wallets instead of individual addresses.  
   * For example, set the `communityTreasury` address in `COIN100CommunityGovernance` to the multi-sig wallet address.

### **9.3. Monitoring and Maintenance**

1. **Use Wallet Management Tools:**  
   * Tools like **Zerion** or **Debank** can help monitor wallet balances and activities.  
2. **Regular Audits:**  
   * Periodically audit wallets to ensure no unauthorized transactions have occurred.  
3. **Emergency Protocols:**  
   * Establish protocols for recovering funds or pausing contract interactions in case of emergencies.

---

## **10\. Finalizing and Preparing for Mainnet Deployment**

After successful testing on the Amoy Testnet, prepare for deploying to the Polygon Mainnet.

### **10.1. Review and Optimize Contracts**

1. **Code Review:**  
   * Conduct thorough code reviews to identify and fix potential vulnerabilities.  
2. **Optimize Gas Usage:**  
   * Refactor contracts to minimize gas consumption where possible.  
3. **Security Audits:**  
   * Engage reputable third-party auditors to review your smart contracts.

### **10.2. Update Configuration for Mainnet**

**Modify `hardhat.config.js`:**  
javascript  
Copy code  
`module.exports = {`

  `solidity: "0.8.18",`

  `networks: {`

    `polygon: {`

      `url: process.env.POLYGON_RPC_URL,`

      ``accounts: [`0x${process.env.PRIVATE_KEY}`],``

    `},`

    `amoy: {`

      `url: process.env.AMOY_RPC_URL,`

      ``accounts: [`0x${process.env.PRIVATE_KEY}`],``

    `},`

  `},`

`};`

1.   
2. **Set Mainnet RPC URL and Private Key:**  
   * Update the `.env` file with `POLYGON_RPC_URL` and ensure the private key corresponds to a secure mainnet wallet.

**.env**  
env  
Copy code  
`POLYGON_RPC_URL=https://polygon-mainnet.rpc.url # Replace with actual Polygon Mainnet RPC URL`

`AMOY_RPC_URL=https://amoy-testnet.rpc.url # Replace with actual Amoy Testnet RPC URL`

`PRIVATE_KEY=YOUR_PRIVATE_KEY # Private key of the COIN100 Owner Wallet (0x8a823C6506eE5aB3d2eD641Ca25838431F3ecA4C)`

3. 

### **10.3. Deploy to Polygon Mainnet**

1. **Fund Mainnet Wallet:**  
   * Ensure your **COIN100 Owner Wallet** (`0x8a823C6506eE5aB3d2eD641Ca25838431F3ecA4C`) has sufficient MATIC for deployment costs.

**Run Deployment Script:**  
bash  
Copy code  
`npx hardhat run scripts/deploy.js --network polygon`

2.   
3. **Verify Deployment:**  
   * Check the contract addresses on [Polygonscan](https://polygonscan.com/).

### **10.4. Post-Deployment Steps**

1. **Verify Contracts on Polygonscan:**  
   * Use Hardhat's verification plugin or manually verify contracts for transparency.  
2. **Set Up Frontend Interface:**  
   * Develop a user-friendly frontend to interact with the COIN100 ecosystem.  
   * Consider using frameworks like React.js along with libraries like Ethers.js or Web3.js.  
3. **Announce Launch:**  
   * Communicate the mainnet deployment to your community through official channels such as your website, social media, and cryptocurrency forums.

   * 

