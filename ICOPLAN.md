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


# Coin100 ICO
Revised ICO Strategy & Details
1. Unsold Tokens After ICO Ends
Scenario: Suppose your ICO runs for a full 12 months, and you intended to sell 97% of the supply but only 50% gets sold. This leaves 47% unsold.

Common Approaches:

Burn Unsold Tokens:
You can permanently remove the unsold tokens from circulation by calling the token’s internal burn function. This reduces supply and may help price stability and trust.

Roll Over Unsold Tokens to Treasury or Another Event:
Instead of burning, you could send the remaining tokens to a treasury wallet governed by the community or to a liquidity pool. This might be useful if you plan future initiatives, airdrops, or community grants.

Extend or Re-run the Sale:
You could allow governance (once established) to vote on what to do with these tokens: extending the sale period, burning them, or using them for other ecosystem growth strategies.

Choosing the Best Option:

Burning is the simplest and most transparent. It gives a signal of fairness since you don't flood the market later.
Storing them in a treasury for future community-led initiatives can be appealing once you have a governance system in place.
For now, let’s assume you’ll burn unsold tokens at the end of the sale if not sold.

2. Accepting Multiple Payment Methods (MATIC, USDC, etc.)
Your initial ICO contract only handled MATIC. To accept multiple tokens (like USDC, WETH, or other ERC20s):

Approach A: Single Crowdsale Contract with Multiple Functions

The crowdsale contract can have multiple buyTokens functions:
buyWithMATIC() - user sends MATIC directly.
buyWithToken(address token, uint256 amount) - user approves and transfers a specific ERC20 token (like USDC) to the crowdsale contract.
The contract then calculates how many C100 tokens to give based on a price feed or a fixed rate.
Key Considerations:

You need a pricing oracle or a predefined conversion rate for each accepted token. For example, if 1 MATIC = 1000 C100, you must decide what 1 USDC = in C100. If 1 USDC = $1 and you peg C100 to a $1 starting value, then 1 USDC might buy 1 C100.
If stable pricing is important, use a stable token like USDC for a straightforward ratio.
Make sure users have approved the crowdsale contract to spend their USDC before calling buyWithToken().
Approach B: Separate Crowdsale Contracts per Token

Deploy multiple versions of a crowdsale contract, each dedicated to a single payment token. This can be simpler to implement but more complex to manage.
Recommended Approach:

A single crowdsale contract with functions for each accepted token. You’ll store a mapping of acceptedTokens and their rates. For example:
acceptedTokens[MATIC_address] = 1000 C100 per MATIC
acceptedTokens[USDC_address] = 1 C100 per USDC (assuming $1 baseline)
Users call buyWithToken(USDC, usdcAmount) after approving the contract. The contract transfers in USDC, then sends C100 out accordingly.

3. Setting a Governor Contract for Decentralized Management
What is a Governor Contract?
A governance contract lets token holders propose and vote on changes. Eventually, after the ICO and initial phases, you want to transfer key privileges from the owner to a decentralized governance contract. This aligns with projects like Compound, Uniswap, and Aave that use on-chain governance.

Typical Governor Contract Structure (Using OpenZeppelin’s Governor):

A token with governance power (like C100) is used for voting.
A governance contract (like OpenZeppelin’s Governor contracts) allows:
Creating proposals (like “Burn the unsold tokens” or “Change the rebase parameters”).
Voting on proposals using token balances.
Executing proposals that pass.
Code Example (Simplified): Below is an extremely simplified version of what a governance contract might look like using OpenZeppelin templates. In reality, you’d import and extend OpenZeppelin’s Governor contracts.

solidity
Copy code
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/governance/Governor.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotesComp.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorTimelockControl.sol";

// Example: C100Governor
contract C100Governor is Governor, GovernorCountingSimple, GovernorVotesComp, GovernorTimelockControl {
    constructor(
        ERC20VotesComp _token,
        TimelockController _timelock
    )
        Governor("C100Governor")
        GovernorVotesComp(_token)
        GovernorTimelockControl(_timelock)
    {}

    function votingDelay() public pure override returns (uint256) {
        return 1; // 1 block
    }

    function votingPeriod() public pure override returns (uint256) {
        return 45818; // about 1 week in blocks
    }

    function quorum(uint256 blockNumber) public pure override returns (uint256) {
        return 10000e18; // require a certain threshold of tokens for quorum
    }

    function proposalThreshold() public pure override returns (uint256) {
        return 100e18; // minimum tokens to create a proposal
    }

    // The following functions are overrides required by Solidity.
    function state(uint256 proposalId) public view override(Governor, GovernorTimelockControl) returns (ProposalState) {
        return super.state(proposalId);
    }
    
    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public override(Governor) returns (uint256) {
        return super.propose(targets, values, calldatas, description);
    }
    
    function _execute(uint256 proposalId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes32 descriptionHash)
        internal
        override(Governor, GovernorTimelockControl)
    {
        super._execute(proposalId, targets, values, calldatas, descriptionHash);
    }
    
    function _cancel(address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes32 descriptionHash)
        internal
        override(Governor, GovernorTimelockControl)
    {
        super._cancel(targets, values, calldatas, descriptionHash);
    }
    
    function _executor() internal view override(Governor, GovernorTimelockControl) returns (address) {
        return super._executor();
    }
    
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(Governor, GovernorTimelockControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
How the Governor Works:

Token holders lock C100 tokens to gain voting power.
Anyone with enough voting power can propose changes.
The community votes on proposals.
If a proposal passes, the governor executes the changes (e.g., calling burnUnsoldTokens() on the crowdsale contract).
4. Deployment Order of Contracts
You don’t have to deploy all at once. Typically, the order is:

Token Contract (C100):
Deploy the token first. This gives you a token address.

Crowdsale (ICO) Contract:

After deploying the token, you know how many tokens you have.
Deploy the crowdsale contract with parameters: token address, start/end times, rate, etc.
Transfer 97% of tokens to the crowdsale contract.
Governor & Timelock (for Governance):

Governance usually comes later, once the ICO is complete and you have a community of token holders.
Deploy a TimelockController contract (a contract that enforces a delay on executing governance proposals).
Deploy the Governor contract passing the token and timelock.
Migrate owner privileges of your token (and possibly your treasury) to the timelock contract controlled by the governor once the community is ready.
Timeline Example:

At Start:

Deploy Token.
Deploy Crowdsale.
Transfer tokens to Crowdsale.
ICO runs for 12 months.
After ICO Ends:

Burn unsold tokens or transfer them to a treasury.
Add liquidity to a DEX.
Later (Months after ICO):

Deploy Timelock and Governor contracts.
Propose a vote in the community to transfer admin rights from the owner to the governance system.
After passing the proposal, the project is now governed by token holders.
5. Summary of the Revised Plan
After 12 months ICO ends with unsold tokens: Decide a policy—burn them or move them to a treasury for future use. Implement a finalize() function in the crowdsale contract that either burns the leftover tokens or transfers them to a treasury address.

Accepting Multiple Payment Methods:
Modify the crowdsale contract to:

Hold a mapping of paymentToken -> rate.
Implement buyWithMATIC() and buyWithToken(tokenAddress, amount) functions.
Handle approvals and token transfers for ERC20 payment tokens (like USDC).
Governor Contract for Decentralized Management:

After the ICO and initial phase, deploy a governor contract (like the one above) and a timelock.
Transfer ownership of critical contracts (like the token or treasury) to the timelock governed by the governor.
Token holders then control the system via proposals and votes.
Deployment Order:

Deploy Token
Deploy Crowdsale
Start ICO
End ICO, finalize outcomes
Later, deploy Governor and Timelock
Transfer control to governance as the project matures
This plan is more robust, addresses what to do with unsold tokens, how to handle multiple payment methods, and clarifies how and when to introduce governance for decentralized management. It also outlines the order of deployments and the evolving lifecycle of the project.


