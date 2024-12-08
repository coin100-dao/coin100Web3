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











ChatGPT can make mistakes. Check important info.