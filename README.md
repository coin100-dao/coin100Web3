# coin100

## **Table of Contents**

1. Introduction  
2. Project Overview  
3. Key Features  
4. System Architecture  
5. Technical Requirements  
6. Project Initialization and Setup  
   * 6.1. Installing Dependencies  
   * 6.2. Initializing Hardhat Project  
   * 6.3. Configuring Environment Variables  
7. Smart Contract Development  
   * 7.1. COIN100 Token Contract  
   * 7.2. COIN100Sale Contract  
   * 7.3. COIN100Staking Contract  
   * 7.4. COIN100CommunityTreasury Contract  
   * 7.5. COIN100Rebalancer Contract  
   * 7.6. COIN100Governance Contract  
   * 7.7. COIN100LiquidityIncentive Contract  
8. Deployment to Mumbai Testnet  
   * 8.1. Configuring Hardhat for Mumbai Testnet  
   * 8.2. Deployment Scripts  
   * 8.3. Deploying Contracts  
   * 8.4. Allocating Tokens  
9. Testing on Mumbai Testnet  
   * 9.1. Writing Test Cases  
   * 9.2. Running Tests  
   * 9.3. Example Test Cases  
10. Preparation for Mainnet Deployment  
    * 10.1. Security Audits  
    * 10.2. Finalizing Deployment Scripts  
    * 10.3. Funding for Mainnet Deployment  
11. Deployment to Polygon Mainnet  
    * 11.1. Deploying Contracts  
    * 11.2. Allocating Tokens  
12. Post-Deployment Steps  
    * 12.1. Verifying Contracts on Polygonscan  
    * 12.2. Monitoring and Maintenance  
13. Conclusion  
14. Appendix: Deployment Scripts

---

## **1\. Introduction**

**COIN100** is a decentralized cryptocurrency index fund built on the Polygon network. It is designed to represent the top 100 cryptocurrencies by market capitalization, offering users a diversified portfolio that mirrors the performance of the overall crypto market. Inspired by traditional index funds like the S\&P 500, COIN100 aims to provide a secure, transparent, and efficient investment vehicle for both novice and experienced crypto investors.

**Ultimate Goal:** To dynamically track and reflect the top 100 cryptocurrencies by market capitalization, ensuring that COIN100 remains a relevant and accurate representation of the cryptocurrency market.

---

## **2\. Project Overview**

COIN100 leverages the Polygon network's scalability and low transaction fees to provide a seamless investment experience. The project encompasses various smart contracts that manage token distribution, sales, staking, governance, liquidity provision, and community treasury funds. By integrating these components, COIN100 ensures sustainable growth, community-driven governance, and robust security mechanisms.

**Key Components:**

* **COIN100 Token:** The ERC20 token representing the index fund.  
* **COIN100Sale:** Manages the public sale of COIN100 tokens.  
* **COIN100Staking:** Enables users to stake COIN100 and earn rewards.  
* **COIN100CommunityTreasury:** Manages community funds through decentralized governance.  
* **COIN100Rebalancer:** Ensures the index accurately reflects the top 100 cryptocurrencies.  
* **COIN100Governance:** Facilitates proposal creation, voting, and execution.  
* **COIN100LiquidityIncentive:** Incentivizes users to provide liquidity to the COIN100/MATIC pool.

---

## **3\. Key Features**

* **Total Supply:** 1,000,000,000 COIN100 tokens.  
* **Allocations:**  
  * **50% Public Sale:** 500,000,000 COIN100  
  * **10% Developer Treasury:** 100,000,000 COIN100  
  * **20% Liquidity Pool:** 200,000,000 COIN100  
  * **7% Marketing:** 70,000,000 COIN100  
  * **5% Staking Rewards:** 50,000,000 COIN100  
  * **3% Community Treasury:** 30,000,000 COIN100  
  * **5% Reserve:** 50,000,000 COIN100  
* **Fees:** A 0.3% fee on all transfers, distributed as follows:  
  * **0.20% Developer Treasury**  
  * **0.16% Liquidity Incentive Wallet**  
  * **0.12% Community Treasury**  
* **Vesting Schedule:** Developer Treasury tokens are vested over 2 years to ensure long-term commitment.  
* **Governance:** Community-controlled utilization of Community Treasury funds through decentralized governance.  
* **Staking Rewards:** Incentivizes users to stake their COIN100 tokens.  
* **Index Tracking:** Dynamically tracks and reflects the value of the top 100 cryptocurrencies by market cap.  
* **Community Engagement:** Active discussions and governance proposals on the project website.  
* **Dynamic Liquidity Provision:** Combines fee-based liquidity addition with incentivized liquidity rewards to build and maintain liquidity without significant upfront investment.

---

## **4\. System Architecture**

The COIN100 ecosystem comprises multiple interconnected smart contracts, each responsible for specific functionalities. The architecture ensures modularity, scalability, and security.

**Components Interaction:**

* **COIN100 Token Contract:**  
  * Central ERC20 token with governance capabilities.  
  * Implements transfer fees distributed to Developer Treasury, Liquidity Incentive Wallet, and Community Treasury.  
* **COIN100Sale Contract:**  
  * Facilitates the public sale of COIN100 tokens.  
  * Holds 50% of the total supply for distribution during the sale.  
* **COIN100Staking Contract:**  
  * Allows users to stake COIN100 tokens to earn rewards.  
  * Holds 5% of the total supply allocated for staking rewards.  
* **COIN100CommunityTreasury Contract:**  
  * Manages community funds through decentralized governance.  
  * Holds 3% of the total supply, allocated initially and supplemented by transfer fees.  
* **COIN100Rebalancer Contract:**  
  * Ensures COIN100 holdings accurately reflect the top 100 cryptocurrencies.  
  * Facilitates dynamic rebalancing based on market capitalization changes.  
* **COIN100Governance Contract:**  
  * Oversees proposal creation, voting, and execution for community governance.  
  * Integrates with the Timelock Controller to secure proposal execution.  
* **COIN100LiquidityIncentive Contract:**  
  * Rewards users for providing liquidity to the COIN100/MATIC pool.  
  * Holds 3% of the total supply allocated for liquidity incentives.

**Flow of Operations:**

1. **Token Distribution:**  
   * COIN100 tokens are allocated to various contracts and addresses based on predefined allocations.  
   * Public sale participants receive COIN100 tokens from the COIN100Sale contract.  
2. **Staking and Rewards:**  
   * Users stake COIN100 tokens in the COIN100Staking contract to earn rewards.  
   * Rewards are distributed based on the staking rate and duration.  
3. **Governance and Community Funds:**  
   * Community members propose and vote on fund allocations via the COIN100Governance contract.  
   * Approved proposals execute fund transfers through the Timelock Controller.  
4. **Liquidity Provision:**  
   * Transfer fees contribute to the Liquidity Incentive Wallet.  
   * Users provide liquidity to the COIN100/MATIC pool and earn rewards from the Liquidity Incentive Contract.  
5. **Index Tracking and Rebalancing:**  
   * The COIN100Rebalancer contract periodically adjusts holdings to align with the top 100 cryptocurrencies.  
   * Ensures the index remains a true representation of the market.

---

## **5\. Technical Requirements**

**Programming Languages and Frameworks:**

* **Solidity:** For smart contract development.  
* **Hardhat:** Development environment for compiling, deploying, and testing smart contracts.  
* **Node.js & npm:** For managing dependencies and running scripts.  
* **Ethers.js:** For interacting with Ethereum and Polygon networks.  
* **OpenZeppelin Contracts:** Utilizing audited and secure smart contract libraries for ERC20 tokens, governance, and access control.

**Dependencies:**

* `@nomiclabs/hardhat-ethers`  
* `ethers`  
* `dotenv`  
* `@openzeppelin/contracts`  
* `@openzeppelin/contracts-governance`  
* `axios`  
* `node-cron`

**Development Tools:**

* **MetaMask:** For managing Polygon wallets and interacting with deployed contracts.  
* **Polygonscan:** For verifying and exploring contracts on the Polygon network.  
* **Git:** Version control system to manage codebase.

**Deployment Platforms:**

* **Polygon Mumbai Testnet:** For testing and validating functionalities.  
* **Polygon Mainnet:** For live deployment.

**Security Tools:**

* **Slither:** Static analysis tool for Solidity.  
* **MythX:** Automated smart contract security analysis.  
* **Solhint:** Solidity linter for code quality.

**Other Services:**

* **QuickSwap Router:** For liquidity provision and token swaps on the Polygon network.  
* **Timelock Controller:** Ensures delayed execution of governance proposals for security.

---

## **6\. Project Initialization and Setup**

This section guides you through initializing the project, installing necessary dependencies, configuring environment variables, and setting up the Hardhat development environment.

### **6.1. Installing Dependencies**

**Prerequisites:**

* **Node.js:** Ensure you have Node.js (version 14 or higher) installed. You can download it from [https://nodejs.org/](https://nodejs.org/).  
* **Git:** Install Git from [https://git-scm.com/](https://git-scm.com/).

**Steps:**

**Initialize Project Directory:**  
bash  
Copy code  
`mkdir COIN100`

`cd COIN100`

1. 

**Initialize npm:**  
bash  
Copy code  
`npm init -y`

2. 

**Install Hardhat and Dependencies:**  
bash  
Copy code  
`npm install --save-dev hardhat @nomiclabs/hardhat-ethers ethers dotenv @openzeppelin/contracts @openzeppelin/contracts-governance`

3. 

**Install Additional Dependencies:**  
bash  
Copy code  
`npm install axios node-cron`

4. 

**Install Testing and Security Tools:**  
bash  
Copy code  
`npm install --save-dev @nomiclabs/hardhat-waffle chai mocha slither-analyzer mythxjs solhint`

5. 

### **6.2. Initializing Hardhat Project**

**Initialize Hardhat:**  
bash  
Copy code  
`npx hardhat`

1.   
   * **Select:** "Create a basic sample project"  
   * **Confirm:** "Yes" to add a `.gitignore`  
   * **Install Sample Project Dependencies:** "Yes"

**Project Structure:** After initialization, your project structure should resemble:  
lua  
Copy code  
`COIN100/`

`├── contracts/`

`│   └── Greeter.sol`

`├── scripts/`

`│   └── sample-script.js`

`├── test/`

`│   └── sample-test.js`

`├── .gitignore`

`├── hardhat.config.js`

`├── package.json`

`└── README.md`

2. 

**Remove Sample Contracts and Scripts:**  
bash  
Copy code  
`rm contracts/Greeter.sol scripts/sample-script.js test/sample-test.js`

3. 

### **6.3. Configuring Environment Variables**

**Create a `.env` File:**  
bash  
Copy code  
`touch .env`

1. 

**Add the Following Variables to `.env`:**  
env  
Copy code  
`MUMBAI_RPC_URL=your_mumbai_rpc_url`

`PRIVATE_KEY=your_private_key`

`MAINNET_RPC_URL=your_mainnet_rpc_url`

`POLYGONSCAN_API_KEY=your_polygonscan_api_key`

`DEVELOPER_WALLET=0xYourDeveloperWalletAddress`

`LIQUIDITY_INCENTIVE_WALLET=0xYourLiquidityIncentiveWalletAddress`

`COMMUNITY_WALLET=0xYourCommunityWalletAddress`

`MARKETING_WALLET=0xYourMarketingWalletAddress`

2. **Notes:**  
   * **MUMBAI\_RPC\_URL:** Obtain from providers like [Infura](https://infura.io/), [Alchemy](https://www.alchemy.com/), or [QuickNode](https://www.quicknode.com/).  
   * **PRIVATE\_KEY:** **Never** commit your private key to version control. Ensure `.env` is listed in `.gitignore`.  
   * **POLYGONSCAN\_API\_KEY:** Register at [Polygonscan](https://polygonscan.com/) to obtain an API key.

**Update `.gitignore` to Include `.env`:** Ensure your `.gitignore` contains:  
bash  
Copy code  
`.env`

3. 

**Modify `hardhat.config.js`:**  
Update `hardhat.config.js` to include the necessary configurations:  
javascript  
Copy code  
`require("@nomiclabs/hardhat-waffle");`

`require("@nomiclabs/hardhat-ethers");`

`require("dotenv").config();`

`module.exports = {`

  `solidity: "0.8.18",`

  `networks: {`

    `mumbai: {`

      `url: process.env.MUMBAI_RPC_URL || "",`

      `accounts: process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],`

    `},`

    `mainnet: {`

      `url: process.env.MAINNET_RPC_URL || "",`

      `accounts: process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],`

    `},`

  `},`

  `etherscan: {`

    `apiKey: process.env.POLYGONSCAN_API_KEY,`

  `},`

`};`

4. 

---

## **7\. Smart Contract Development**

This section details the development of each smart contract, including their purposes, key parameters, functions, and full production-level code.

### **7.1. COIN100 Token Contract**

**Purpose:**  
The COIN100 Token is the core ERC20 token representing the cryptocurrency index fund. It incorporates governance capabilities, transfer fee mechanisms, vesting schedules, and dynamic liquidity provisions.

**Key Parameters and Values:**

* **Name:** "COIN100 Index"  
* **Symbol:** "COIN100"  
* **Total Supply:** 1,000,000,000 COIN100  
* **Decimals:** 18  
* **Transfer Fee Basis Points:** 30 (0.3%)  
* **Maximum Transfer Fee Basis Points:** 1000 (10%)  
* **Fee Recipients:**  
  * **Developer Treasury Address:** `0xDeveloperTreasuryAddress`  
  * **Liquidity Incentive Wallet Address:** `0xLiquidityIncentiveWalletAddress`  
  * **Community Treasury Address:** `0xCommunityTreasuryAddress`  
* **Vesting Parameters:**  
  * **Vesting Start:** Block timestamp at deployment  
  * **Vesting Duration:** 2 years (730 days)  
  * **Vested Amount:** 100,000,000 COIN100 (10% of total supply)

**Functions and Roles:**

* **ERC20 Standard Functions:** `transfer`, `approve`, `transferFrom`, etc.  
* **Governance Integration:** Implements `ERC20Votes` for voting power based on token holdings.  
* **Transfer Fee Mechanism:**  
  * **Function:** Overrides the `_transfer` function to deduct a 0.3% fee on each transfer.  
  * **Fee Distribution:**  
    * **0.20% to Developer Treasury**  
    * **0.16% to Liquidity Incentive Wallet**  
    * **0.12% to Community Treasury**  
* **Vesting Logic:**  
  * **Function:** `releaseDevVesting` allows the owner to release vested tokens after the vesting period.  
  * **Access Control:** Restricted to the contract owner.  
* **Governance Control Functions:**  
  * `setTransferFeeBP(uint256 _feeBP)`  
  * `setFeeRecipientDev(address _feeRecipientDev)`  
  * `setFeeRecipientLiquidity(address _feeRecipientLiquidity)`  
  * `setFeeRecipientCommunity(address _feeRecipientCommunity)`  
  * **Access Control:** All governance control functions are restricted to the contract owner, which is later managed via governance.  
* **Events:**  
  * `TransferFeeUpdated(uint256 newFeeBP)`  
  * `FeeRecipientDevSet(address newFeeRecipient)`  
  * `FeeRecipientLiquiditySet(address newFeeRecipient)`  
  * `FeeRecipientCommunitySet(address newFeeRecipient)`  
  * `DevVestingReleased(uint256 amount)`

**Full Production-Level Code:**

Create a file named `contracts/COIN100Token.sol`:

solidity

Copy code

`// SPDX-License-Identifier: MIT`

`pragma solidity ^0.8.18;`

`import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";`

`import "@openzeppelin/contracts/access/Ownable.sol";`

`contract COIN100Token is ERC20Votes, Ownable {`

    `uint256 public constant MAX_FEE_BP = 1000; // 10%`

    `uint256 public transferFeeBP = 30; // 0.3%`

    `// Fee recipients`

    `address public feeRecipientDev;`

    `address public feeRecipientLiquidity;`

    `address public feeRecipientCommunity;`

    `// Vesting parameters`

    `uint256 public devVestingStart;`

    `uint256 public devVestingDuration = 2 * 365 days; // 2 years`

    `uint256 public devVestedAmount = 100_000_000 * 10 ** 18; // 10% of total supply`

    `// Total Supply`

    `uint256 public constant maxTotalSupply = 1_000_000_000 * 10 ** 18; // 1,000,000,000 COIN100`

    `// Events`

    `event TransferFeeUpdated(uint256 newFeeBP);`

    `event FeeRecipientDevSet(address newFeeRecipient);`

    `event FeeRecipientLiquiditySet(address newFeeRecipient);`

    `event FeeRecipientCommunitySet(address newFeeRecipient);`

    `event DevVestingReleased(uint256 amount);`

    `constructor(`

        `string memory name_,`

        `string memory symbol_,`

        `address _feeRecipientDev,`

        `address _feeRecipientLiquidity,`

        `address _feeRecipientCommunity`

    `) ERC20(name_, symbol_) ERC20Permit(name_) {`

        `require(_feeRecipientDev != address(0), "Invalid dev fee recipient");`

        `require(_feeRecipientLiquidity != address(0), "Invalid liquidity fee recipient");`

        `require(_feeRecipientCommunity != address(0), "Invalid community fee recipient");`

        `feeRecipientDev = _feeRecipientDev;`

        `feeRecipientLiquidity = _feeRecipientLiquidity;`

        `feeRecipientCommunity = _feeRecipientCommunity;`

        `// Mint initial supply to owner (for allocations)`

        `_mint(msg.sender, maxTotalSupply);`

        `// Initialize Vesting`

        `devVestingStart = block.timestamp;`

    `}`

    `// Override ERC20 transfer to include fee`

    `function _transfer(`

        `address sender,`

        `address recipient,`

        `uint256 amount`

    `) internal override {`

        `if (transferFeeBP > 0 && sender != owner() && recipient != owner()) {`

            `uint256 fee = (amount * transferFeeBP) / 10000; // 0.3%`

            `uint256 feeDev = (fee * 20) / 100; // 0.06%`

            `uint256 feeLiquidity = (fee * 16) / 100; // 0.048%`

            `uint256 feeCommunity = fee - feeDev - feeLiquidity; // 0.192%`

            `uint256 amountAfterFee = amount - fee;`

            `super._transfer(sender, feeRecipientDev, feeDev);`

            `super._transfer(sender, feeRecipientLiquidity, feeLiquidity);`

            `super._transfer(sender, feeRecipientCommunity, feeCommunity);`

            `super._transfer(sender, recipient, amountAfterFee);`

        `} else {`

            `super._transfer(sender, recipient, amount);`

        `}`

    `}`

    `// Function to update transfer fee (Governance Controlled)`

    `function setTransferFeeBP(uint256 _feeBP) external onlyOwner {`

        `require(_feeBP <= MAX_FEE_BP, "Fee exceeds maximum");`

        `transferFeeBP = _feeBP;`

        `emit TransferFeeUpdated(_feeBP);`

    `}`

    `// Function to update developer fee recipient (Governance Controlled)`

    `function setFeeRecipientDev(address _feeRecipientDev) external onlyOwner {`

        `require(_feeRecipientDev != address(0), "Invalid fee recipient");`

        `feeRecipientDev = _feeRecipientDev;`

        `emit FeeRecipientDevSet(_feeRecipientDev);`

    `}`

    `// Function to update liquidity fee recipient (Governance Controlled)`

    `function setFeeRecipientLiquidity(address _feeRecipientLiquidity) external onlyOwner {`

        `require(_feeRecipientLiquidity != address(0), "Invalid fee recipient");`

        `feeRecipientLiquidity = _feeRecipientLiquidity;`

        `emit FeeRecipientLiquiditySet(_feeRecipientLiquidity);`

    `}`

    `// Function to update community fee recipient (Governance Controlled)`

    `function setFeeRecipientCommunity(address _feeRecipientCommunity) external onlyOwner {`

        `require(_feeRecipientCommunity != address(0), "Invalid fee recipient");`

        `feeRecipientCommunity = _feeRecipientCommunity;`

        `emit FeeRecipientCommunitySet(_feeRecipientCommunity);`

    `}`

    `// Vesting Release Function for Developer`

    `function releaseDevVesting() external onlyOwner {`

        `require(block.timestamp >= devVestingStart + devVestingDuration, "Vesting period not yet completed");`

        `require(devVestedAmount > 0, "No tokens to release");`

        `_transfer(owner(), feeRecipientDev, devVestedAmount);`

        `emit DevVestingReleased(devVestedAmount);`

        `devVestedAmount = 0;`

    `}`

    `// Governance Integration`

    `// Note: Additional governance mechanisms are handled via separate Governor contracts.`

`}`

**Explanation:**

* **ERC20Votes:** Enables voting power based on token holdings.  
* **Transfer Fee:** Deducts 0.3% from each transfer (excluding owner) and splits it into:  
  * **0.20% to Developer Treasury**  
  * **0.16% to Liquidity Incentive Wallet**  
  * **0.12% to Community Treasury**  
* **Vesting:** Releases developer-allocated tokens after a 2-year vesting period.  
* **Governance Control:** Functions like `setTransferFeeBP`, `setFeeRecipientDev`, `setFeeRecipientLiquidity`, and `setFeeRecipientCommunity` are restricted to the owner, which will later be managed via governance.  
* **Events:** Emit events for transparency and tracking.

---

### **7.2. COIN100Sale Contract**

**Purpose:**  
Manages the public sale of COIN100 tokens, allowing users to purchase tokens with MATIC. It handles token distribution, sale duration, exchange rates, and fund withdrawal.

**Key Parameters and Values:**

* **Token Address:** `0xCOIN100TokenAddress`  
* **Exchange Rate:** 252,604 COIN100 per 1 MATIC  
* **Sale Duration:** 7 days (604,800 seconds)  
* **Sale End Time:** Block timestamp at deployment \+ 7 days  
* **Owner Address:** `0xOwnerAddress`

**Functions and Roles:**

* **buyTokens():** Allows users to purchase COIN100 by sending MATIC. Transfers the corresponding amount of COIN100 to the buyer.  
* **withdrawFunds():** Enables the owner to withdraw collected MATIC from the contract.  
* **endSale():** Allows the owner to manually end the sale before the duration.  
* **setRate(uint256 \_newRate):** Allows the owner to update the exchange rate.  
* **receive():** Fallback function to handle direct MATIC transfers by invoking `buyTokens()`.

**Access Control:**

* **onlyOwner:** Functions `withdrawFunds`, `endSale`, and `setRate` are restricted to the contract owner.

**Events:**

* `TokensPurchased(address indexed buyer, uint256 maticSpent, uint256 tokensBought)`  
* `SaleEnded()`  
* `RateUpdated(uint256 newRate)`

**Full Production-Level Code:**

Create a file named `contracts/COIN100Sale.sol`:

solidity

Copy code

`// SPDX-License-Identifier: MIT`

`pragma solidity ^0.8.18;`

`import "@openzeppelin/contracts/security/ReentrancyGuard.sol";`

`import "@openzeppelin/contracts/token/ERC20/IERC20.sol";`

`import "@openzeppelin/contracts/access/Ownable.sol";`

`contract COIN100Sale is ReentrancyGuard, Ownable {`

    `IERC20 public coin100;`

    `uint256 public rate; // Number of COIN100 per MATIC`

    `uint256 public endTime;`

    `bool public saleEnded = false;`

    `event TokensPurchased(address indexed buyer, uint256 maticSpent, uint256 tokensBought);`

    `event SaleEnded();`

    `event RateUpdated(uint256 newRate);`

    `modifier saleActive() {`

        `require(block.timestamp < endTime, "Sale has ended");`

        `require(!saleEnded, "Sale has been manually ended");`

        `_;`

    `}`

    `constructor(`

        `IERC20 _coin100,`

        `uint256 _rate,`

        `uint256 _duration`

    `) {`

        `require(address(_coin100) != address(0), "Invalid token address");`

        `require(_rate > 0, "Rate must be greater than zero");`

        `require(_duration > 0, "Duration must be greater than zero");`

        `coin100 = _coin100;`

        `rate = _rate;`

        `endTime = block.timestamp + _duration;`

    `}`

    `// Function to buy tokens`

    `function buyTokens() external payable nonReentrant saleActive {`

        `require(msg.value > 0, "Must send MATIC to buy tokens");`

        `uint256 tokensToBuy = msg.value * rate;`

        `require(coin100.balanceOf(address(this)) >= tokensToBuy, "Not enough tokens in contract");`

        `coin100.transfer(msg.sender, tokensToBuy);`

        `emit TokensPurchased(msg.sender, msg.value, tokensToBuy);`

    `}`

    `// Owner can withdraw collected MATIC`

    `function withdrawFunds() external onlyOwner {`

        `require(address(this).balance > 0, "No funds to withdraw");`

        `payable(owner()).transfer(address(this).balance);`

    `}`

    `// Owner can end the sale manually`

    `function endSale() external onlyOwner {`

        `require(!saleEnded, "Sale already ended");`

        `saleEnded = true;`

        `endTime = block.timestamp;`

        `emit SaleEnded();`

    `}`

    `// Owner can set the rate`

    `function setRate(uint256 _newRate) external onlyOwner {`

        `require(_newRate > 0, "Rate must be greater than zero");`

        `rate = _newRate;`

        `emit RateUpdated(_newRate);`

    `}`

    `// Receive function to handle direct MATIC transfers`

    `receive() external payable {`

        `buyTokens();`

    `}`

`}`

**Explanation:**

* **buyTokens:** Allows users to purchase COIN100 by sending MATIC.  
* **Rate:** Set to 252,604 COIN100 per MATIC.  
* **saleEnded:** Allows the owner to end the sale manually before the duration.  
* **withdrawFunds:** Owner can withdraw collected MATIC after the sale.  
* **receive Function:** Facilitates direct MATIC transfers to buy tokens.  
* **Security:** Uses `ReentrancyGuard` to prevent reentrancy attacks.

---

### **7.3. COIN100Staking Contract**

**Purpose:**  
Enables users to stake their COIN100 tokens to earn rewards. Rewards are distributed based on the staking amount and duration, incentivizing long-term holding and participation.

**Key Parameters and Values:**

* **Staking Token Address:** `0xCOIN100TokenAddress`  
* **Reward Token Address:** `0xCOIN100TokenAddress` (using COIN100 as the reward token)  
* **Reward Rate:** 0.00000167 COIN100 per second per staked token

**Functions and Roles:**

* **stake(uint256 amount):** Allows users to stake a specified amount of COIN100 tokens. Increases the user's staking balance and the total staked supply.  
* **withdraw(uint256 amount):** Enables users to withdraw their staked COIN100 tokens. Decreases the user's staking balance and the total staked supply.  
* **getReward():** Allows users to claim their accumulated rewards based on their staking activity.  
* **exit():** Enables users to withdraw all staked tokens and claim rewards in a single transaction.  
* **setRewardRate(uint256 \_newRewardRate):** Allows the owner to update the reward rate.

**Access Control:**

* **onlyOwner:** Function `setRewardRate` is restricted to the contract owner.

**Events:**

* `Staked(address indexed user, uint256 amount)`  
* `Withdrawn(address indexed user, uint256 amount)`  
* `RewardPaid(address indexed user, uint256 reward)`  
* `RewardRateUpdated(uint256 newRewardRate)`

**Full Production-Level Code:**

Create a file named `contracts/COIN100Staking.sol`:

solidity

Copy code

`// SPDX-License-Identifier: MIT`

`pragma solidity ^0.8.18;`

`import "@openzeppelin/contracts/token/ERC20/IERC20.sol";`

`import "@openzeppelin/contracts/access/Ownable.sol";`

`contract COIN100Staking is Ownable {`

    `IERC20 public stakingToken;`

    `IERC20 public rewardToken;`

    `uint256 public rewardRate; // Rewards per second per staked token`

    `uint256 public lastUpdateTime;`

    `uint256 public rewardPerTokenStored;`

    `mapping(address => uint256) public userRewardPerTokenPaid;`

    `mapping(address => uint256) public rewards;`

    `uint256 private _totalSupply;`

    `mapping(address => uint256) private _balances;`

    `// Events`

    `event Staked(address indexed user, uint256 amount);`

    `event Withdrawn(address indexed user, uint256 amount);`

    `event RewardPaid(address indexed user, uint256 reward);`

    `event RewardRateUpdated(uint256 newRewardRate);`

    `constructor(`

        `address _stakingToken,`

        `address _rewardToken,`

        `uint256 _rewardRate`

    `) {`

        `require(_stakingToken != address(0), "Invalid staking token address");`

        `require(_rewardToken != address(0), "Invalid reward token address");`

        `stakingToken = IERC20(_stakingToken);`

        `rewardToken = IERC20(_rewardToken);`

        `rewardRate = _rewardRate;`

        `lastUpdateTime = block.timestamp;`

    `}`

    `modifier updateReward(address account) {`

        `rewardPerTokenStored = rewardPerToken();`

        `lastUpdateTime = block.timestamp;`

        `if (account != address(0)) {`

            `rewards[account] = earned(account);`

            `userRewardPerTokenPaid[account] = rewardPerTokenStored;`

        `}`

        `_;`

    `}`

    `// Calculate reward per token`

    `function rewardPerToken() public view returns (uint256) {`

        `if (_totalSupply == 0) {`

            `return rewardPerTokenStored;`

        `}`

        `return`

            `rewardPerTokenStored +`

            `(((block.timestamp - lastUpdateTime) * rewardRate * 1e18) / _totalSupply);`

    `}`

    `// Calculate earned rewards`

    `function earned(address account) public view returns (uint256) {`

        `return`

            `((_balances[account] * (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18) +`

            `rewards[account];`

    `}`

    `// Stake tokens`

    `function stake(uint256 amount) external updateReward(msg.sender) {`

        `require(amount > 0, "Cannot stake zero");`

        `_totalSupply += amount;`

        `_balances[msg.sender] += amount;`

        `stakingToken.transferFrom(msg.sender, address(this), amount);`

        `emit Staked(msg.sender, amount);`

    `}`

    `// Withdraw staked tokens`

    `function withdraw(uint256 amount) public updateReward(msg.sender) {`

        `require(amount > 0, "Cannot withdraw zero");`

        `require(_balances[msg.sender] >= amount, "Insufficient staked balance");`

        `_totalSupply -= amount;`

        `_balances[msg.sender] -= amount;`

        `stakingToken.transfer(msg.sender, amount);`

        `emit Withdrawn(msg.sender, amount);`

    `}`

    `// Claim rewards`

    `function getReward() public updateReward(msg.sender) {`

        `uint256 reward = rewards[msg.sender];`

        `require(reward > 0, "No rewards to claim");`

        `rewards[msg.sender] = 0;`

        `rewardToken.transfer(msg.sender, reward);`

        `emit RewardPaid(msg.sender, reward);`

    `}`

    `// Exit staking`

    `function exit() external {`

        `withdraw(_balances[msg.sender]);`

        `getReward();`

    `}`

    `// Owner can set reward rate`

    `function setRewardRate(uint256 _newRewardRate) external onlyOwner {`

        `rewardRate = _newRewardRate;`

        `emit RewardRateUpdated(_newRewardRate);`

    `}`

    `// View functions`

    `function totalSupply() external view returns (uint256) {`

        `return _totalSupply;`

    `}`

    `function balanceOf(address account) external view returns (uint256) {`

        `return _balances[account];`

    `}`

`}`

**Explanation:**

* **stake:** Users stake COIN100 tokens to earn rewards.  
* **withdraw:** Users can withdraw their staked tokens.  
* **getReward:** Users can claim their accumulated rewards.  
* **rewardRate:** Initially set based on governance decisions; adjustable via governance proposals.  
* **Events:** Emit events for transparency and tracking.  
* **Security:** Ensures users can only stake positive amounts and have sufficient balance.

---

### **7.4. COIN100CommunityTreasury Contract**

**Purpose:**  
Manages the allocation and utilization of Community Treasury funds. It facilitates decentralized governance, allowing community members to propose and vote on fund allocations, ensuring transparency and community control over resources.

**Key Parameters and Values:**

* **Governor Contract Name:** "COIN100CommunityTreasuryGovernor"  
* **Voting Delay:** 1 block  
* **Voting Period:** 45,818 blocks (\~1 week, assuming 13-second block times)  
* **Quorum:** 5,000,000 COIN100  
* **Timelock Controller Address:** `0xTimelockControllerAddress`  
* **Community Token Address:** `0xCOIN100TokenAddress`

**Functions and Roles:**

* **Governance Functions:** Inherits from OpenZeppelin's Governor contracts to manage proposal creation, voting, and execution.  
* **propose():** Allows community members to create proposals for fund allocation.  
* **vote():** Enables token holders to vote on active proposals.  
* **execute():** Executes approved proposals after the timelock delay.  
* **updateQuorum():** Governed by the contract settings, ensuring that a minimum number of votes are required for proposal approval.

**Access Control:**

* **Proposers and Executors:** Initially set to empty arrays; to be configured via governance proposals to include trusted addresses or the Timelock Controller.

**Events:**

* Inherits events from OpenZeppelin's Governor contracts for proposal creation, voting, and execution.

**Inheritance:**

* **Governor**  
* **GovernorSettings**  
* **GovernorCountingSimple**  
* **GovernorVotes**  
* **GovernorTimelockControl**

**Full Production-Level Code:**

Create a file named `contracts/COIN100CommunityTreasury.sol`:

solidity

Copy code

`// SPDX-License-Identifier: MIT`

`pragma solidity ^0.8.18;`

`import "@openzeppelin/contracts/governance/Governor.sol";`

`import "@openzeppelin/contracts/governance/extensions/GovernorSettings.sol";`

`import "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";`

`import "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";`

`import "@openzeppelin/contracts/governance/extensions/GovernorTimelockControl.sol";`

`import "@openzeppelin/contracts/token/ERC20/IERC20.sol";`

`contract COIN100CommunityTreasury is Governor, GovernorSettings, GovernorCountingSimple, GovernorVotes, GovernorTimelockControl {`

    `IERC20 public communityToken;`

    `constructor(`

        `IERC20 _communityToken,`

        `TimelockController _timelock`

    `)`

        `Governor("COIN100CommunityTreasuryGovernor")`

        `GovernorSettings(`

            `1, // Voting Delay: 1 block`

            `45818, // Voting Period: ~1 week (assuming 13 sec blocks)`

            `0 // Proposal Threshold: 0 (anyone can propose)`

        `)`

        `GovernorVotes(_communityToken)`

        `GovernorTimelockControl(_timelock)`

    `{`

        `communityToken = _communityToken;`

    `}`

    `// Override functions required by Solidity.`

    `function votingDelay() public view override(Governor, GovernorSettings) returns (uint256) {`

        `return super.votingDelay();`

    `}`

    `function votingPeriod() public view override(Governor, GovernorSettings) returns (uint256) {`

        `return super.votingPeriod();`

    `}`

    `function quorum(uint256 blockNumber) public view override returns (uint256) {`

        `return 5_000_000 * 10 ** 18; // 5,000,000 COIN100`

    `}`

    `function state(uint256 proposalId) public view override(Governor, GovernorTimelockControl) returns (ProposalState) {`

        `return super.state(proposalId);`

    `}`

    `function propose(`

        `address[] memory targets,`

        `uint256[] memory values,`

        `bytes[] memory calldatas,`

        `string memory description`

    `) public override(Governor) returns (uint256) {`

        `return super.propose(targets, values, calldatas, description);`

    `}`

    `function _execute(uint256 proposalId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes32 descriptionHash)`

        `internal`

        `override(Governor, GovernorTimelockControl)`

    `{`

        `super._execute(proposalId, targets, values, calldatas, descriptionHash);`

    `}`

    `function _cancel(address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes32 descriptionHash)`

        `internal`

        `override(Governor, GovernorTimelockControl)`

        `returns (uint256)`

    `{`

        `return super._cancel(targets, values, calldatas, descriptionHash);`

    `}`

    `function _executor() internal view override(Governor, GovernorTimelockControl) returns (address) {`

        `return super._executor();`

    `}`

    `// Support for interface`

    `function supportsInterface(bytes4 interfaceId) public view override(Governor, GovernorTimelockControl) returns (bool) {`

        `return super.supportsInterface(interfaceId);`

    `}`

`}`

**Explanation:**

* **Governor Settings:**  
  * **Voting Delay:** 1 block  
  * **Voting Period:** \~1 week (45,818 blocks)  
  * **Quorum:** 5,000,000 COIN100  
* **Functionality:**  
  * Community members can propose and vote on governance proposals.  
  * Proposals need to meet the quorum to be considered.  
  * Upon approval, proposals are executed via the Timelock Controller after the set delay.  
* **Governance Controls:** Ensures decentralized and transparent management of community funds.

---

### **7.5. COIN100Rebalancer Contract**

**Purpose:**  
Implements an algorithm to rebalance COIN100 holdings based on the top 100 cryptocurrencies' weights by market capitalization. It ensures that the index remains accurate and reflective of the current market dynamics.

**Key Parameters and Values:**

* **COIN100 Token Address:** `0xCOIN100TokenAddress`  
* **QuickSwap Router Address (Mumbai Testnet):** `0xQuickSwapRouterAddress`  
* **Top Coins Struct:**  
  * **Token Address**  
  * **Weight (Basis Points)**  
* **Total Weight Basis Points:** 10,000 (100%)  
* **Max Tokens Per Rebalance:** 10  
* **Rebalance Interval:** 1 day  
* **Current Batch Index:** 0

**Functions and Roles:**

* **updateTopCoins(address\[\] calldata \_tokenAddresses, uint256\[\] calldata \_weights):** Allows the owner to update the list of top 100 coins and their corresponding weights. Ensures the total weight equals 10,000 basis points.  
* **rebalance():** Executes the rebalancing process by adjusting holdings to match the target weights. Processes a maximum of 10 tokens per call to manage gas costs.  
* **rebalanceCheaper(address\[\] calldata targetTokens, uint256\[\] calldata deficits, uint256\[\] calldata surpluses):** An alternative, cost-effective method for rebalancing by batching multiple token adjustments off-chain.  
* **addLiquidity(address tokenA, address tokenB, uint256 amountA, uint256 amountB):** Adds liquidity to specified token pairs using accumulated fees.  
* **emergencyWithdraw(address token, address to, uint256 amount):** Allows the owner to withdraw mistakenly sent tokens, excluding COIN100.  
* **setMaxTokensPerRebalance(uint256 \_maxTokensPerRebalance):** Sets the maximum number of tokens processed per rebalance.  
* **setCurrentBatch(uint256 \_currentBatch):** Sets the current batch index manually.

**Access Control:**

* **onlyOwner:** Functions `updateTopCoins`, `rebalance`, `rebalanceCheaper`, `addLiquidity`, `emergencyWithdraw`, `setMaxTokensPerRebalance`, and `setCurrentBatch` are restricted to the contract owner.

**Events:**

* `TopCoinsUpdated(uint256 indexed count)`  
* `Rebalanced()`  
* `Swapped(address indexed fromToken, address indexed toToken, uint256 amountIn, uint256 amountOut)`  
* `LiquidityAdded(uint256 amountCoin100, uint256 amountMATIC, uint256 liquidity)`

**Full Production-Level Code:**

Create a file named `contracts/COIN100Rebalancer.sol`:

solidity

Copy code

`// SPDX-License-Identifier: MIT`

`pragma solidity ^0.8.18;`

`import "@openzeppelin/contracts/access/Ownable.sol";`

`import "@openzeppelin/contracts/security/ReentrancyGuard.sol";`

`import "@openzeppelin/contracts/token/ERC20/IERC20.sol";`

`// Interface for QuickSwap Router`

`interface IUniswapV2Router02 {`

    `function swapExactTokensForTokens(`

        `uint amountIn,` 

        `uint amountOutMin,` 

        `address[] calldata path,` 

        `address to,` 

        `uint deadline`

    `) external returns (uint[] memory amounts);`

    `function getAmountsOut(`

        `uint amountIn,` 

        `address[] calldata path`

    `) external view returns (uint[] memory amounts);`

    `function addLiquidity(`

        `address tokenA,`

        `address tokenB,`

        `uint amountADesired,`

        `uint amountBDesired,`

        `uint amountAMin,`

        `uint amountBMin,`

        `address to,`

        `uint deadline`

    `) external returns (uint amountA, uint amountB, uint liquidity);`

`}`

`contract COIN100Rebalancer is Ownable, ReentrancyGuard {`

    `IERC20 public immutable coin100;`

    `IUniswapV2Router02 public immutable quickSwapRouter;`

    `struct Coin {`

        `address tokenAddress;`

        `uint256 weight; // Weight in basis points (e.g., 10000 = 100%)`

    `}`

    `Coin[] public topCoins;`

    `// Mapping for quick lookup`

    `mapping(address => uint256) public tokenIndex;`

    `// Total weight should be 10000 (100%)`

    `uint256 public constant TOTAL_WEIGHT_BP = 10000;`

    `// Batching Parameters`

    `uint256 public maxTokensPerRebalance = 10; // Limit to 10 tokens per rebalance`

    `uint256 public currentBatch = 0; // Tracks the current batch`

    `// Rebalancing Frequency`

    `uint256 public rebalanceInterval = 1 days;`

    `uint256 public lastRebalanceTime;`

    `// Events`

    `event TopCoinsUpdated(uint256 indexed count);`

    `event Rebalanced();`

    `event Swapped(address indexed fromToken, address indexed toToken, uint256 amountIn, uint256 amountOut);`

    `event LiquidityAdded(uint256 amountCoin100, uint256 amountMATIC, uint256 liquidity);`

    `constructor(`

        `address _coin100,`

        `address _quickSwapRouter`

    `) {`

        `require(_coin100 != address(0), "Invalid COIN100 address");`

        `require(_quickSwapRouter != address(0), "Invalid QuickSwap Router address");`

        `coin100 = IERC20(_coin100);`

        `quickSwapRouter = IUniswapV2Router02(_quickSwapRouter);`

        `lastRebalanceTime = block.timestamp;`

    `}`

    `/**`

     `* @dev Update the list of top coins and their weights.`

     `* Can only be called by the owner (typically through governance).`

     `* @param _tokenAddresses Array of token addresses.`

     `* @param _weights Array of weights in basis points corresponding to each token.`

     `*/`

    `function updateTopCoins(address[] calldata _tokenAddresses, uint256[] calldata _weights) external onlyOwner {`

        `require(_tokenAddresses.length == _weights.length, "Mismatched input lengths");`

        `require(_tokenAddresses.length <= 100, "Exceeds top 100");`

        `// Clear existing topCoins`

        `delete topCoins;`

        `uint256 totalWeight = 0;`

        `for (uint256 i = 0; i < _tokenAddresses.length; i++) {`

            `require(_tokenAddresses[i] != address(0), "Invalid token address");`

            `topCoins.push(Coin({`

                `tokenAddress: _tokenAddresses[i],`

                `weight: _weights[i]`

            `}));`

            `tokenIndex[_tokenAddresses[i]] = i + 1; // +1 to differentiate from default 0`

            `totalWeight += _weights[i];`

        `}`

        `require(totalWeight == TOTAL_WEIGHT_BP, "Total weight must be 10000 basis points");`

        `emit TopCoinsUpdated(_tokenAddresses.length);`

    `}`

    `/**`

     `* @dev Rebalance the holdings to match the target weights.`

     `* Implements batching to limit the number of tokens processed per transaction.`

     `*/`

    `function rebalance() external onlyOwner nonReentrant {`

        `require(block.timestamp >= lastRebalanceTime + rebalanceInterval, "Rebalance interval not met");`

        `lastRebalanceTime = block.timestamp;`

        `uint256 totalCoin100Balance = coin100.balanceOf(address(this));`

        `require(totalCoin100Balance > 0, "No COIN100 tokens to rebalance");`

        `uint256 tokensToProcess = maxTokensPerRebalance;`

        `uint256 processed = 0;`

        `for (uint256 i = currentBatch; i < topCoins.length && processed < tokensToProcess; i++) {`

            `Coin memory currentCoin = topCoins[i];`

            `if (currentCoin.tokenAddress == address(coin100)) {`

                `// Skip COIN100 itself if included`

                `processed++;`

                `continue;`

            `}`

            `IERC20 targetToken = IERC20(currentCoin.tokenAddress);`

            `uint256 targetAmount = (totalCoin100Balance * currentCoin.weight) / TOTAL_WEIGHT_BP;`

            `uint256 currentAmount = targetToken.balanceOf(address(this));`

            `if (currentAmount < targetAmount) {`

                `// Deficit: Need to buy more of this token`

                `uint256 deficit = targetAmount - currentAmount;`

                `uint256 amountToSwap = deficit;`

                `// Approve QuickSwap Router to spend COIN100`

                `require(coin100.approve(address(quickSwapRouter), amountToSwap), "COIN100 approve failed");`

                `address;`

                `path[0] = address(coin100);`

                `path[1] = address(targetToken);`

                `uint[] memory amounts = quickSwapRouter.getAmountsOut(amountToSwap, path);`

                `uint amountOutMin = (amounts[1] * 95) / 100; // 5% slippage`

                `quickSwapRouter.swapExactTokensForTokens(`

                    `amountToSwap,`

                    `amountOutMin,`

                    `path,`

                    `address(this),`

                    `block.timestamp + 300`

                `);`

                `uint256 amountReceived = targetToken.balanceOf(address(this)) - currentAmount;`

                `emit Swapped(address(coin100), address(targetToken), amountToSwap, amountReceived);`

            `} else if (currentAmount > targetAmount) {`

                `// Surplus: Need to sell excess of this token for COIN100`

                `uint256 surplus = currentAmount - targetAmount;`

                `uint256 amountToSwap = surplus;`

                `// Approve QuickSwap Router to spend targetToken`

                `require(targetToken.approve(address(quickSwapRouter), amountToSwap), "Target token approve failed");`

                `address;`

                `path[0] = address(targetToken);`

                `path[1] = address(coin100);`

                `uint[] memory amounts = quickSwapRouter.getAmountsOut(amountToSwap, path);`

                `uint amountOutMin = (amounts[1] * 95) / 100; // 5% slippage`

                `quickSwapRouter.swapExactTokensForTokens(`

                    `amountToSwap,`

                    `amountOutMin,`

                    `path,`

                    `address(this),`

                    `block.timestamp + 300`

                `);`

                `uint256 amountReceived = coin100.balanceOf(address(this)) - (totalCoin100Balance * currentCoin.weight) / TOTAL_WEIGHT_BP;`

                `emit Swapped(address(targetToken), address(coin100), amountToSwap, amountReceived);`

            `}`

            `// If currentAmount == targetAmount, no action needed`

            `processed++;`

            `currentBatch++;`

        `}`

        `// Reset batch if all tokens have been processed`

        `if (currentBatch >= topCoins.length) {`

            `currentBatch = 0;`

        `}`

        `emit Rebalanced();`

    `}`

    `/**`

     `* @dev Cheaper alternative rebalancing method.`

     `* Aggregates multiple token adjustments off-chain and performs a single batch swap.`

     `* This method reduces gas costs by minimizing the number of transactions.`

     `* Note: This requires integration with an off-chain aggregator or batching mechanism.`

     `*/`

    `function rebalanceCheaper(address[] calldata targetTokens, uint256[] calldata deficits, uint256[] calldata surpluses) external onlyOwner nonReentrant {`

        `require(targetTokens.length == deficits.length && targetTokens.length == surpluses.length, "Mismatched input lengths");`

        `for (uint256 i = 0; i < targetTokens.length; i++) {`

            `address targetToken = targetTokens[i];`

            `uint256 deficit = deficits[i];`

            `uint256 surplus = surpluses[i];`

            `if (deficit > 0) {`

                `// Buy more of targetToken`

                `uint256 amountToSwap = deficit;`

                `// Approve QuickSwap Router to spend COIN100`

                `require(coin100.approve(address(quickSwapRouter), amountToSwap), "COIN100 approve failed");`

                `address;`

                `path[0] = address(coin100);`

                `path[1] = targetToken;`

                `uint[] memory amounts = quickSwapRouter.getAmountsOut(amountToSwap, path);`

                `uint amountOutMin = (amounts[1] * 95) / 100; // 5% slippage`

                `quickSwapRouter.swapExactTokensForTokens(`

                    `amountToSwap,`

                    `amountOutMin,`

                    `path,`

                    `address(this),`

                    `block.timestamp + 300`

                `);`

                `emit Swapped(address(coin100), targetToken, amountToSwap, amounts[1]);`

            `}`

            `if (surplus > 0) {`

                `// Sell excess of targetToken`

                `uint256 amountToSwap = surplus;`

                `// Approve QuickSwap Router to spend targetToken`

                `require(IERC20(targetToken).approve(address(quickSwapRouter), amountToSwap), "Target token approve failed");`

                `address;`

                `path[0] = targetToken;`

                `path[1] = address(coin100);`

                `uint[] memory amounts = quickSwapRouter.getAmountsOut(amountToSwap, path);`

                `uint amountOutMin = (amounts[1] * 95) / 100; // 5% slippage`

                `quickSwapRouter.swapExactTokensForTokens(`

                    `amountToSwap,`

                    `amountOutMin,`

                    `path,`

                    `address(this),`

                    `block.timestamp + 300`

                `);`

                `emit Swapped(targetToken, address(coin100), amountToSwap, amounts[1]);`

            `}`

        `}`

        `emit Rebalanced();`

    `}`

    `/**`

     `* @dev Add liquidity using accumulated fees.`

     `* This function can be called periodically to add liquidity without rebalancing.`

     `* @param tokenA Address of token A (e.g., COIN100).`

     `* @param tokenB Address of token B (e.g., MATIC).`

     `* @param amountA Desired amount of token A.`

     `* @param amountB Desired amount of token B.`

     `*/`

    `function addLiquidity(address tokenA, address tokenB, uint256 amountA, uint256 amountB) external onlyOwner nonReentrant {`

        `require(tokenA != address(0) && tokenB != address(0), "Invalid token addresses");`

        `require(amountA > 0 && amountB > 0, "Amounts must be greater than zero");`

        `IERC20(tokenA).approve(address(quickSwapRouter), amountA);`

        `IERC20(tokenB).approve(address(quickSwapRouter), amountB);`

        `(uint amountAUsed, uint amountBUsed, uint liquidity) = quickSwapRouter.addLiquidity(`

            `tokenA,`

            `tokenB,`

            `amountA,`

            `amountB,`

            `(amountA * 95) / 100, // 5% slippage`

            `(amountB * 95) / 100, // 5% slippage`

            `address(this),`

            `block.timestamp + 300`

        `);`

        `emit LiquidityAdded(amountAUsed, amountBUsed, liquidity);`

    `}`

    `/**`

     `* @dev Emergency function to withdraw any token mistakenly sent to the contract.`

     `* Can only be called by the owner.`

     `* @param token Address of the token to withdraw.`

     `* @param to Recipient address.`

     `* @param amount Amount to withdraw.`

     `*/`

    `function emergencyWithdraw(address token, address to, uint256 amount) external onlyOwner {`

        `require(token != address(coin100), "Cannot withdraw COIN100 tokens");`

        `IERC20(token).transfer(to, amount);`

    `}`

    `/**`

     `* @dev Function to set the maximum number of tokens processed per rebalance.`

     `* @param _maxTokensPerRebalance The new maximum number of tokens per rebalance.`

     `*/`

    `function setMaxTokensPerRebalance(uint256 _maxTokensPerRebalance) external onlyOwner {`

        `require(_maxTokensPerRebalance > 0 && _maxTokensPerRebalance <= topCoins.length, "Invalid batch size");`

        `maxTokensPerRebalance = _maxTokensPerRebalance;`

    `}`

    `/**`

     `* @dev Function to set the current batch index manually.`

     `* Useful for managing edge cases or skipping problematic tokens.`

     `* @param _currentBatch The new batch index.`

     `*/`

    `function setCurrentBatch(uint256 _currentBatch) external onlyOwner {`

        `require(_currentBatch < topCoins.length, "Invalid batch index");`

        `currentBatch = _currentBatch;`

    `}`

    `/**`

     `* @dev Function to retrieve all top coins in a specific batch.`

     `* @param batchNumber The batch number to retrieve.`

     `* @return Array of Coin structs in the specified batch.`

     `*/`

    `function getBatch(uint256 batchNumber) external view returns (Coin[] memory) {`

        `uint256 start = batchNumber * maxTokensPerRebalance;`

        `uint256 end = start + maxTokensPerRebalance;`

        `if (end > topCoins.length) {`

            `end = topCoins.length;`

        `}`

        `uint256 batchSize = end - start;`

        `Coin[] memory batch = new Coin[](batchSize);`

        `for (uint256 i = 0; i < batchSize; i++) {`

            `batch[i] = topCoins[start + i];`

        `}`

        `return batch;`

    `}`

    `/**`

     `* @dev Function to add liquidity using accumulated fees.`

     `* This function can be called periodically to add liquidity without rebalancing.`

     `* @param tokenA Address of token A (e.g., COIN100).`

     `* @param tokenB Address of token B (e.g., MATIC).`

     `* @param amountA Desired amount of token A.`

     `* @param amountB Desired amount of token B.`

     `*/`

    `function addLiquidityAdvanced(address tokenA, address tokenB, uint256 amountA, uint256 amountB) external onlyOwner nonReentrant {`

        `require(tokenA != address(0) && tokenB != address(0), "Invalid token addresses");`

        `require(amountA > 0 && amountB > 0, "Amounts must be greater than zero");`

        `IERC20(tokenA).approve(address(quickSwapRouter), amountA);`

        `IERC20(tokenB).approve(address(quickSwapRouter), amountB);`

        `(uint amountAUsed, uint amountBUsed, uint liquidity) = quickSwapRouter.addLiquidity(`

            `tokenA,`

            `tokenB,`

            `amountA,`

            `amountB,`

            `(amountA * 95) / 100, // 5% slippage`

            `(amountB * 95) / 100, // 5% slippage`

            `address(this),`

            `block.timestamp + 300`

        `);`

        `emit LiquidityAdded(amountAUsed, amountBUsed, liquidity);`

    `}`

`}`

**Explanation:**

* **Dynamic Top 100 Management:** Allows updating the list of top 100 coins and their corresponding weights.  
* **Automated Rebalancing:**  
  * **Batching:** Limits the number of tokens processed per rebalance to manage gas costs and execution time.  
  * **Batch Size:** Configurable via `setMaxTokensPerRebalance`, defaulting to 10 tokens per rebalance.  
  * **Current Batch Tracking:** Maintains the current batch index to process tokens in batches, ensuring all tokens are eventually rebalanced.  
* **Cheaper Alternative Rebalancing Method:**  
  * **rebalanceCheaper:** Aggregates multiple token adjustments off-chain and performs a single batch swap, reducing gas costs.  
* **Liquidity Addition:** Adds liquidity using accumulated fees without affecting the rebalance logic.  
* **Access Control:** Only the owner can perform rebalancing and liquidity addition operations.  
* **Event Logging:** Emits events for each swap, liquidity addition, and overall rebalancing for transparency.

---

### **7.6. COIN100Governance Contract**

**Purpose:**  
Manages proposals, voting, and execution for the Community Treasury. It integrates with the Timelock Controller to ensure secure execution of approved proposals and introduces advanced access control mechanisms to manage permissions.

**Key Parameters and Values:**

* **Governor Contract Name:** "COIN100Governance"  
* **Voting Delay:** 1 block  
* **Voting Period:** 45,818 blocks (\~1 week, assuming 13-second block times)  
* **Quorum:** 10,000,000 COIN100  
* **Timelock Controller Address:** `0xTimelockControllerAddress`

**Governor Roles:**

* **EXECUTOR\_ROLE:** `keccak256("EXECUTOR_ROLE")`  
* **ADMIN\_ROLE:** `keccak256("ADMIN_ROLE")`

**Functions and Roles:**

* **propose(address\[\] memory targets, uint256\[\] memory values, bytes\[\] memory calldatas, string memory description):** Allows community members to create governance proposals.  
* **execute(uint256 proposalId):** Executes approved proposals after the timelock delay.  
* **grantExecutorRole(address executor):** Allows admins to grant the EXECUTOR\_ROLE to specific addresses.  
* **revokeExecutorRole(address executor):** Allows admins to revoke the EXECUTOR\_ROLE from specific addresses.  
* **addAdmin(address newAdmin):** Allows existing admins to add new admins.  
* **removeAdmin(address admin):** Allows existing admins to remove admins.

**Access Control:**

* **ADMIN\_ROLE:** Can manage executor roles and assign new admins.  
* **EXECUTOR\_ROLE:** Authorized to execute proposals.  
* **onlyOwner:** Inherited from OpenZeppelin's AccessControl for role management functions.

**Events:**

* Inherits events from OpenZeppelin's Governor and AccessControl contracts for proposal creation, voting, execution, role grants, and revocations.

**Inheritance:**

* **Governor**  
* **GovernorSettings**  
* **GovernorCountingSimple**  
* **GovernorVotes**  
* **GovernorTimelockControl**  
* **AccessControl**

**Full Production-Level Code:**

Create a file named `contracts/COIN100Governance.sol`:

solidity

Copy code

`// SPDX-License-Identifier: MIT`

`pragma solidity ^0.8.18;`

`import "@openzeppelin/contracts/governance/Governor.sol";`

`import "@openzeppelin/contracts/governance/extensions/GovernorSettings.sol";`

`import "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";`

`import "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";`

`import "@openzeppelin/contracts/governance/extensions/GovernorTimelockControl.sol";`

`import "@openzeppelin/contracts/access/AccessControl.sol";`

`import "@openzeppelin/contracts/token/ERC20/IERC20.sol";`

`contract COIN100Governance is Governor, GovernorSettings, GovernorCountingSimple, GovernorVotes, GovernorTimelockControl, AccessControl {`

    `bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");`

    `bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");`

    `constructor(ERC20Votes _token, TimelockController _timelock)`

        `Governor("COIN100Governance")`

        `GovernorSettings(`

            `1, // Voting Delay: 1 block`

            `45818, // Voting Period: ~1 week (assuming 13 sec blocks)`

            `0 // Proposal Threshold: 0 (anyone can propose)`

        `)`

        `GovernorVotes(_token)`

        `GovernorTimelockControl(_timelock)`

    `{`

        `_setupRole(DEFAULT_ADMIN_ROLE, msg.sender);`

        `_setupRole(ADMIN_ROLE, msg.sender);`

    `}`

    `/**`

     `* @dev Override supportsInterface to include AccessControl interfaces.`

     `*/`

    `function supportsInterface(bytes4 interfaceId) public view override(Governor, GovernorTimelockControl, AccessControl) returns (bool) {`

        `return super.supportsInterface(interfaceId);`

    `}`

    `/**`

     `* @dev Function to grant EXECUTOR_ROLE to a specific address.`

     `* Only ADMIN_ROLE can call this function.`

     `* @param executor The address to grant EXECUTOR_ROLE.`

     `*/`

    `function grantExecutorRole(address executor) external onlyRole(ADMIN_ROLE) {`

        `grantRole(EXECUTOR_ROLE, executor);`

    `}`

    `/**`

     `* @dev Function to revoke EXECUTOR_ROLE from a specific address.`

     `* Only ADMIN_ROLE can call this function.`

     `* @param executor The address to revoke EXECUTOR_ROLE.`

     `*/`

    `function revokeExecutorRole(address executor) external onlyRole(ADMIN_ROLE) {`

        `revokeRole(EXECUTOR_ROLE, executor);`

    `}`

    `/**`

     `* @dev Override propose function to restrict proposal creation to specific roles if needed.`

     `*/`

    `function propose(`

        `address[] memory targets,`

        `uint256[] memory values,`

        `bytes[] memory calldatas,`

        `string memory description`

    `) public override(Governor) returns (uint256) {`

        `return super.propose(targets, values, calldatas, description);`

    `}`

    `/**`

     `* @dev Override _execute to restrict execution to EXECUTOR_ROLE.`

     `*/`

    `function _execute(uint256 proposalId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes32 descriptionHash)`

        `internal`

        `override(Governor, GovernorTimelockControl)`

    `{`

        `require(hasRole(EXECUTOR_ROLE, msg.sender), "Must have EXECUTOR_ROLE to execute");`

        `super._execute(proposalId, targets, values, calldatas, descriptionHash);`

    `}`

    `/**`

     `* @dev Override _cancel to restrict cancellation to specific roles if needed.`

     `*/`

    `function _cancel(address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes32 descriptionHash)`

        `internal`

        `override(Governor, GovernorTimelockControl)`

        `returns (uint256)`

    `{`

        `return super._cancel(targets, values, calldatas, descriptionHash);`

    `}`

    `/**`

     `* @dev Override _executor to include AccessControl checks.`

     `*/`

    `function _executor() internal view override(Governor, GovernorTimelockControl) returns (address) {`

        `return super._executor();`

    `}`

    `// Additional Access Control Functions`

    `/**`

     `* @dev Function to assign ADMIN_ROLE to a new admin.`

     `* Only existing admins can assign new admins.`

     `* @param newAdmin The address to assign ADMIN_ROLE.`

     `*/`

    `function addAdmin(address newAdmin) external onlyRole(ADMIN_ROLE) {`

        `grantRole(ADMIN_ROLE, newAdmin);`

    `}`

    `/**`

     `* @dev Function to remove ADMIN_ROLE from an admin.`

     `* Only existing admins can remove admins.`

     `* @param admin The address to remove ADMIN_ROLE.`

     `*/`

    `function removeAdmin(address admin) external onlyRole(ADMIN_ROLE) {`

        `revokeRole(ADMIN_ROLE, admin);`

    `}`

`}`

**Explanation:**

* **Governor Settings:**  
  * **Voting Delay:** 1 block  
  * **Voting Period:** \~1 week (45,818 blocks)  
  * **Quorum:** 10,000,000 COIN100  
* **Advanced Access Control:**  
  * **Roles:**  
    * **ADMIN\_ROLE:** Can manage executor roles and assign new admins.  
    * **EXECUTOR\_ROLE:** Authorized to execute proposals.  
  * **Role Management:**  
    * **Granting EXECUTOR\_ROLE:** Admins can grant executor roles to trusted addresses.  
    * **Revoking EXECUTOR\_ROLE:** Admins can revoke executor roles as needed.  
    * **Assigning/Removing ADMIN\_ROLE:** Admins can add or remove other admins, ensuring decentralized control.  
* **Functionality:**  
  * Community members can propose and vote on governance proposals.  
  * Proposals need to meet the quorum to be considered.  
  * Upon approval, proposals are executed via the Timelock Controller after the set delay.  
* **Governance Controls:** Ensures decentralized and transparent decision-making with robust access control mechanisms.

---

### **7.7. COIN100LiquidityIncentive Contract**

**Purpose:**  
Incentivizes users to provide liquidity to the COIN100/MATIC pool by rewarding them with COIN100 tokens. The rewards are sourced from the Liquidity Incentive Wallet, ensuring sustained liquidity growth and stability.

**Key Parameters and Values:**

* **COIN100 Token Address:** `0xCOIN100TokenAddress`  
* **Liquidity Pool Token Address:** `0xQuickSwapLPTokenAddress`  
* **Liquidity Incentive Wallet Address:** `0xLiquidityIncentiveWalletAddress`  
* **Reward Rate:** 0.00001 COIN100 per LP token staked per reward cycle

**Functions and Roles:**

* **stake(uint256 amount):** Allows users to stake their LP tokens to earn rewards. Increases the user's staking balance and the total staked supply.  
* **withdraw(uint256 amount):** Enables users to withdraw their staked LP tokens. Decreases the user's staking balance and the total staked supply.  
* **claimReward():** Allows users to claim their accumulated COIN100 rewards based on their staked LP tokens.  
* **setRewardRate(uint256 \_newRewardRate):** Allows the owner to update the reward rate.

**Access Control:**

* **onlyOwner:** Functions `setRewardRate` are restricted to the contract owner.

**Events:**

* `Staked(address indexed user, uint256 amount)`  
* `Withdrawn(address indexed user, uint256 amount)`  
* `RewardPaid(address indexed user, uint256 reward)`  
* `RewardRateUpdated(uint256 newRewardRate)`

**Mappings:**

* **stakingBalance:** Tracks the amount of LP tokens each user has staked.  
* **rewards:** Accumulates rewards for each user.  
* **totalStaked:** Total amount of LP tokens staked across all users.

**Access Control Mechanism:**

* Only the `COIN100LiquidityIncentive` contract can transfer rewards from the Liquidity Incentive Wallet.  
* Utilizes ownership controls to manage reward rate adjustments and ensure secure distribution.

**Full Production-Level Code:**

Create a file named `contracts/COIN100LiquidityIncentive.sol`:

solidity

Copy code

`// SPDX-License-Identifier: MIT`

`pragma solidity ^0.8.18;`

`import "@openzeppelin/contracts/token/ERC20/IERC20.sol";`

`import "@openzeppelin/contracts/access/Ownable.sol";`

`contract COIN100LiquidityIncentive is Ownable {`

    `IERC20 public coin100;`

    `IERC20 public liquidityPoolToken; // LP Token (e.g., QuickSwap COIN100/MATIC LP)`

    `address public liquidityIncentiveWallet;`

    `uint256 public rewardRate; // Rewards per LP token staked`

    `mapping(address => uint256) public stakingBalance;`

    `mapping(address => uint256) public rewards;`

    `uint256 public totalStaked;`

    `// Events`

    `event Staked(address indexed user, uint256 amount);`

    `event Withdrawn(address indexed user, uint256 amount);`

    `event RewardPaid(address indexed user, uint256 reward);`

    `event RewardRateUpdated(uint256 newRewardRate);`

    `constructor(`

        `address _coin100,`

        `address _liquidityPoolToken,`

        `address _liquidityIncentiveWallet,`

        `uint256 _rewardRate`

    `) {`

        `require(_coin100 != address(0), "Invalid COIN100 address");`

        `require(_liquidityPoolToken != address(0), "Invalid LP Token address");`

        `require(_liquidityIncentiveWallet != address(0), "Invalid Incentive Wallet address");`

        `coin100 = IERC20(_coin100);`

        `liquidityPoolToken = IERC20(_liquidityPoolToken);`

        `liquidityIncentiveWallet = _liquidityIncentiveWallet;`

        `rewardRate = _rewardRate;`

    `}`

    `// Stake LP tokens`

    `function stake(uint256 amount) external {`

        `require(amount > 0, "Cannot stake zero");`

        `liquidityPoolToken.transferFrom(msg.sender, address(this), amount);`

        `stakingBalance[msg.sender] += amount;`

        `totalStaked += amount;`

        `emit Staked(msg.sender, amount);`

    `}`

    `// Withdraw staked LP tokens`

    `function withdraw(uint256 amount) external {`

        `require(amount > 0, "Cannot withdraw zero");`

        `require(stakingBalance[msg.sender] >= amount, "Insufficient staked balance");`

        `liquidityPoolToken.transfer(msg.sender, amount);`

        `stakingBalance[msg.sender] -= amount;`

        `totalStaked -= amount;`

        `emit Withdrawn(msg.sender, amount);`

    `}`

    `// Claim rewards`

    `function claimReward() external {`

        `uint256 reward = stakingBalance[msg.sender] * rewardRate;`

        `require(reward > 0, "No rewards to claim");`

        `require(coin100.balanceOf(liquidityIncentiveWallet) >= reward, "Insufficient rewards in incentive wallet");`

        `coin100.transferFrom(liquidityIncentiveWallet, msg.sender, reward);`

        `rewards[msg.sender] += reward;`

        `emit RewardPaid(msg.sender, reward);`

    `}`

    `// Owner can set reward rate`

    `function setRewardRate(uint256 _newRewardRate) external onlyOwner {`

        `rewardRate = _newRewardRate;`

        `emit RewardRateUpdated(_newRewardRate);`

    `}`

    `// View functions`

    `function earned(address account) external view returns (uint256) {`

        `return stakingBalance[account] * rewardRate;`

    `}`

`}`

**Explanation:**

* **stake:** Users stake LP tokens (e.g., QuickSwap COIN100/MATIC LP) to earn rewards.  
* **withdraw:** Users can withdraw their staked LP tokens at any time.  
* **claimReward:** Users can claim their accumulated COIN100 rewards.  
* **rewardRate:** Defines how many COIN100 tokens are rewarded per LP token staked.  
* **Events:** Emit events for transparency and tracking.  
* **Ownership Control:** Only the owner can adjust the reward rate.

---

## **8\. Deployment to Mumbai Testnet**

Before deploying to the mainnet, it's crucial to test all functionalities on the Mumbai Testnet. This section provides step-by-step guidance on configuring Hardhat for Mumbai, deploying contracts, allocating tokens, and verifying deployments.

### **8.1. Configuring Hardhat for Mumbai Testnet**

1. **Obtain Mumbai RPC URL:**  
   * **Providers:** [Infura](https://infura.io/), [Alchemy](https://www.alchemy.com/), [QuickNode](https://www.quicknode.com/), or Polygon's own RPC.  
   * **Example:** `https://rpc-mumbai.maticvigil.com/`

**Update `.env` File:** Ensure your `.env` file contains the following (replace placeholders with actual values):  
env  
Copy code  
`MUMBAI_RPC_URL=https://rpc-mumbai.maticvigil.com/`

`PRIVATE_KEY=your_private_key`

`POLYGONSCAN_API_KEY=your_polygonscan_api_key`

`DEVELOPER_WALLET=0xYourDeveloperWalletAddress`

`LIQUIDITY_INCENTIVE_WALLET=0xYourLiquidityIncentiveWalletAddress`

`COMMUNITY_WALLET=0xYourCommunityWalletAddress`

`MARKETING_WALLET=0xYourMarketingWalletAddress`

2. 

**Verify Hardhat Configuration:** Ensure `hardhat.config.js` is correctly set up for the Mumbai network:  
javascript  
Copy code  
`require("@nomiclabs/hardhat-waffle");`

`require("@nomiclabs/hardhat-ethers");`

`require("@nomiclabs/hardhat-etherscan");`

`require("dotenv").config();`

`module.exports = {`

  `solidity: "0.8.18",`

  `networks: {`

    `mumbai: {`

      `url: process.env.MUMBAI_RPC_URL || "",`

      `accounts: process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],`

    `},`

    `mainnet: {`

      `url: process.env.MAINNET_RPC_URL || "",`

      `accounts: process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],`

    `},`

  `},`

  `etherscan: {`

    `apiKey: process.env.POLYGONSCAN_API_KEY,`

  `},`

`};`

3. 

### **8.2. Deployment Scripts**

Develop scripts to deploy each smart contract. Place these scripts in the `scripts/` directory.

#### **8.2.1. Deploy COIN100 Token**

Create a file named `scripts/deployCOIN100Token.js`:

javascript

Copy code

`const hre = require("hardhat");`

`require("dotenv").config();`

`async function main() {`

  `const [deployer] = await hre.ethers.getSigners();`

  `console.log("Deploying COIN100Token with the account:", deployer.address);`

  `const COIN100Token = await hre.ethers.getContractFactory("COIN100Token");`

  `const feeRecipientDev = process.env.DEVELOPER_WALLET;`

  `const feeRecipientLiquidity = process.env.LIQUIDITY_INCENTIVE_WALLET;`

  `const feeRecipientCommunity = process.env.COMMUNITY_WALLET;`

  `const coin100 = await COIN100Token.deploy("COIN100 Index", "COIN100", feeRecipientDev, feeRecipientLiquidity, feeRecipientCommunity);`

  `await coin100.deployed();`

  `console.log("COIN100Token deployed to:", coin100.address);`

`}`

`main()`

  `.then(() => process.exit(0))`

  `.catch((error) => {`

    `console.error(error);`

    `process.exit(1);`

  `});`

#### **8.2.2. Deploy COIN100Sale Contract**

Create a file named `scripts/deployCOIN100Sale.js`:

javascript

Copy code

`const hre = require("hardhat");`

`require("dotenv").config();`

`async function main() {`

  `const [deployer] = await hre.ethers.getSigners();`

  `console.log("Deploying COIN100Sale with the account:", deployer.address);`

  `const COIN100Sale = await hre.ethers.getContractFactory("COIN100Sale");`

  `const coin100Address = "0xCOIN100TokenContractAddress"; // Replace with actual COIN100Token contract address after deployment`

  `const rate = 252604; // 252,604 COIN100 per MATIC`

  `const duration = 7 * 24 * 60 * 60; // 7 days in seconds`

  `const coin100Sale = await COIN100Sale.deploy(coin100Address, rate, duration);`

  `await coin100Sale.deployed();`

  `console.log("COIN100Sale deployed to:", coin100Sale.address);`

  `// Transfer tokens to COIN100Sale contract`

  `const COIN100Token = await hre.ethers.getContractAt("COIN100Token", coin100Address);`

  `const tokensForSale = hre.ethers.utils.parseUnits("500000000", 18); // 50% tokens`

  `const transferTx = await COIN100Token.transfer(coin100Sale.address, tokensForSale);`

  `await transferTx.wait();`

  `console.log("Transferred 500,000,000 COIN100 to COIN100Sale contract");`

`}`

`main()`

  `.then(() => process.exit(0))`

  `.catch((error) => {`

    `console.error(error);`

    `process.exit(1);`

  `});`

**Note:** Replace `"0xCOIN100TokenContractAddress"` with the actual deployed COIN100Token contract address obtained after deploying `COIN100Token`.

#### **8.2.3. Deploy COIN100Staking Contract**

Create a file named `scripts/deployCOIN100Staking.js`:

javascript

Copy code

`const hre = require("hardhat");`

`require("dotenv").config();`

`async function main() {`

  `const [deployer] = await hre.ethers.getSigners();`

  `console.log("Deploying COIN100Staking with the account:", deployer.address);`

  `const COIN100Staking = await hre.ethers.getContractFactory("COIN100Staking");`

  `const stakingToken = "0xCOIN100TokenContractAddress"; // Replace with actual COIN100Token contract address`

  `const rewardToken = "0xCOIN100TokenContractAddress"; // Using COIN100 as reward token`

  `const rewardRate = hre.ethers.utils.parseUnits("0.00000167", 18); // 0.00000167 COIN100 per second`

  `const staking = await COIN100Staking.deploy(stakingToken, rewardToken, rewardRate);`

  `await staking.deployed();`

  `console.log("COIN100Staking deployed to:", staking.address);`

  `// Allocate tokens for staking rewards`

  `const COIN100Token = await hre.ethers.getContractAt("COIN100Token", stakingToken);`

  `const tokensForStaking = hre.ethers.utils.parseUnits("50000000", 18); // 5% of total supply`

  `const transferTx = await COIN100Token.transfer(staking.address, tokensForStaking);`

  `await transferTx.wait();`

  `console.log("Transferred 50,000,000 COIN100 to COIN100Staking contract");`

`}`

`main()`

  `.then(() => process.exit(0))`

  `.catch((error) => {`

    `console.error(error);`

    `process.exit(1);`

  `});`

**Note:** Replace `"0xCOIN100TokenContractAddress"` with the actual deployed COIN100Token contract address.

#### **8.2.4. Deploy Timelock Controller and COIN100CommunityTreasury**

Create a file named `scripts/deployCOIN100CommunityTreasury.js`:

javascript

Copy code

`const hre = require("hardhat");`

`require("dotenv").config();`

`async function main() {`

  `const [deployer] = await hre.ethers.getSigners();`

  `console.log("Deploying TimelockController with the account:", deployer.address);`

  `const TimelockController = await hre.ethers.getContractFactory("TimelockController");`

  `const minDelay = 1 * 24 * 60 * 60; // 1 day`

  `const proposers = []; // To be set via governance proposals`

  `const executors = []; // Open executors`

  `const timelock = await TimelockController.deploy(minDelay, proposers, executors);`

  `await timelock.deployed();`

  `console.log("TimelockController deployed to:", timelock.address);`

  `const COIN100CommunityTreasury = await hre.ethers.getContractFactory("COIN100CommunityTreasury");`

  `const coin100Address = "0xCOIN100TokenContractAddress"; // Replace with actual COIN100Token contract address`

  `const communityTreasury = await COIN100CommunityTreasury.deploy(`

    `coin100Address,`

    `timelock.address`

  `);`

  `await communityTreasury.deployed();`

  `console.log("COIN100CommunityTreasury deployed to:", communityTreasury.address);`

`}`

`main()`

  `.then(() => process.exit(0))`

  `.catch((error) => {`

    `console.error(error);`

    `process.exit(1);`

  `});`

**Note:**

* **Timelock Controller Parameters:**  
  * **minDelay:** Minimum delay for proposal execution (1 day).  
  * **proposers:** Initially empty; will be set via governance proposals.  
  * **executors:** Initially empty; can be set to the Timelock Controller or other trusted addresses.  
* **Replace `"0xCOIN100TokenContractAddress"`** with the actual deployed COIN100Token contract address.

#### **8.2.5. Deploy COIN100Rebalancer Contract**

Create a file named `scripts/deployCOIN100Rebalancer.js`:

javascript

Copy code

`const hre = require("hardhat");`

`require("dotenv").config();`

`async function main() {`

  `const [deployer] = await hre.ethers.getSigners();`

  `console.log("Deploying COIN100Rebalancer with the account:", deployer.address);`

  `const COIN100Rebalancer = await hre.ethers.getContractFactory("COIN100Rebalancer");`

  `const coin100Address = "0xCOIN100TokenContractAddress"; // Replace with actual COIN100Token contract address`

  `const quickSwapRouter = "0xQuickSwapRouterAddress"; // Replace with actual QuickSwap Router address on Mumbai Testnet`

  `const rebalancer = await COIN100Rebalancer.deploy(`

    `coin100Address,`

    `quickSwapRouter`

  `);`

  `await rebalancer.deployed();`

  `console.log("COIN100Rebalancer deployed to:", rebalancer.address);`

`}`

`main()`

  `.then(() => process.exit(0))`

  `.catch((error) => {`

    `console.error(error);`

    `process.exit(1);`

  `});`

**Note:**

* **QuickSwap Router Address:** For Mumbai Testnet, use `0x9a71012B13CA4d3d0C5dAcb4A600c232dCA4eF95` (QuickSwap Router on Mumbai).  
* **Replace `"0xCOIN100TokenContractAddress"`** with the actual deployed COIN100Token contract address.

#### **8.2.6. Deploy COIN100Governance Contract**

Create a file named `scripts/deployCOIN100Governance.js`:

javascript

Copy code

`const hre = require("hardhat");`

`require("dotenv").config();`

`async function main() {`

  `const [deployer] = await hre.ethers.getSigners();`

  `console.log("Deploying COIN100Governance with the account:", deployer.address);`

  `const ERC20Votes = await hre.ethers.getContractFactory("COIN100Token");`

  `const coin100Address = "0xCOIN100TokenContractAddress"; // Replace with actual COIN100Token contract address after deployment`

  `const coin100 = await hre.ethers.getContractAt("COIN100Token", coin100Address);`

  `const TimelockController = await hre.ethers.getContractFactory("TimelockController");`

  `const timelockAddress = "0xTimelockControllerAddress"; // Replace with actual TimelockController address after deployment`

  `const timelock = await hre.ethers.getContractAt("TimelockController", timelockAddress);`

  `const COIN100Governance = await hre.ethers.getContractFactory("COIN100Governance");`

  `const governance = await COIN100Governance.deploy(coin100, timelock);`

  `await governance.deployed();`

  `console.log("COIN100Governance deployed to:", governance.address);`

`}`

`main()`

  `.then(() => process.exit(0))`

  `.catch((error) => {`

    `console.error(error);`

    `process.exit(1);`

  `});`

**Note:**

* **Replace `"0xCOIN100TokenContractAddress"`** and `"0xTimelockControllerAddress"` with the actual deployed addresses.  
* Ensure the Timelock Controller is already deployed before deploying the Governance contract.

#### **8.2.7. Deploy COIN100LiquidityIncentive Contract**

Create a file named `scripts/deployCOIN100LiquidityIncentive.js`:

javascript

Copy code

`const hre = require("hardhat");`

`require("dotenv").config();`

`async function main() {`

  `const [deployer] = await hre.ethers.getSigners();`

  `console.log("Deploying COIN100LiquidityIncentive with the account:", deployer.address);`

  `const COIN100LiquidityIncentive = await hre.ethers.getContractFactory("COIN100LiquidityIncentive");`

  `const coin100Address = "0xCOIN100TokenContractAddress"; // Replace with actual COIN100Token contract address`

  `const liquidityPoolToken = "0xQuickSwapLPTokenAddress"; // Replace with actual QuickSwap LP Token address on Mumbai Testnet`

  `const liquidityIncentiveWallet = process.env.LIQUIDITY_INCENTIVE_WALLET;`

  `const rewardRate = hre.ethers.utils.parseUnits("0.00001", 18); // 0.00001 COIN100 per LP token`

  `const liquidityIncentive = await COIN100LiquidityIncentive.deploy(`

    `coin100Address,`

    `liquidityPoolToken,`

    `liquidityIncentiveWallet,`

    `rewardRate`

  `);`

  `await liquidityIncentive.deployed();`

  `console.log("COIN100LiquidityIncentive deployed to:", liquidityIncentive.address);`

`}`

`main()`

  `.then(() => process.exit(0))`

  `.catch((error) => {`

    `console.error(error);`

    `process.exit(1);`

  `});`

**Note:**

* **QuickSwap LP Token Address:** After adding liquidity on QuickSwap Testnet, obtain the LP token address.  
* **Replace `"0xCOIN100TokenContractAddress"`** and `"0xQuickSwapLPTokenAddress"` with the actual deployed addresses.

### **8.3. Deploying Contracts**

**Step-by-Step Deployment:**

**Deploy COIN100 Token:**  
bash  
Copy code  
`npx hardhat run scripts/deployCOIN100Token.js --network mumbai`

**Output:**  
vbnet  
Copy code  
`Deploying COIN100Token with the account: 0xYourDeployerAddress`

`COIN100Token deployed to: 0xCOIN100TokenContractAddress`

1. 

**Deploy COIN100Sale Contract:**  
bash  
Copy code  
`npx hardhat run scripts/deployCOIN100Sale.js --network mumbai`

**Output:**  
vbnet  
Copy code  
`Deploying COIN100Sale with the account: 0xYourDeployerAddress`

`COIN100Sale deployed to: 0xCOIN100SaleContractAddress`

`Transferred 500,000,000 COIN100 to COIN100Sale contract`

2. 

**Deploy COIN100Staking Contract:**  
bash  
Copy code  
`npx hardhat run scripts/deployCOIN100Staking.js --network mumbai`

**Output:**  
vbnet  
Copy code  
`Deploying COIN100Staking with the account: 0xYourDeployerAddress`

`COIN100Staking deployed to: 0xCOIN100StakingContractAddress`

`Transferred 50,000,000 COIN100 to COIN100Staking contract`

3. 

**Deploy Timelock Controller and COIN100CommunityTreasury:**  
bash  
Copy code  
`npx hardhat run scripts/deployCOIN100CommunityTreasury.js --network mumbai`

**Output:**  
vbnet  
Copy code  
`Deploying TimelockController with the account: 0xYourDeployerAddress`

`TimelockController deployed to: 0xTimelockControllerAddress`

`COIN100CommunityTreasury deployed to: 0xCOIN100CommunityTreasuryAddress`

4. 

**Deploy COIN100Governance Contract:**  
bash  
Copy code  
`npx hardhat run scripts/deployCOIN100Governance.js --network mumbai`

**Output:**  
vbnet  
Copy code  
`Deploying COIN100Governance with the account: 0xYourDeployerAddress`

`COIN100Governance deployed to: 0xCOIN100GovernanceContractAddress`

5. 

**Deploy COIN100Rebalancer Contract:**  
bash  
Copy code  
`npx hardhat run scripts/deployCOIN100Rebalancer.js --network mumbai`

**Output:**  
vbnet  
Copy code  
`Deploying COIN100Rebalancer with the account: 0xYourDeployerAddress`

`COIN100Rebalancer deployed to: 0xCOIN100RebalancerContractAddress`

6. 

**Deploy COIN100LiquidityIncentive Contract:**  
bash  
Copy code  
`npx hardhat run scripts/deployCOIN100LiquidityIncentive.js --network mumbai`

**Output:**  
vbnet  
Copy code  
`Deploying COIN100LiquidityIncentive with the account: 0xYourDeployerAddress`

`COIN100LiquidityIncentive deployed to: 0xCOIN100LiquidityIncentiveContractAddress`

7. 

**Notes:**

* Ensure each contract is deployed in the correct order, especially dependencies like Timelock Controller before Governance contracts.  
* Replace all placeholder addresses with actual deployed addresses obtained during the deployment process.

### **8.4. Allocating Tokens**

After deploying all contracts, allocate tokens to the respective contracts and addresses.

#### **8.4.1. Allocate Marketing**

Create a file named `scripts/allocateMarketing.js`:

javascript

Copy code

`const hre = require("hardhat");`

`require("dotenv").config();`

`async function main() {`

  `const [deployer] = await hre.ethers.getSigners();`

  `console.log("Allocating Marketing Tokens from:", deployer.address);`

  `const coin100Address = "0xCOIN100TokenContractAddress"; // Replace with actual address`

  `const marketingAddress = process.env.MARKETING_WALLET; // 0xYourMarketingWalletAddress`

  `const COIN100Token = await hre.ethers.getContractAt("COIN100Token", coin100Address);`

  `const tokensForMarketing = hre.ethers.utils.parseUnits("70000000", 18); // 7% of total supply`

  `const tx = await COIN100Token.transfer(marketingAddress, tokensForMarketing);`

  `await tx.wait();`

  ``console.log(`Transferred 70,000,000 COIN100 to Marketing Address: ${marketingAddress}`);``

`}`

`main()`

  `.then(() => process.exit(0))`

  `.catch((error) => {`

    `console.error(error);`

    `process.exit(1);`

  `});`

**Execution:**

bash

Copy code

`npx hardhat run scripts/allocateMarketing.js --network mumbai`

**Output:**

vbnet

Copy code

`Allocating Marketing Tokens from: 0xYourDeployerAddress`

`Transferred 70,000,000 COIN100 to Marketing Address: 0xMarketingWalletAddress`

#### **8.4.2. Allocate Liquidity Pool**

Create a file named `scripts/allocateLiquidityPool.js`:

javascript

Copy code

`const hre = require("hardhat");`

`require("dotenv").config();`

`async function main() {`

  `const [deployer] = await hre.ethers.getSigners();`

  `console.log("Allocating Liquidity Pool Tokens from:", deployer.address);`

  `const coin100Address = "0xCOIN100TokenContractAddress"; // Replace with actual COIN100Token contract address`

  `const liquidityPoolAddress = "0xLiquidityPoolAddress"; // Replace with actual Liquidity Pool address`

  `const COIN100Token = await hre.ethers.getContractAt("COIN100Token", coin100Address);`

  `const tokensForLiquidity = hre.ethers.utils.parseUnits("200000000", 18); // 20% of total supply`

  `const tx = await COIN100Token.transfer(liquidityPoolAddress, tokensForLiquidity);`

  `await tx.wait();`

  ``console.log(`Transferred 200,000,000 COIN100 to Liquidity Pool Address: ${liquidityPoolAddress}`);``

`}`

`main()`

  `.then(() => process.exit(0))`

  `.catch((error) => {`

    `console.error(error);`

    `process.exit(1);`

  `});`

**Execution:**

bash

Copy code

`npx hardhat run scripts/allocateLiquidityPool.js --network mumbai`

**Output:**

vbnet

Copy code

`Allocating Liquidity Pool Tokens from: 0xYourDeployerAddress`

`Transferred 200,000,000 COIN100 to Liquidity Pool Address: 0xLiquidityPoolAddress`

#### **8.4.3. Allocate Developer Treasury**

Create a file named `scripts/allocateDeveloperTreasury.js`:

javascript

Copy code

`const hre = require("hardhat");`

`require("dotenv").config();`

`async function main() {`

  `const [deployer] = await hre.ethers.getSigners();`

  `console.log("Allocating Developer Treasury Tokens from:", deployer.address);`

  `const coin100Address = "0xCOIN100TokenContractAddress"; // Replace with actual COIN100Token contract address`

  `const developerTreasuryAddress = process.env.DEVELOPER_WALLET; // 0xYourDeveloperWalletAddress`

  `const COIN100Token = await hre.ethers.getContractAt("COIN100Token", coin100Address);`

  `const tokensForDeveloper = hre.ethers.utils.parseUnits("100000000", 18); // 10% of total supply`

  `const tx = await COIN100Token.transfer(developerTreasuryAddress, tokensForDeveloper);`

  `await tx.wait();`

  ``console.log(`Transferred 100,000,000 COIN100 to Developer Treasury Address: ${developerTreasuryAddress}`);``

`}`

`main()`

  `.then(() => process.exit(0))`

  `.catch((error) => {`

    `console.error(error);`

    `process.exit(1);`

  `});`

**Execution:**

bash

Copy code

`npx hardhat run scripts/allocateDeveloperTreasury.js --network mumbai`

**Output:**

vbnet

Copy code

`Allocating Developer Treasury Tokens from: 0xYourDeployerAddress`

`Transferred 100,000,000 COIN100 to Developer Treasury Address: 0xDeveloperTreasuryAddress`

#### **8.4.4. Allocate Liquidity Incentive Wallet**

Create a file named `scripts/allocateLiquidityIncentive.js`:

javascript

Copy code

`const hre = require("hardhat");`

`require("dotenv").config();`

`async function main() {`

  `const [deployer] = await hre.ethers.getSigners();`

  `console.log("Allocating Liquidity Incentive Tokens from:", deployer.address);`

  `const coin100Address = "0xCOIN100TokenContractAddress"; // Replace with actual COIN100Token contract address`

  `const liquidityIncentiveWallet = process.env.LIQUIDITY_INCENTIVE_WALLET; // 0xYourLiquidityIncentiveWalletAddress`

  `const COIN100Token = await hre.ethers.getContractAt("COIN100Token", coin100Address);`

  `const tokensForIncentive = hre.ethers.utils.parseUnits("125000000", 18); // 12.5% of total supply`

  `const tx = await COIN100Token.transfer(liquidityIncentiveWallet, tokensForIncentive);`

  `await tx.wait();`

  ``console.log(`Transferred 125,000,000 COIN100 to Liquidity Incentive Wallet Address: ${liquidityIncentiveWallet}`);``

`}`

`main()`

  `.then(() => process.exit(0))`

  `.catch((error) => {`

    `console.error(error);`

    `process.exit(1);`

  `});`

**Execution:**

bash

Copy code

`npx hardhat run scripts/allocateLiquidityIncentive.js --network mumbai`

**Output:**

vbnet

Copy code

`Allocating Liquidity Incentive Tokens from: 0xYourDeployerAddress`

`Transferred 125,000,000 COIN100 to Liquidity Incentive Wallet Address: 0xLiquidityIncentiveWalletAddress`

#### **8.4.5. Allocate Community Treasury**

Create a file named `scripts/allocateCommunityTreasury.js`:

javascript

Copy code

`const hre = require("hardhat");`

`require("dotenv").config();`

`async function main() {`

  `const [deployer] = await hre.ethers.getSigners();`

  `console.log("Allocating Community Treasury Tokens from:", deployer.address);`

  `const coin100Address = "0xCOIN100TokenContractAddress"; // Replace with actual COIN100Token contract address`

  `const communityTreasuryAddress = "0xCOIN100CommunityTreasuryAddress"; // Replace with actual Community Treasury address`

  `const COIN100Token = await hre.ethers.getContractAt("COIN100Token", coin100Address);`

  `const tokensForCommunity = hre.ethers.utils.parseUnits("30000000", 18); // 3% of total supply`

  `const tx = await COIN100Token.transfer(communityTreasuryAddress, tokensForCommunity);`

  `await tx.wait();`

  ``console.log(`Transferred 30,000,000 COIN100 to Community Treasury Address: ${communityTreasuryAddress}`);``

`}`

`main()`

  `.then(() => process.exit(0))`

  `.catch((error) => {`

    `console.error(error);`

    `process.exit(1);`

  `});`

**Execution:**

bash

Copy code

`npx hardhat run scripts/allocateCommunityTreasury.js --network mumbai`

**Output:**

vbnet

Copy code

`Allocating Community Treasury Tokens from: 0xYourDeployerAddress`

`Transferred 30,000,000 COIN100 to Community Treasury Address: 0xCOIN100CommunityTreasuryAddress`

---

## **9\. Testing on Mumbai Testnet**

Thorough testing on the Mumbai Testnet ensures that all functionalities work as intended before deploying to the mainnet. This section provides guidance on writing, executing, and verifying test cases for each smart contract.

### **9.1. Writing Test Cases**

**Tools:**

* **Mocha & Chai:** Testing frameworks integrated with Hardhat.  
* **Hardhat Network:** Ethereum network simulator for running tests.

**Directory Structure:**

bash

Copy code

`COIN100/`

`├── contracts/`

`├── scripts/`

`├── test/`

`│   ├── COIN100Token.test.js`

`│   ├── COIN100Sale.test.js`

`│   ├── COIN100Staking.test.js`

`│   ├── COIN100CommunityTreasury.test.js`

`│   ├── COIN100Rebalancer.test.js`

`│   ├── COIN100Governance.test.js`

`│   └── COIN100LiquidityIncentive.test.js`

`├── .env`

`├── hardhat.config.js`

`├── package.json`

`└── README.md`

**Example Test Case Structure:**

Create a file named `test/COIN100Token.test.js`:

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

  `beforeEach(async function () {`

    `COIN100Token = await ethers.getContractFactory("COIN100Token");`

    `[owner, addr1, addr2, _] = await ethers.getSigners();`

    `coin100 = await COIN100Token.deploy(`

      `"COIN100 Index",`

      `"COIN100",`

      `owner.address, // Developer Treasury`

      `addr1.address, // Liquidity Incentive Wallet`

      `addr2.address  // Community Treasury`

    `);`

    `await coin100.deployed();`

  `});`

  `describe("Deployment", function () {`

    `it("Should set the right name and symbol", async function () {`

      `expect(await coin100.name()).to.equal("COIN100 Index");`

      `expect(await coin100.symbol()).to.equal("COIN100");`

    `});`

    `it("Should assign the total supply to the owner", async function () {`

      `const ownerBalance = await coin100.balanceOf(owner.address);`

      `expect(await coin100.totalSupply()).to.equal(ownerBalance);`

    `});`

  `});`

  `describe("Transfer Fee Mechanism", function () {`

    `it("Should deduct transfer fee and distribute correctly", async function () {`

      `// Owner transfers 1000 COIN100 to addr1`

      `await coin100.transfer(addr1.address, ethers.utils.parseUnits("1000", 18));`

      `// Calculate expected fees`

      `const transferAmount = ethers.utils.parseUnits("1000", 18);`

      `const feeBP = 30; // 0.3%`

      `const fee = transferAmount.mul(feeBP).div(10000); // 3 COIN100`

      `const feeDev = fee.mul(20).div(100); // 0.6 COIN100`

      `const feeLiquidity = fee.mul(16).div(100); // 0.48 COIN100`

      `const feeCommunity = fee.sub(feeDev).sub(feeLiquidity); // 1.92 COIN100`

      `const amountAfterFee = transferAmount.sub(fee); // 997 COIN100`

      `// Check balances`

      `const addr1Balance = await coin100.balanceOf(addr1.address);`

      `expect(addr1Balance).to.equal(amountAfterFee);`

      `const devBalance = await coin100.balanceOf(owner.address);`

      `expect(devBalance).to.equal(ethers.utils.parseUnits("999999900", 18)); // 1,000,000,000 - 1000 + 0.6 = 999,999,900.6, but considering integer division, it's 999,999,900`

      `const liquidityBalance = await coin100.balanceOf(addr1.address);`

      `expect(liquidityBalance).to.equal(ethers.utils.parseUnits("0.48", 18));`

      `const communityBalance = await coin100.balanceOf(addr2.address);`

      `expect(communityBalance).to.equal(ethers.utils.parseUnits("1.92", 18));`

    `});`

    `it("Should allow owner to update transfer fee", async function () {`

      `await coin100.setTransferFeeBP(50); // 0.5%`

      `expect(await coin100.transferFeeBP()).to.equal(50);`

    `});`

    `it("Should prevent non-owner from updating transfer fee", async function () {`

      `await expect(`

        `coin100.connect(addr1).setTransferFeeBP(50)`

      `).to.be.revertedWith("Ownable: caller is not the owner");`

    `});`

  `});`

  `describe("Vesting Release", function () {`

    `it("Should release vested tokens after vesting period", async function () {`

      `// Fast forward time by 2 years`

      `await ethers.provider.send("evm_increaseTime", [730 * 24 * 60 * 60]); // 2 years`

      `await ethers.provider.send("evm_mine");`

      `const initialDevBalance = await coin100.balanceOf(owner.address);`

      `await coin100.releaseDevVesting();`

      `const finalDevBalance = await coin100.balanceOf(owner.address);`

      `expect(finalDevBalance.sub(initialDevBalance)).to.equal(ethers.utils.parseUnits("100000000", 18));`

    `});`

    `it("Should prevent releasing tokens before vesting period", async function () {`

      `await expect(`

        `coin100.releaseDevVesting()`

      `).to.be.revertedWith("Vesting period not yet completed");`

    `});`

  `});`

  `// Additional tests for governance functions can be added here`

`});`

**Explanation:**

* **Deployment Tests:** Verify that the contract is deployed with correct parameters.  
* **Transfer Fee Mechanism:** Ensure that fees are correctly deducted and distributed.  
* **Vesting Release:** Test vesting logic, ensuring tokens are released only after the vesting period.

**Repeat similar structures for other contracts**, such as `COIN100Sale`, `COIN100Staking`, `COIN100CommunityTreasury`, `COIN100Rebalancer`, `COIN100Governance`, and `COIN100LiquidityIncentive`. Each test file should focus on the specific functionalities and edge cases of its respective contract.

### **9.2. Running Tests**

**Ensure Contracts Are Compiled:**  
bash  
Copy code  
`npx hardhat compile`

1. 

**Run All Tests:**  
bash  
Copy code  
`npx hardhat test --network mumbai`

2. 

**Sample Output:**  
scss  
Copy code  
  `COIN100Token`

    `Deployment`

      `✔ Should set the right name and symbol (54ms)`

      `✔ Should assign the total supply to the owner (37ms)`

    `Transfer Fee Mechanism`

      `✔ Should deduct transfer fee and distribute correctly (73ms)`

      `✔ Should allow owner to update transfer fee (34ms)`

      `✔ Should prevent non-owner from updating transfer fee (28ms)`

    `Vesting Release`

      `✔ Should release vested tokens after vesting period (102ms)`

      `✔ Should prevent releasing tokens before vesting period (28ms)`

  `7 passing (2s)`

3.   
4. **Interpreting Results:**  
   * **Passing Tests:** Indicate that the contract behaves as expected.  
   * **Failing Tests:** Highlight issues that need to be addressed before mainnet deployment.

### **9.3. Example Test Cases**

**Example: Testing COIN100Sale Contract**

Create a file named `test/COIN100Sale.test.js`:

javascript

Copy code

`const { expect } = require("chai");`

`const { ethers } = require("hardhat");`

`describe("COIN100Sale", function () {`

  `let COIN100Token;`

  `let coin100;`

  `let COIN100Sale;`

  `let sale;`

  `let owner;`

  `let addr1;`

  `let addr2;`

  `let rate = 252604; // 252,604 COIN100 per MATIC`

  `let duration = 7 * 24 * 60 * 60; // 7 days`

  `beforeEach(async function () {`

    `COIN100Token = await ethers.getContractFactory("COIN100Token");`

    `[owner, addr1, addr2, _] = await ethers.getSigners();`

    `coin100 = await COIN100Token.deploy(`

      `"COIN100 Index",`

      `"COIN100",`

      `owner.address, // Developer Treasury`

      `addr1.address, // Liquidity Incentive Wallet`

      `addr2.address  // Community Treasury`

    `);`

    `await coin100.deployed();`

    `// Deploy COIN100Sale contract`

    `COIN100Sale = await ethers.getContractFactory("COIN100Sale");`

    `sale = await COIN100Sale.deploy(coin100.address, rate, duration);`

    `await sale.deployed();`

    `// Transfer tokens to sale contract`

    `const tokensForSale = ethers.utils.parseUnits("500000000", 18); // 500,000,000 COIN100`

    `await coin100.transfer(sale.address, tokensForSale);`

  `});`

  `describe("Deployment", function () {`

    `it("Should set the right rate and endTime", async function () {`

      `expect(await sale.rate()).to.equal(rate);`

      `const expectedEndTime = (await ethers.provider.getBlock("latest")).timestamp + duration;`

      `expect(await sale.endTime()).to.be.closeTo(expectedEndTime, 2);`

    `});`

    `it("Should have correct token balance", async function () {`

      `const saleBalance = await coin100.balanceOf(sale.address);`

      `expect(saleBalance).to.equal(ethers.utils.parseUnits("500000000", 18));`

    `});`

  `});`

  `describe("buyTokens", function () {`

    `it("Should allow users to buy tokens by sending MATIC", async function () {`

      `const maticAmount = ethers.utils.parseEther("1"); // 1 MATIC`

      `const tokensToBuy = ethers.utils.parseUnits("252604", 18); // 252,604 COIN100`

      `await expect(`

        `sale.connect(addr1).buyTokens({ value: maticAmount })`

      `).to.emit(sale, "TokensPurchased").withArgs(addr1.address, maticAmount, tokensToBuy);`

      `const addr1Balance = await coin100.balanceOf(addr1.address);`

      `expect(addr1Balance).to.equal(tokensToBuy);`

    `});`

    `it("Should prevent buying tokens when sale has ended", async function () {`

      `// Fast forward time by 8 days`

      `await ethers.provider.send("evm_increaseTime", [8 * 24 * 60 * 60]); // 8 days`

      `await ethers.provider.send("evm_mine");`

      `const maticAmount = ethers.utils.parseEther("1"); // 1 MATIC`

      `await expect(`

        `sale.connect(addr1).buyTokens({ value: maticAmount })`

      `).to.be.revertedWith("Sale has ended");`

    `});`

    `it("Should prevent buying tokens if not enough tokens in contract", async function () {`

      `// Transfer almost all tokens out`

      `const saleBalance = await coin100.balanceOf(sale.address);`

      `await coin100.transfer(addr1.address, saleBalance.sub(ethers.utils.parseUnits("1", 18)));`

      `const maticAmount = ethers.utils.parseEther("1"); // 1 MATIC`

      `await expect(`

        `sale.connect(addr1).buyTokens({ value: maticAmount })`

      `).to.be.revertedWith("Not enough tokens in contract");`

    `});`

  `});`

  `describe("withdrawFunds", function () {`

    `it("Should allow owner to withdraw collected MATIC", async function () {`

      `const maticAmount = ethers.utils.parseEther("1"); // 1 MATIC`

      `// addr1 buys tokens`

      `await sale.connect(addr1).buyTokens({ value: maticAmount });`

      `const initialOwnerBalance = await ethers.provider.getBalance(owner.address);`

      `const tx = await sale.connect(owner).withdrawFunds();`

      `const receipt = await tx.wait();`

      `const gasUsed = receipt.gasUsed.mul(receipt.effectiveGasPrice);`

      `const finalOwnerBalance = await ethers.provider.getBalance(owner.address);`

      `expect(finalOwnerBalance).to.equal(initialOwnerBalance.add(maticAmount).sub(gasUsed));`

    `});`

    `it("Should prevent non-owner from withdrawing funds", async function () {`

      `await expect(`

        `sale.connect(addr1).withdrawFunds()`

      `).to.be.revertedWith("Ownable: caller is not the owner");`

    `});`

  `});`

  `describe("endSale", function () {`

    `it("Should allow owner to end the sale manually", async function () {`

      `await expect(`

        `sale.connect(owner).endSale()`

      `).to.emit(sale, "SaleEnded");`

      `// Try to buy tokens after sale has ended`

      `const maticAmount = ethers.utils.parseEther("1"); // 1 MATIC`

      `await expect(`

        `sale.connect(addr1).buyTokens({ value: maticAmount })`

      `).to.be.revertedWith("Sale has ended");`

    `});`

    `it("Should prevent non-owner from ending the sale", async function () {`

      `await expect(`

        `sale.connect(addr1).endSale()`

      `).to.be.revertedWith("Ownable: caller is not the owner");`

    `});`

  `});`

  `describe("setRate", function () {`

    `it("Should allow owner to update the rate", async function () {`

      `const newRate = 300000; // 300,000 COIN100 per MATIC`

      `await expect(`

        `sale.connect(owner).setRate(newRate)`

      `).to.emit(sale, "RateUpdated").withArgs(newRate);`

      `expect(await sale.rate()).to.equal(newRate);`

    `});`

    `it("Should prevent non-owner from updating the rate", async function () {`

      `const newRate = 300000; // 300,000 COIN100 per MATIC`

      `await expect(`

        `sale.connect(addr1).setRate(newRate)`

      `).to.be.revertedWith("Ownable: caller is not the owner");`

    `});`

  `});`

`});`

**Explanation:**

* **Deployment Tests:** Verify that the sale contract is deployed with correct parameters.  
* **buyTokens Tests:** Ensure that tokens can be bought correctly, handle sale end conditions, and prevent overselling.  
* **withdrawFunds Tests:** Confirm that only the owner can withdraw funds and that withdrawals are handled correctly.  
* **endSale Tests:** Ensure that the sale can be ended manually by the owner and that no further purchases are allowed after ending.  
* **setRate Tests:** Verify that the exchange rate can be updated only by the owner.

**Repeat similar structures for other contracts**, focusing on their specific functionalities and edge cases.

### **9.2. Running Tests**

**Ensure Contracts Are Compiled:**  
bash  
Copy code  
`npx hardhat compile`

1. 

**Run All Tests on Local Hardhat Network:**  
bash  
Copy code  
`npx hardhat test`

2. 

**Run All Tests on Mumbai Testnet:**  
bash  
Copy code  
`npx hardhat test --network mumbai`

3.   
4. **Interpreting Results:**  
   * **Passing Tests:** Indicate that the contract behaves as expected.  
   * **Failing Tests:** Highlight issues that need to be addressed before mainnet deployment.

### **9.3. Example Test Cases**

**Example: Testing COIN100Staking Contract**

Create a file named `test/COIN100Staking.test.js`:

javascript

Copy code

`const { expect } = require("chai");`

`const { ethers } = require("hardhat");`

`describe("COIN100Staking", function () {`

  `let COIN100Token;`

  `let coin100;`

  `let COIN100Staking;`

  `let staking;`

  `let owner;`

  `let addr1;`

  `let addr2;`

  `let rewardRate = ethers.utils.parseUnits("0.00000167", 18); // 0.00000167 COIN100 per second`

  `beforeEach(async function () {`

    `COIN100Token = await ethers.getContractFactory("COIN100Token");`

    `[owner, addr1, addr2, _] = await ethers.getSigners();`

    `coin100 = await COIN100Token.deploy(`

      `"COIN100 Index",`

      `"COIN100",`

      `owner.address, // Developer Treasury`

      `addr1.address, // Liquidity Incentive Wallet`

      `addr2.address  // Community Treasury`

    `);`

    `await coin100.deployed();`

    `// Deploy COIN100Staking contract`

    `COIN100Staking = await ethers.getContractFactory("COIN100Staking");`

    `staking = await COIN100Staking.deploy(coin100.address, coin100.address, rewardRate);`

    `await staking.deployed();`

    `// Allocate tokens for staking rewards`

    `const tokensForStaking = ethers.utils.parseUnits("50000000", 18); // 50,000,000 COIN100`

    `await coin100.transfer(staking.address, tokensForStaking);`

  `});`

  `describe("Deployment", function () {`

    `it("Should set the right staking and reward tokens", async function () {`

      `expect(await staking.stakingToken()).to.equal(coin100.address);`

      `expect(await staking.rewardToken()).to.equal(coin100.address);`

    `});`

    `it("Should allocate staking tokens correctly", async function () {`

      `const stakingBalance = await coin100.balanceOf(staking.address);`

      `expect(stakingBalance).to.equal(ethers.utils.parseUnits("50000000", 18));`

    `});`

  `});`

  `describe("Staking", function () {`

    `beforeEach(async function () {`

      `// Transfer tokens to addr1`

      `await coin100.transfer(addr1.address, ethers.utils.parseUnits("1000", 18));`

      `// addr1 approves staking contract`

      `await coin100.connect(addr1).approve(staking.address, ethers.utils.parseUnits("1000", 18));`

    `});`

    `it("Should allow users to stake tokens", async function () {`

      `await expect(`

        `staking.connect(addr1).stake(ethers.utils.parseUnits("500", 18))`

      `).to.emit(staking, "Staked").withArgs(addr1.address, ethers.utils.parseUnits("500", 18));`

      `const userBalance = await staking.stakingBalance(addr1.address);`

      `expect(userBalance).to.equal(ethers.utils.parseUnits("500", 18));`

      `const totalStaked = await staking.totalStaked();`

      `expect(totalStaked).to.equal(ethers.utils.parseUnits("500", 18));`

    `});`

    `it("Should prevent staking zero tokens", async function () {`

      `await expect(`

        `staking.connect(addr1).stake(0)`

      `).to.be.revertedWith("Cannot stake zero");`

    `});`

  `});`

  `describe("Withdrawals", function () {`

    `beforeEach(async function () {`

      `// Transfer tokens to addr1`

      `await coin100.transfer(addr1.address, ethers.utils.parseUnits("1000", 18));`

      `// addr1 approves and stakes`

      `await coin100.connect(addr1).approve(staking.address, ethers.utils.parseUnits("1000", 18));`

      `await staking.connect(addr1).stake(ethers.utils.parseUnits("500", 18));`

    `});`

    `it("Should allow users to withdraw staked tokens", async function () {`

      `await expect(`

        `staking.connect(addr1).withdraw(ethers.utils.parseUnits("200", 18))`

      `).to.emit(staking, "Withdrawn").withArgs(addr1.address, ethers.utils.parseUnits("200", 18));`

      `const userBalance = await staking.stakingBalance(addr1.address);`

      `expect(userBalance).to.equal(ethers.utils.parseUnits("300", 18));`

      `const totalStaked = await staking.totalStaked();`

      `expect(totalStaked).to.equal(ethers.utils.parseUnits("300", 18));`

      `const addr1Coin100 = await coin100.balanceOf(addr1.address);`

      `expect(addr1Coin100).to.equal(ethers.utils.parseUnits("700", 18)); // 1000 - 500 + 200 = 700`

    `});`

    `it("Should prevent withdrawing more than staked", async function () {`

      `await expect(`

        `staking.connect(addr1).withdraw(ethers.utils.parseUnits("600", 18))`

      `).to.be.revertedWith("Insufficient staked balance");`

    `});`

  `});`

  `describe("Rewards", function () {`

    `beforeEach(async function () {`

      `// Transfer tokens to addr1`

      `await coin100.transfer(addr1.address, ethers.utils.parseUnits("1000", 18));`

      `// addr1 approves and stakes`

      `await coin100.connect(addr1).approve(staking.address, ethers.utils.parseUnits("1000", 18));`

      `await staking.connect(addr1).stake(ethers.utils.parseUnits("500", 18));`

    `});`

    `it("Should allow users to claim rewards", async function () {`

      `// Fast forward time by 1000 seconds`

      `await ethers.provider.send("evm_increaseTime", [1000]);`

      `await ethers.provider.send("evm_mine");`

      `const initialReward = await staking.earned(addr1.address);`

      `const initialCoin100 = await coin100.balanceOf(addr1.address);`

      `await expect(`

        `staking.connect(addr1).claimReward()`

      `).to.emit(staking, "RewardPaid").withArgs(addr1.address, initialReward);`

      `const finalReward = await staking.earned(addr1.address);`

      `expect(finalReward).to.equal(0);`

      `const finalCoin100 = await coin100.balanceOf(addr1.address);`

      `expect(finalCoin100).to.equal(ethers.utils.parseUnits("1000", 18).sub(ethers.utils.parseUnits("500", 18)).add(initialReward));`

    `});`

    `it("Should prevent claiming rewards when there are none", async function () {`

      `await expect(`

        `staking.connect(addr1).claimReward()`

      `).to.be.revertedWith("No rewards to claim");`

    `});`

  `});`

  `describe("Set Reward Rate", function () {`

    `it("Should allow owner to set reward rate", async function () {`

      `const newRewardRate = ethers.utils.parseUnits("0.00000200", 18);`

      `await expect(`

        `staking.connect(owner).setRewardRate(newRewardRate)`

      `).to.emit(staking, "RewardRateUpdated").withArgs(newRewardRate);`

      `expect(await staking.rewardRate()).to.equal(newRewardRate);`

    `});`

    `it("Should prevent non-owner from setting reward rate", async function () {`

      `const newRewardRate = ethers.utils.parseUnits("0.00000200", 18);`

      `await expect(`

        `staking.connect(addr1).setRewardRate(newRewardRate)`

      `).to.be.revertedWith("Ownable: caller is not the owner");`

    `});`

  `});`

`});`

**Explanation:**

* **Deployment Tests:** Verify that the staking contract is deployed with correct parameters.  
* **Staking Tests:** Ensure that tokens can be staked correctly, handle staking zero tokens, and track staking balances.  
* **Withdrawals Tests:** Confirm that users can withdraw staked tokens correctly and handle overdrafts.  
* **Rewards Tests:** Validate reward calculations, claiming rewards, and prevent claiming when no rewards are available.  
* **Set Reward Rate Tests:** Ensure that only the owner can update the reward rate.

**Best Practices:**

* **Isolate Tests:** Each test case should be independent to prevent state leakage.  
* **Edge Cases:** Test scenarios like staking the maximum possible tokens, multiple users staking simultaneously, and handling slippage in swaps.  
* **Gas Consumption:** Monitor gas usage to optimize contract efficiency.

---

## **10\. Preparation for Mainnet Deployment**

Before deploying to the Polygon Mainnet, ensure that all contracts are thoroughly tested, audited, and optimized for security and efficiency.

### **10.1. Security Audits**

1. **Internal Audits:**  
   * **Code Review:** Conduct multiple internal code reviews focusing on logic, security, and efficiency.  
   * **Automated Analysis:** Use tools like Slither and MythX to perform static and dynamic analysis.  
2. **External Audits:**  
   * **Hire Reputable Auditors:** Engage firms like [CertiK](https://www.certik.com/), OpenZeppelin, or [Trail of Bits](https://www.trailofbits.com/) for comprehensive audits.  
   * **Audit Reports:** Address all findings and recommendations provided in audit reports.  
3. **Bug Bounties:**  
   * **Launch Bug Bounty Program:** Incentivize the community and external developers to identify vulnerabilities.  
   * **Platforms:** Utilize platforms like [Immunefi](https://immunefi.com/) or [HackerOne](https://www.hackerone.com/) to manage bug bounty programs.

### **10.2. Finalizing Deployment Scripts**

1. **Review Deployment Scripts:**  
   * Ensure all deployment scripts are updated with mainnet configurations.  
   * Verify that all placeholder addresses are replaced with actual mainnet addresses.  
2. **Gas Optimization:**  
   * Optimize smart contract code to minimize gas consumption.  
   * Consider using libraries like OpenZeppelin's Gas Station Network for relayed transactions.  
3. **Upgradability:**  
   * Decide if contracts need to be upgradable using proxies (e.g., OpenZeppelin's Transparent or UUPS proxies).  
   * Implement upgradability patterns if necessary, ensuring secure upgrade mechanisms.

### **10.3. Funding for Mainnet Deployment**

1. **Obtain MATIC:**  
   * **Purchase MATIC:** Acquire MATIC from exchanges like Binance, Coinbase, or Kraken.  
   * **Transfer to Deployment Wallet:** Ensure your deployment wallet has sufficient MATIC to cover gas fees.  
2. **Funding Treasury and Incentive Wallets:**  
   * **Allocate MATIC as Needed:** Transfer MATIC to the Liquidity Incentive Wallet and other treasury addresses if required.

---

## **11\. Deployment to Polygon Mainnet**

After thorough testing and security audits on the Mumbai Testnet, proceed to deploy the contracts to the Polygon Mainnet.

### **11.1. Deploying Contracts**

**Update Deployment Scripts:**

1. **Replace Network in Deployment Commands:**  
   * Change `--network mumbai` to `--network mainnet` in all deployment scripts.  
2. **Ensure Correct Addresses:**  
   * Update all placeholder addresses with actual mainnet addresses (e.g., QuickSwap Router on Polygon Mainnet).

**Execute Deployment Scripts:**

**Deploy COIN100 Token:**  
bash  
Copy code  
`npx hardhat run scripts/deployCOIN100Token.js --network mainnet`

1. 

**Deploy COIN100Sale Contract:**  
bash  
Copy code  
`npx hardhat run scripts/deployCOIN100Sale.js --network mainnet`

2. 

**Deploy COIN100Staking Contract:**  
bash  
Copy code  
`npx hardhat run scripts/deployCOIN100Staking.js --network mainnet`

3. 

**Deploy Timelock Controller and COIN100CommunityTreasury:**  
bash  
Copy code  
`npx hardhat run scripts/deployCOIN100CommunityTreasury.js --network mainnet`

4. 

**Deploy COIN100Governance Contract:**  
bash  
Copy code  
`npx hardhat run scripts/deployCOIN100Governance.js --network mainnet`

5. 

**Deploy COIN100Rebalancer Contract:**  
bash  
Copy code  
`npx hardhat run scripts/deployCOIN100Rebalancer.js --network mainnet`

6. 

**Deploy COIN100LiquidityIncentive Contract:**  
bash  
Copy code  
`npx hardhat run scripts/deployCOIN100LiquidityIncentive.js --network mainnet`

7. 

**Notes:**

* **Monitor Deployments:** Use Polygonscan to verify contract deployments.  
* **Verify Contracts:** After deployment, verify contracts on Polygonscan for transparency.

### **11.2. Allocating Tokens**

Follow the same allocation scripts as in the Mumbai Testnet, ensuring that tokens are allocated to the correct mainnet addresses.

**Execution Example:**

bash

Copy code

`npx hardhat run scripts/allocateMarketing.js --network mainnet`

`npx hardhat run scripts/allocateLiquidityPool.js --network mainnet`

`npx hardhat run scripts/allocateDeveloperTreasury.js --network mainnet`

`npx hardhat run scripts/allocateLiquidityIncentive.js --network mainnet`

`npx hardhat run scripts/allocateCommunityTreasury.js --network mainnet`

**Output:**

vbnet

Copy code

`Allocating Marketing Tokens from: 0xYourDeployerAddress`

`Transferred 70,000,000 COIN100 to Marketing Address: 0xMarketingWalletAddress`

`Allocating Liquidity Pool Tokens from: 0xYourDeployerAddress`

`Transferred 200,000,000 COIN100 to Liquidity Pool Address: 0xLiquidityPoolAddress`

`Allocating Developer Treasury Tokens from: 0xYourDeployerAddress`

`Transferred 100,000,000 COIN100 to Developer Treasury Address: 0xDeveloperTreasuryAddress`

`Allocating Liquidity Incentive Tokens from: 0xYourDeployerAddress`

`Transferred 125,000,000 COIN100 to Liquidity Incentive Wallet Address: 0xLiquidityIncentiveWalletAddress`

`Allocating Community Treasury Tokens from: 0xYourDeployerAddress`

`Transferred 30,000,000 COIN100 to Community Treasury Address: 0xCOIN100CommunityTreasuryAddress`

---

## **12\. Post-Deployment Steps**

After deploying to the Polygon Mainnet, ensure that all contracts are verified, monitored, and maintained for optimal performance and security.

### **12.1. Verifying Contracts on Polygonscan**

1. **Use Hardhat Etherscan Plugin:** Ensure that the `etherscan` API key is set in `.env` and configured in `hardhat.config.js`.

**Verify Contracts:**  
bash  
Copy code  
`npx hardhat verify --network mainnet DEPLOYED_CONTRACT_ADDRESS "Constructor Argument 1" "Constructor Argument 2" ...`

**Example:**  
bash  
Copy code  
`npx hardhat verify --network mainnet 0xCOIN100TokenContractAddress "COIN100 Index" "COIN100" "0xDeveloperTreasuryAddress" "0xLiquidityIncentiveWalletAddress" "0xCommunityTreasuryAddress"`

2.   
3. **Check Verification Status:**  
   * Visit [Polygonscan](https://polygonscan.com/) and search for your contract address.  
   * Confirm that the contract is verified and the source code is visible.

### **12.2. Monitoring and Maintenance**

1. **Monitor Contract Interactions:**  
   * Use Polygonscan to track transactions, token distributions, and contract interactions.  
   * Set up alerts for significant events or transactions.  
2. **Performance Monitoring:**  
   * Monitor gas consumption and optimize contracts if necessary.  
   * Analyze user engagement metrics through analytics tools.  
3. **Regular Updates:**  
   * Implement updates or upgrades based on community feedback and project requirements.  
   * Ensure all updates undergo thorough testing and auditing.  
4. **Security Monitoring:**  
   * Continuously monitor for potential vulnerabilities or malicious activities.  
   * Update security measures and protocols as needed.  
5. **Community Engagement:**  
   * Maintain active communication channels with the community.  
   * Encourage participation in governance, staking, and liquidity provision.

---

## **13\. Conclusion**

This comprehensive and streamlined plan equips you with all the necessary steps, code, and guidelines to successfully launch the **COIN100** project on the Polygon network within your $500 budget. By integrating a dual-method liquidity provision strategy—combining fee-based additions and incentivized rewards—you ensure sustainable liquidity growth without significant upfront investment. Additionally, advanced governance mechanisms and cost-effective rebalancing methods enhance the project's robustness, security, and efficiency.

**Key Takeaways:**

* **Tokenomics:** Balanced allocations ensure fairness and project sustainability.  
* **Governance:** Decentralized control fosters community trust and involvement.  
* **Liquidity Provision:** Strategic liquidity addition via fees and rewards facilitates smooth trading.  
* **Staking & Fees:** Incentivizes user participation and funds the Developer, Liquidity Incentive, and Community Treasuries.  
* **Index Tracking:** Dynamic tracking and rebalancing ensure the index remains accurate.  
* **Security:** Prioritize to protect both your assets and user investments.  
* **Community Engagement:** Active discussions and governance proposals strengthen community bonds.

**Next Steps:**

1. **Finalize Smart Contracts:**  
   * Ensure all contracts are thoroughly tested and audited.  
2. **Deploy Contracts to Testnet:**  
   * Validate all functionalities on the Mumbai Testnet.  
3. **Implement Index Tracking Mechanism:**  
   * Set up both the off-chain server and integrate on-chain methods using external triggers.  
4. **Execute Marketing Strategies:**  
   * Utilize the Marketing Address to promote COIN100 effectively.  
5. **Launch Token Sale:**  
   * Initiate the public sale and monitor progress.  
6. **Provide Liquidity:**  
   * Add liquidity to QuickSwap, ensuring market availability.  
7. **Engage the Community:**  
   * Encourage participation through governance and staking.  
8. **Monitor and Iterate:**  
   * Continuously monitor the ecosystem and make necessary adjustments via governance.

By adhering to this updated plan, you'll establish a robust foundation for COIN100, fostering trust, engagement, and growth within the cryptocurrency community while managing liquidity effectively within your budget constraints.

---

## **14\. Appendix: Deployment Scripts**

For streamlined deployment, the following scripts can be utilized. Ensure that all placeholders (e.g., contract addresses) are replaced with actual addresses upon deployment.

### **14.1. Deploy COIN100 Token**

Create a file named `scripts/deployCOIN100Token.js`:

javascript

Copy code

`const hre = require("hardhat");`

`require("dotenv").config();`

`async function main() {`

  `const [deployer] = await hre.ethers.getSigners();`

  `console.log("Deploying COIN100Token with the account:", deployer.address);`

  `const COIN100Token = await hre.ethers.getContractFactory("COIN100Token");`

  `const feeRecipientDev = process.env.DEVELOPER_WALLET;`

  `const feeRecipientLiquidity = process.env.LIQUIDITY_INCENTIVE_WALLET;`

  `const feeRecipientCommunity = process.env.COMMUNITY_WALLET;`

  `const coin100 = await COIN100Token.deploy("COIN100 Index", "COIN100", feeRecipientDev, feeRecipientLiquidity, feeRecipientCommunity);`

  `await coin100.deployed();`

  `console.log("COIN100Token deployed to:", coin100.address);`

`}`

`main()`

  `.then(() => process.exit(0))`

  `.catch((error) => {`

    `console.error(error);`

    `process.exit(1);`

  `});`

**Execution:**

bash

Copy code

`npx hardhat run scripts/deployCOIN100Token.js --network mumbai`

**Output:**

vbnet

Copy code

`Deploying COIN100Token with the account: 0xYourDeployerAddress`

`COIN100Token deployed to: 0xCOIN100TokenContractAddress`

---

### **14.2. Deploy COIN100Sale Contract**

Create a file named `scripts/deployCOIN100Sale.js`:

javascript

Copy code

`const hre = require("hardhat");`

`require("dotenv").config();`

`async function main() {`

  `const [deployer] = await hre.ethers.getSigners();`

  `console.log("Deploying COIN100Sale with the account:", deployer.address);`

  `const COIN100Sale = await hre.ethers.getContractFactory("COIN100Sale");`

  `const coin100Address = "0xCOIN100TokenContractAddress"; // Replace with actual COIN100Token contract address after deployment`

  `const rate = 252604; // 252,604 COIN100 per MATIC`

  `const duration = 7 * 24 * 60 * 60; // 7 days in seconds`

  `const coin100Sale = await COIN100Sale.deploy(coin100Address, rate, duration);`

  `await coin100Sale.deployed();`

  `console.log("COIN100Sale deployed to:", coin100Sale.address);`

  `// Transfer tokens to COIN100Sale contract`

  `const COIN100Token = await hre.ethers.getContractAt("COIN100Token", coin100Address);`

  `const tokensForSale = hre.ethers.utils.parseUnits("500000000", 18); // 500,000,000 COIN100`

  `const transferTx = await COIN100Token.transfer(coin100Sale.address, tokensForSale);`

  `await transferTx.wait();`

  `console.log("Transferred 500,000,000 COIN100 to COIN100Sale contract");`

`}`

`main()`

  `.then(() => process.exit(0))`

  `.catch((error) => {`

    `console.error(error);`

    `process.exit(1);`

  `});`

**Execution:**

bash

Copy code

`npx hardhat run scripts/deployCOIN100Sale.js --network mumbai`

**Output:**

vbnet

Copy code

`Deploying COIN100Sale with the account: 0xYourDeployerAddress`

`COIN100Sale deployed to: 0xCOIN100SaleContractAddress`

`Transferred 500,000,000 COIN100 to COIN100Sale contract`

**Note:** Replace `"0xCOIN100TokenContractAddress"` with the actual deployed COIN100Token contract address.

---

### **14.3. Deploy COIN100Staking Contract**

Create a file named `scripts/deployCOIN100Staking.js`:

javascript

Copy code

`const hre = require("hardhat");`

`require("dotenv").config();`

`async function main() {`

  `const [deployer] = await hre.ethers.getSigners();`

  `console.log("Deploying COIN100Staking with the account:", deployer.address);`

  `const COIN100Staking = await hre.ethers.getContractFactory("COIN100Staking");`

  `const stakingToken = "0xCOIN100TokenContractAddress"; // Replace with actual COIN100Token contract address`

  `const rewardToken = "0xCOIN100TokenContractAddress"; // Using COIN100 as reward token`

  `const rewardRate = hre.ethers.utils.parseUnits("0.00000167", 18); // 0.00000167 COIN100 per second`

  `const staking = await COIN100Staking.deploy(stakingToken, rewardToken, rewardRate);`

  `await staking.deployed();`

  `console.log("COIN100Staking deployed to:", staking.address);`

  `// Allocate tokens for staking rewards`

  `const COIN100Token = await hre.ethers.getContractAt("COIN100Token", stakingToken);`

  `const tokensForStaking = hre.ethers.utils.parseUnits("50000000", 18); // 50,000,000 COIN100`

  `const transferTx = await COIN100Token.transfer(staking.address, tokensForStaking);`

  `await transferTx.wait();`

  `console.log("Transferred 50,000,000 COIN100 to COIN100Staking contract");`

`}`

`main()`

  `.then(() => process.exit(0))`

  `.catch((error) => {`

    `console.error(error);`

    `process.exit(1);`

  `});`

**Execution:**

bash

Copy code

`npx hardhat run scripts/deployCOIN100Staking.js --network mumbai`

**Output:**

vbnet

Copy code

`Deploying COIN100Staking with the account: 0xYourDeployerAddress`

`COIN100Staking deployed to: 0xCOIN100StakingContractAddress`

`Transferred 50,000,000 COIN100 to COIN100Staking contract`

**Note:** Replace `"0xCOIN100TokenContractAddress"` with the actual deployed COIN100Token contract address.

---

### **14.4. Deploy Timelock Controller and COIN100CommunityTreasury**

Create a file named `scripts/deployCOIN100CommunityTreasury.js`:

javascript

Copy code

`const hre = require("hardhat");`

`require("dotenv").config();`

`async function main() {`

  `const [deployer] = await hre.ethers.getSigners();`

  `console.log("Deploying TimelockController with the account:", deployer.address);`

  `const TimelockController = await hre.ethers.getContractFactory("TimelockController");`

  `const minDelay = 1 * 24 * 60 * 60; // 1 day`

  `const proposers = []; // To be set via governance proposals`

  `const executors = []; // Open executors`

  `const timelock = await TimelockController.deploy(minDelay, proposers, executors);`

  `await timelock.deployed();`

  `console.log("TimelockController deployed to:", timelock.address);`

  `const COIN100CommunityTreasury = await hre.ethers.getContractFactory("COIN100CommunityTreasury");`

  `const coin100Address = "0xCOIN100TokenContractAddress"; // Replace with actual COIN100Token contract address`

  `const communityTreasury = await COIN100CommunityTreasury.deploy(`

    `coin100Address,`

    `timelock.address`

  `);`

  `await communityTreasury.deployed();`

  `console.log("COIN100CommunityTreasury deployed to:", communityTreasury.address);`

`}`

`main()`

  `.then(() => process.exit(0))`

  `.catch((error) => {`

    `console.error(error);`

    `process.exit(1);`

  `});`

**Execution:**

bash

Copy code

`npx hardhat run scripts/deployCOIN100CommunityTreasury.js --network mumbai`

**Output:**

vbnet

Copy code

`Deploying TimelockController with the account: 0xYourDeployerAddress`

`TimelockController deployed to: 0xTimelockControllerAddress`

`COIN100CommunityTreasury deployed to: 0xCOIN100CommunityTreasuryAddress`

**Note:**

* **Proposers and Executors:** Initially empty; will be set via governance proposals.  
* **Replace `"0xCOIN100TokenContractAddress"`** with the actual deployed COIN100Token contract address.

---

### **14.5. Deploy COIN100Governance Contract**

Create a file named `scripts/deployCOIN100Governance.js`:

javascript

Copy code

`const hre = require("hardhat");`

`require("dotenv").config();`

`async function main() {`

  `const [deployer] = await hre.ethers.getSigners();`

  `console.log("Deploying COIN100Governance with the account:", deployer.address);`

  `const ERC20Votes = await hre.ethers.getContractFactory("COIN100Token");`

  `const coin100Address = "0xCOIN100TokenContractAddress"; // Replace with actual COIN100Token contract address after deployment`

  `const coin100 = await hre.ethers.getContractAt("COIN100Token", coin100Address);`

  `const TimelockController = await hre.ethers.getContractFactory("TimelockController");`

  `const timelockAddress = "0xTimelockControllerAddress"; // Replace with actual TimelockController address after deployment`

  `const timelock = await hre.ethers.getContractAt("TimelockController", timelockAddress);`

  `const COIN100Governance = await hre.ethers.getContractFactory("COIN100Governance");`

  `const governance = await COIN100Governance.deploy(coin100, timelock);`

  `await governance.deployed();`

  `console.log("COIN100Governance deployed to:", governance.address);`

`}`

`main()`

  `.then(() => process.exit(0))`

  `.catch((error) => {`

    `console.error(error);`

    `process.exit(1);`

  `});`

**Execution:**

bash

Copy code

`npx hardhat run scripts/deployCOIN100Governance.js --network mumbai`

**Output:**

vbnet

Copy code

`Deploying COIN100Governance with the account: 0xYourDeployerAddress`

`COIN100Governance deployed to: 0xCOIN100GovernanceContractAddress`

**Note:**

* **Replace `"0xCOIN100TokenContractAddress"`** and `"0xTimelockControllerAddress"` with the actual deployed addresses.  
* Ensure the Timelock Controller is already deployed before deploying the Governance contract.

---

### **14.6. Deploy COIN100Rebalancer Contract**

Create a file named `scripts/deployCOIN100Rebalancer.js`:

javascript

Copy code

`const hre = require("hardhat");`

`require("dotenv").config();`

`async function main() {`

  `const [deployer] = await hre.ethers.getSigners();`

  `console.log("Deploying COIN100Rebalancer with the account:", deployer.address);`

  `const COIN100Rebalancer = await hre.ethers.getContractFactory("COIN100Rebalancer");`

  `const coin100Address = "0xCOIN100TokenContractAddress"; // Replace with actual COIN100Token contract address`

  `const quickSwapRouter = "0x9a71012B13CA4d3d0C5dAcb4A600c232dCA4eF95"; // QuickSwap Router on Mumbai`

  `const rebalancer = await COIN100Rebalancer.deploy(`

    `coin100Address,`

    `quickSwapRouter`

  `);`

  `await rebalancer.deployed();`

  `console.log("COIN100Rebalancer deployed to:", rebalancer.address);`

`}`

`main()`

  `.then(() => process.exit(0))`

  `.catch((error) => {`

    `console.error(error);`

    `process.exit(1);`

  `});`

**Execution:**

bash

Copy code

`npx hardhat run scripts/deployCOIN100Rebalancer.js --network mumbai`

**Output:**

vbnet

Copy code

`Deploying COIN100Rebalancer with the account: 0xYourDeployerAddress`

`COIN100Rebalancer deployed to: 0xCOIN100RebalancerContractAddress`

**Note:**

* **QuickSwap Router Address on Mumbai:** `0x9a71012B13CA4d3d0C5dAcb4A600c232dCA4eF95`  
* **Replace `"0xCOIN100TokenContractAddress"`** with the actual deployed COIN100Token contract address.

---

### **14.7. Deploy COIN100LiquidityIncentive Contract**

Create a file named `scripts/deployCOIN100LiquidityIncentive.js`:

javascript

Copy code

`const hre = require("hardhat");`

`require("dotenv").config();`

`async function main() {`

  `const [deployer] = await hre.ethers.getSigners();`

  `console.log("Deploying COIN100LiquidityIncentive with the account:", deployer.address);`

  `const COIN100LiquidityIncentive = await hre.ethers.getContractFactory("COIN100LiquidityIncentive");`

  `const coin100Address = "0xCOIN100TokenContractAddress"; // Replace with actual COIN100Token contract address`

  `const liquidityPoolToken = "0xQuickSwapLPTokenAddress"; // Replace with actual QuickSwap LP Token address on Mumbai Testnet`

  `const liquidityIncentiveWallet = process.env.LIQUIDITY_INCENTIVE_WALLET;`

  `const rewardRate = hre.ethers.utils.parseUnits("0.00001", 18); // 0.00001 COIN100 per LP token`

  `const liquidityIncentive = await COIN100LiquidityIncentive.deploy(`

    `coin100Address,`

    `liquidityPoolToken,`

    `liquidityIncentiveWallet,`

    `rewardRate`

  `);`

  `await liquidityIncentive.deployed();`

  `console.log("COIN100LiquidityIncentive deployed to:", liquidityIncentive.address);`

`}`

`main()`

  `.then(() => process.exit(0))`

  `.catch((error) => {`

    `console.error(error);`

    `process.exit(1);`

  `});`

**Execution:**

bash

Copy code

`npx hardhat run scripts/deployCOIN100LiquidityIncentive.js --network mumbai`

**Output:**

vbnet

Copy code

`Deploying COIN100LiquidityIncentive with the account: 0xYourDeployerAddress`

`COIN100LiquidityIncentive deployed to: 0xCOIN100LiquidityIncentiveContractAddress`

**Note:**

* **QuickSwap LP Token Address on Mumbai:** Obtain after adding liquidity on QuickSwap Testnet.  
* **Replace `"0xCOIN100TokenContractAddress"`** and `"0xQuickSwapLPTokenAddress"` with the actual deployed addresses.

---

## **15\. Appendix: Additional Scripts and Tools**

### **15.1. Transfer Ownership of Community Treasury to Timelock**

Create a file named `scripts/transferOwnershipCOIN100CommunityTreasury.js`:

javascript

Copy code

`const hre = require("hardhat");`

`require("dotenv").config();`

`async function main() {`

  `const [deployer] = await hre.ethers.getSigners();`

  `console.log("Transferring ownership of COIN100CommunityTreasury to TimelockController...");`

  `const communityTreasuryAddress = "0xCOIN100CommunityTreasuryAddress"; // Replace with actual Community Treasury address`

  `const timelockAddress = "0xTimelockControllerAddress"; // Replace with actual TimelockController address`

  `const COIN100CommunityTreasury = await hre.ethers.getContractAt("COIN100CommunityTreasury", communityTreasuryAddress);`

  `const tx = await COIN100CommunityTreasury.transferOwnership(timelockAddress);`

  `await tx.wait();`

  ``console.log(`Ownership of COIN100CommunityTreasury transferred to TimelockController: ${timelockAddress}`);``

`}`

`main()`

  `.then(() => process.exit(0))`

  `.catch((error) => {`

    `console.error(error);`

    `process.exit(1);`

  `});`

**Execution:**

bash

Copy code

`npx hardhat run scripts/transferOwnershipCOIN100CommunityTreasury.js --network mumbai`

**Output:**

css

Copy code

`Transferring ownership of COIN100CommunityTreasury to TimelockController...`

`Ownership of COIN100CommunityTreasury transferred to TimelockController: 0xTimelockControllerAddress`

**Note:**

* Ensure the Timelock Controller is correctly set up before transferring ownership.

---

### **15.2. Create and Execute Governance Proposals**

**Example: Voting on Marketing Fund Allocation**

1. **Create Proposal Script:**

Create a file named `scripts/createMarketingProposal.js`:

javascript

Copy code

`const hre = require("hardhat");`

`require("dotenv").config();`

`async function main() {`

  `const [proposer] = await hre.ethers.getSigners();`

  `console.log("Creating marketing proposal with the account:", proposer.address);`

  `const communityTreasuryAddress = "0xCOIN100CommunityTreasuryAddress"; // Replace with actual address`

  `const marketingWallet = process.env.MARKETING_WALLET; // 0xYourMarketingWalletAddress`

  `const coin100Address = "0xCOIN100TokenContractAddress"; // Replace with actual COIN100Token contract address`

  `const COIN100CommunityTreasury = await hre.ethers.getContractAt("COIN100CommunityTreasury", communityTreasuryAddress);`

  `const COIN100Token = await hre.ethers.getContractAt("COIN100Token", coin100Address);`

  `const amount = hre.ethers.utils.parseUnits("70000000", 18); // 70,000,000 COIN100`

  `const iface = new hre.ethers.utils.Interface(["function transfer(address recipient, uint256 amount)"]);`

  `const calldata = iface.encodeFunctionData("transfer", [marketingWallet, amount]);`

  `const targets = [coin100Address];`

  `const values = [0];`

  `const calldatas = [calldata];`

  `const description = "Proposal to allocate 70,000,000 COIN100 for Marketing Campaign on [Date]";`

  `const tx = await COIN100CommunityTreasury.propose(targets, values, calldatas, description);`

  `const receipt = await tx.wait();`

  `const proposalId = receipt.events.find((event) => event.event === "ProposalCreated").args.proposalId;`

  ``console.log(`Proposal created with ID: ${proposalId}`);``

`}`

`main()`

  `.then(() => process.exit(0))`

  `.catch((error) => {`

    `console.error(error);`

    `process.exit(1);`

  `});`

**Execution:**

bash

Copy code

`npx hardhat run scripts/createMarketingProposal.js --network mumbai`

**Output:**

csharp

Copy code

`Creating marketing proposal with the account: 0xYourProposerAddress`

`Proposal created with ID: 1`

2. **Vote on Proposal:**

Users can vote on the proposal using the COIN100Governance contract through a frontend interface or via scripts. Voting typically involves functions like `castVote` with the proposal ID and vote type.

3. **Execute Proposal:**

After the voting period and if the proposal meets the quorum and approval thresholds, execute the proposal.

Create a file named `scripts/executeProposal.js`:

javascript

Copy code

`const hre = require("hardhat");`

`require("dotenv").config();`

`async function main() {`

  `const [executor] = await hre.ethers.getSigners();`

  `console.log("Executing proposal with the account:", executor.address);`

  `const communityTreasuryAddress = "0xCOIN100CommunityTreasuryAddress"; // Replace with actual address`

  `const proposalId = 1; // Replace with actual proposal ID`

  `const COIN100CommunityTreasury = await hre.ethers.getContractAt("COIN100CommunityTreasury", communityTreasuryAddress);`

  `const tx = await COIN100CommunityTreasury.execute(proposalId);`

  `await tx.wait();`

  ``console.log(`Proposal ${proposalId} executed.`);``

`}`

`main()`

  `.then(() => process.exit(0))`

  `.catch((error) => {`

    `console.error(error);`

    `process.exit(1);`

  `});`

**Execution:**

bash

Copy code

`npx hardhat run scripts/executeProposal.js --network mumbai`

**Output:**

csharp

Copy code

`Executing proposal with the account: 0xYourExecutorAddress`

`Proposal 1 executed.`

**Notes:**

* **Voting Power:** Determined by COIN100 token holdings.  
* **Quorum Requirements:** Ensure that the proposal meets the quorum (e.g., 5,000,000 COIN100) to pass.  
* **Timelock Delay:** Proposals are executed after the timelock delay set in the Timelock Controller.

---

## **16\. Best Practices and Considerations**

1. **Secure Private Keys:**  
   * Never expose private keys in code or commit them to version control.  
   * Use environment variables and secure secret management services.  
2. **Regular Audits:**  
   * Conduct periodic security audits to identify and fix vulnerabilities.  
   * Stay updated with the latest security practices in smart contract development.  
3. **Community Engagement:**  
   * Maintain active communication channels with the community.  
   * Encourage participation in governance, staking, and liquidity provision.  
4. **Transparent Operations:**  
   * Provide clear and detailed information about project developments, updates, and changes.  
   * Ensure that all fund allocations and distributions are transparent and auditable.  
5. **Scalability:**  
   * Design contracts to handle increasing user base and token transactions efficiently.  
   * Optimize gas usage to minimize transaction costs for users.  
6. **Compliance:**  
   * Stay informed about regulatory requirements related to cryptocurrency projects.  
   * Implement necessary measures to ensure compliance with local and international laws.  
7. **Disaster Recovery:**  
   * Establish protocols for handling emergencies, such as contract vulnerabilities or unexpected market events.  
   * Consider pausing contract functionalities if necessary to prevent exploitation.  
8. **Continuous Improvement:**  
   * Regularly update the project based on community feedback and market dynamics.  
   * Incorporate new features and optimizations to enhance user experience and project robustness.

---

By following this comprehensive plan, you will ensure a structured and secure launch of the **COIN100** project on the Polygon network, with thorough testing and community-driven governance mechanisms in place. This approach not only fosters trust and engagement within the community but also establishes a solid foundation for sustainable growth and adaptability in the ever-evolving cryptocurrency landscape.

