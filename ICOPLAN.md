# Coin100 ICO
High-Level Overview
Finalize Token Economics:
You already have a token that mints the entire supply to the owner at deployment. You want 3% for the developer (yourself) and the remaining 97% available for sale during the ICO. That’s straightforward: upon deploying the token, you get all tokens, you keep 3%, and send the remaining 97% to a dedicated “ICO” contract.

Create a Crowdsale (ICO) Smart Contract:
You’ll need a separate contract that:

Holds the 97% of tokens dedicated for sale.
Accepts contributions in MATIC (on Polygon), or another stablecoin if you prefer.
Distributes tokens to contributors at a set rate.
Keeps track of start time, end time, and possibly a hard cap and soft cap.
Allows the owner (you) to withdraw funds raised once the sale ends.
Set the ICO Parameters:

Token Price: Decide how many tokens per 1 MATIC (or per 1 USDC) you want to offer. For example, 1 MATIC could buy 1000 C100 tokens.
Sale Duration: Start and end time of the ICO.
Hard Cap and Soft Cap (Optional): A hard cap is the maximum amount you want to raise. A soft cap might be the minimum you want to raise before the sale is considered successful.
Vesting (Optional): Decide if tokens are immediately claimable by investors or if there is a vesting schedule.
Integrate With Your Website (coin100.link): You can build a front-end DApp that:

Connects via MetaMask or WalletConnect.
Displays token sale details: price, how many tokens available, how many sold, how to participate.
Provides a “Buy” button that sends a transaction to the crowdsale contract’s buyTokens() function.
Testing and Auditing:

Test on Polygon testnet (e.g., Mumbai) before mainnet.
Make sure you handle rounding, gas fees, and user experience issues.
Consider a code audit or a review by another developer.
Launch the ICO:

Deploy token contract.
Deploy crowdsale contract with the required parameters.
Transfer 97% of tokens from your owner address to the crowdsale contract.
Announce start time on your website and social channels.
Once the sale is over, finalize it and allow contributors to claim tokens if they weren’t immediately distributed.
Post-ICO:

Liquidity provisioning on a DEX.
Ongoing governance and community building.
Transition to the future governor contract as planned.
Detailed Step-by-Step Instructions
Step 1: Token Contract Modifications
Current State:
Your current token contract mints 100% of supply to the owner. Owner keeps 3% and presumably will use the remaining 97% for the ICO.

What to Change?

Actually, the token contract as posted might not need changes if all tokens are initially minted to the owner. You can simply perform these actions after deployment:
Deploy the token contract.
Owner (you) now has 100% of supply.
Keep 3% in your wallet.
Send 97% of tokens to the crowdsale contract once you deploy it.
Example:
If totalSupply = 1,000,000 C100 tokens, then 3% is 30,000 tokens you keep in your wallet. The remaining 970,000 tokens go to the ICO contract.

You don’t necessarily need to change the token code for the ICO, you just need to plan your distribution after the initial deployment. The token already supports transfer(), so after deploying the ICO contract, you do:

solidity
Copy code
// Pseudocode after deploying the ICO contract:
token.transfer(icoContractAddress, 970_000 ether);
(Note: Make sure to multiply by 1e18 if your token uses 18 decimals.)

Step 2: Creating the Crowdsale Contract
What is a Crowdsale Contract?
A Crowdsale contract holds tokens and sells them to contributors in exchange for MATIC or another currency. OpenZeppelin provides Crowdsale libraries for ERC20 tokens, but since you’re on Solidity 0.8 and likely using newer standards, you can write a simple contract or adapt an existing audited code.

Key Features of the Crowdsale Contract:

State Variables:
C100 token (the token you’re selling).
address payable owner (to withdraw funds).
uint256 rate (how many tokens per MATIC).
uint256 startTime and uint256 endTime.
bool finalized state, if needed.
Functions:
buyTokens() - users send MATIC, contract calculates amount of tokens to give, and records buyer’s contribution.
withdrawFunds() - after sale, owner can withdraw raised MATIC.
finalize() - ends the sale, possibly allows claiming tokens if they weren’t distributed immediately.
Example Parameters:

Suppose the initial price is 1 MATIC = 1,000 C100 tokens.
Start time: block.timestamp + 1 day (means it starts in 1 day).
End time: startTime + 30 days (ICO lasts 30 days).
No vesting: tokens sent immediately upon purchase.
Step 3: Deploying and Initializing Contracts
Deploy Token Contract (COIN100):

Deploy it with initialMarketCap parameter.
You have all tokens now.
Deploy Crowdsale Contract:

Constructor parameters: C100 tokenAddress, address payable wallet (your address), uint256 rate, uint256 startTime, uint256 endTime.
Once deployed, transfer 97% of tokens from your wallet to this contract.
Check Setup:

Verify the crowdsale contract token balance using token.balanceOf(icoContract).
Ensure the crowdsale contract’s startTime and endTime are correct.
Step 4: Integrating With Your Website (coin100.link)
Front-End Steps:

Use Web3 Libraries: Use Web3.js or ethers.js in your front-end.
Display ICO Info:
Current time, start time, end time.
Tokens per MATIC rate.
How many tokens are left.
Connect wallet button to let user connect MetaMask.
Buy Tokens Function:
User inputs how many MATIC they want to contribute.
On “Buy” click, your front-end calls icoContract.buyTokens({ value: userMATIC }).
After transaction confirms, user sees their new C100 balance in their wallet.
Example UI Flow:

User visits coin100.link.
They see “ICO Live Now! 1 MATIC = 1000 C100”.
They connect their wallet, see how many tokens are still available.
They input 2 MATIC and click “Buy”.
A MetaMask prompt appears. User confirms transaction.
After confirmation, they see their token balance update (the front-end calls token.balanceOf(user) to show new balance).
Step 5: Testing and Auditing
Test Locally: Use Hardhat or Truffle to run tests.
Test on Polygon Testnet (Mumbai):
Deploy token and crowdsale contracts to Mumbai.
Test buying tokens with a test wallet.
Check website integration on testnet.
Audit Code (Optional): Have another developer review the code for security issues.
Step 6: Running the ICO
Announce Your ICO on Social Media and Your Website:
State start and end times.
Publish token contract and crowdsale contract addresses.
At Start Time: The contract will start accepting contributions.
During ICO: Monitor the crowdsale, ensure everything runs smoothly.
After ICO Ends: Call finalize() function (if you implement one) to close the sale.
Withdraw Funds: Once finalized, you can withdrawFunds() to your owner wallet.
Step 7: Post-ICO Steps
Add liquidity to a DEX (like Quickswap) for C100/MATIC pair.
Continue community engagement and roadmap execution.
Move towards setting a governor contract for decentralized management.
Example Crowdsale Contract Changes
You might need a contract like this (just conceptual, not fully audited):

solidity
Copy code
// Pseudocode for a Crowdsale
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./COIN100.sol";

contract C100Crowdsale {
    COIN100 public token;
    address payable public owner;
    uint256 public rate; // tokens per 1 MATIC
    uint256 public startTime;
    uint256 public endTime;

    constructor(
        COIN100 _token,
        address payable _owner,
        uint256 _rate,
        uint256 _startTime,
        uint256 _endTime
    ) {
        require(_rate > 0, "Rate must be >0");
        require(_startTime < _endTime, "Invalid time range");
        token = _token;
        owner = _owner;
        rate = _rate;
        startTime = _startTime;
        endTime = _endTime;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier icoActive() {
        require(block.timestamp >= startTime && block.timestamp <= endTime, "Not ICO time");
        _;
    }

    function buyTokens() external payable icoActive {
        require(msg.value > 0, "Send MATIC");
        uint256 tokenAmount = msg.value * rate; 
        require(token.balanceOf(address(this)) >= tokenAmount, "Not enough tokens");
        token.transfer(msg.sender, tokenAmount);
    }

    function withdrawFunds() external onlyOwner {
        // After ICO ends
        require(block.timestamp > endTime, "ICO not ended");
        owner.transfer(address(this).balance);
    }
}
Note:

This is a simplified crowdsale contract. In a real scenario, you might add more features: refund if soft cap not met, finalize function, paused states, etc.
You also might integrate ERC20 stablecoins as the payment method instead of MATIC, in which case you’d allow buyTokens(USDC) and do some checks. But the principle is the same.
Summary
No Major Token Contract Changes Needed: Your token is good as is, just mint to owner at deployment.
Keep 3% as the developer allocation and move the remaining 97% to the ICO contract.
Implement a Crowdsale contract to handle ICO logic: rate, start time, end time, buy function.
Integrate the Crowdsale contract with your website: provide a user-friendly interface.
Test thoroughly before going live.