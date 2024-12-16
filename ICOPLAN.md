# COIN100 Deployment & ICO Execution Plan

## Table of Contents

1. [Introduction](#introduction)  
2. [Goals and Principles](#goals-and-principles)  
3. [Token Deployment](#token-deployment)  
   3.1. [Initial Token Parameters](#initial-token-parameters)  
   3.2. [Owner Allocation (3%)](#owner-allocation-3)  
   3.3. [Index Fund Concept Integration](#index-fund-concept-integration)  
4. [Public Sale (ICO) Deployment](#public-sale-ico-deployment)  
   4.1. [Defining ICO Parameters](#defining-ico-parameters)  
   4.2. [Accepted Payment Methods](#accepted-payment-methods)  
   4.3. [Initial polRate and Temporary Pricing](#initial-polrate-and-temporary-pricing)  
5. [Liquidity Pool Setup](#liquidity-pool-setup)  
   5.1. [C100/USDC Pool Creation](#c100usdc-pool-creation)  
   5.2. [C100/POL Pool Creation](#c100pol-pool-creation)  
   5.3. [Setting Pool Addresses in Contracts](#setting-pool-addresses-in-contracts)  
   5.4. [Fallback Logic (polInUSDCRate)](#fallback-logic-polinusdcrate)  
6. [Performing Initial Administrative Actions](#performing-initial-administrative-actions)  
   6.1. [Linking PublicSale to C100](#linking-publicsale-to-c100)  
   6.2. [Transferring Tokens to PublicSale](#transferring-tokens-to-publicsale)  
   6.3. [Setting Governor Contract (Optional)](#setting-governor-contract-optional)  
   6.4. [Adjusting Fees, Treasury, and LP Rewards](#adjusting-fees-treasury-and-lp-rewards)  
7. [Conducting the ICO](#conducting-the-ico)  
   7.1. [Marketing and Communication](#marketing-and-communication)  
   7.2. [Investor Participation](#investor-participation)  
   7.3. [Dynamic polRate Updates via Rebases](#dynamic-polrate-updates-via-rebases)  
8. [Rebase Operations During and After ICO](#rebase-operations-during-and-after-ico)  
   8.1. [Periodic Rebase Calls](#periodic-rebase-calls)  
   8.2. [Synchronizing polRate with PublicSale](#synchronizing-polrate-with-publicsale)  
   8.3. [Fallback Conditions if Liquidity is Insufficient](#fallback-conditions-if-liquidity-is-insufficient)  
9. [Post-ICO Finalization](#post-ico-finalization)  
   9.1. [Ending the ICO](#ending-the-ico)  
   9.2. [Burning Unsold Tokens](#burning-unsold-tokens)  
   9.3. [Transition to Post-ICO Market Phase](#transition-to-post-ico-market-phase)  
10. [Ongoing Maintenance](#ongoing-maintenance)  
    10.1. [Regular Market Cap Updates](#regular-market-cap-updates)  
    10.2. [Adjusting LP Pools, polInUSDCRate, or Fee Parameters](#adjusting-lp-pools-polinusdcrate-or-fee-parameters)  
    10.3. [Transparency and Community Involvement](#transparency-and-community-involvement)  
11. [Future Governance Introduction](#future-governance-introduction)  
    11.1. [Deploying Governor Contract Later](#deploying-governor-contract-later)  
    11.2. [Community Decision-Making and Voting](#community-decision-making-and-voting)  
    11.3. [Transitioning Control from Owner to Governance](#transitioning-control-from-owner-to-governance)  
12. [Chronological Checklist](#chronological-checklist)  
13. [Conclusion](#conclusion)

---

## Introduction
This document provides a comprehensive plan for deploying the COIN100 (C100) token, setting up a public sale (ICO), establishing liquidity pools for dynamic pricing (polRate), and handling ongoing maintenance and future governance transitions.

## Goals and Principles
- **Transparency:** Ensure every step is clear to stakeholders and investors.
- **Stability:** Dynamically reference on-chain liquidity pools to determine polRate.
- **Flexibility:** Allow fallback mechanisms and periodic adjustments to respond to market conditions.
- **Growth Path to Decentralized Governance:** Initially admin-driven, with plans to introduce community governance.

## Token Deployment

### Initial Token Parameters
- Deploy `COIN100(initialMarketCap, initialPolRate)`:
  - `initialMarketCap`: Sets the initial total supply.
  - `initialPolRate`: A starting polRate for the system before pools are established.
  
### Owner Allocation (3%)
- 3% of the total supply goes to the owner, with the remaining 97% also initially controlled by the owner’s account.
- The owner can decide how much to allocate to the PublicSale contract.

### Index Fund Concept Integration
- C100’s supply rebases daily/periodically to reflect changes in the top 100 crypto market cap.
- This underpins the token’s value proposition as an index tracker.

## Public Sale (ICO) Deployment

### Defining ICO Parameters
- Deploy `C100PublicSale(c100Address, treasury, startTime, endTime, initialPolRate)`.
- `startTime` and `endTime` define the ICO window.
- `treasury`: Where raised funds (POL and tokens) go.
- `initialPolRate`: Matches or closely aligns with the initial polRate set in C100.

### Accepted Payment Methods
- POL (chain’s native token, e.g., MATIC) and possibly USDC or other ERC20 tokens (set via `updateErc20Rate()`).

### Initial polRate and Temporary Pricing
- Until liquidity pools are set, rely on `initialPolRate`.
- Once pools are ready, `rebase()` will fetch live polRate from the pools.

## Liquidity Pool Setup

### C100/USDC Pool Creation
- On a DEX, create a C100/USDC pool to establish a stable reference price in USD terms.
- Add liquidity to target a desired initial price (e.g., $0.001 per C100).

### C100/POL Pool Creation
- Create a C100/POL pool to get a direct on-chain polRate (C100 per POL).
- Ensure sufficient liquidity for stable pricing.

### Setting Pool Addresses in Contracts
- Use `c100Contract.setC100USDCPool(...)` and `c100Contract.setC100POLPool(...)` to register pool addresses.
- The C100 contract will now have references to fetch prices.

### Fallback Logic (polInUSDCRate)
- If the C100/POL pool fails or lacks liquidity, fallback to C100/USDC combined with a known `polInUSDCRate`.
- Set `c100Contract.setPolInUSDCRate(...)` if using fallback logic.

## Performing Initial Administrative Actions

### Linking PublicSale to C100
- `c100Contract.setPublicSaleContract(publicSaleAddress)`
- This allows C100 to push updated polRate to PublicSale after each rebase.

### Transferring Tokens to PublicSale
- Transfer tokens to `publicSaleAddress` so it can sell to investors.
- `c100Contract.transfer(publicSaleAddress, tokensForSale)`

### Setting Governor Contract (Optional)
- If governance is planned:
  - `c100Contract.setGovernorContract(govContractAddress)`
  - `publicSaleContract.setGovernorContract(govContractAddress)`

### Adjusting Fees, Treasury, and LP Rewards
- `c100Contract.setTransferFeeParams(enabled, feeBasisPoints)`
- `c100Contract.updateTreasuryAddress(newTreasury)`
- `c100Contract.setLpRewardPercentage(percent)`

## Conducting the ICO

### Marketing and Communication
- Announce sale details and how to participate.
- Provide clarity on how polRate dynamically updates from pools.

### Investor Participation
- Investors buy C100 from PublicSale using POL or allowed tokens.
- As polRate updates at rebase, prices remain aligned with market conditions.

### Dynamic polRate Updates via Rebases
- Each `rebase(newMarketCap)` call in C100:
  - Fetches new polRate from pools.
  - Updates PublicSale polRate accordingly.
  - Adjusts total supply to reflect index changes.

## Rebase Operations During and After ICO

### Periodic Rebase Calls
- Likely daily or as per strategy.
- Reflects index growth or contraction.

### Synchronizing polRate with PublicSale
- Automatic in `rebase()`; no manual updates needed once pools are set.

### Fallback Conditions if Liquidity is Insufficient
- If no C100/POL liquidity:
  - Use C100/USDC + `polInUSDCRate`.
- If no pools at all, continue using last known polRate or consider reverting rebase until setup is corrected.

## Post-ICO Finalization

### Ending the ICO
- After `endTime`, call `publicSaleContract.finalize()`.
- No more purchases allowed.

### Burning Unsold Tokens
- Unsold tokens are burned (transferred to `0x...dEaD`) to reduce supply dilution.

### Transition to Post-ICO Market Phase
- The token now trades freely on DEXs.
- polRate updates continue with rebases, maintaining alignment with market-driven liquidity pools.

## Ongoing Maintenance

### Regular Market Cap Updates
- Keep feeding `newMarketCap` at each rebase.
- Maintain the index accuracy.

### Adjusting LP Pools, polInUSDCRate, or Fee Parameters
- If market changes, admin can:
  - Update fallback rate (`setPolInUSDCRate()`).
  - Change LP pools if needed.
  - Adjust fees or treasury address.

### Transparency and Community Involvement
- Communicate updates, rebase schedules, and rationale for changes.
- Eventually introduce more governance-driven decision-making.

## Future Governance Introduction

### Deploying Governor Contract Later
- Once ecosystem matures, deploy a governance contract.
- Transfer certain admin rights from owner to govContract.

### Community Decision-Making and Voting
- Token holders vote on proposals.
- Decide on LP reward percentages, fee adjustments, etc.

### Transitioning Control from Owner to Governance
- Gradually reduce owner’s influence.
- Enhance decentralization and community trust.

## Chronological Checklist
1. Deploy `COIN100` and `C100PublicSale` contracts.
2. Set PublicSale in C100.
3. Transfer tokens to PublicSale.
4. Create and fund C100/USDC and C100/POL pools.
5. Set pool addresses and optional fallback rate in C100.
6. Unpause if paused.
7. Start ICO at `startTime`; users buy tokens.
8. Rebase daily: updates polRate and reflects market cap.
9. After `endTime`, finalize ICO and burn unsold tokens.
10. Continue rebasing post-ICO. Introduce governance as project matures.

## Conclusion
This plan ensures a smooth, dynamic, and transparent deployment and ICO execution. By leveraging on-chain liquidity pools to determine polRate and providing a fallback mechanism, the system remains robust and adaptable. Over time, governance can transition from a centralized admin model to a community-driven process, aligning with industry best practices and the project’s long-term vision.
