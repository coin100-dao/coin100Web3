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
   4.3. [Initial C100 Price and Temporary Pricing](#initial-c100-price-and-temporary-pricing)  
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
   7.3. [Dynamic C100 Price Updates via Rebases](#dynamic-c100-price-updates-via-rebases)  
8. [Rebase Operations During and After ICO](#rebase-operations-during-and-after-ico)  
   8.1. [Periodic Rebase Calls](#periodic-rebase-calls)  
   8.2. [Synchronizing C100 Price with PublicSale](#synchronizing-c100-price-with-publicsale)  
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
13. [Post-Deployment Steps](#post-deployment-steps)  
    13.1. [Creating Liquidity Pools](#creating-liquidity-pools)  
    13.2. [Calculating Token Amounts for Initial Liquidity](#calculating-token-amounts-for-initial-liquidity)  
    13.3. [Adding Liquidity to Pools](#adding-liquidity-to-pools)  
    13.4. [Verifying and Managing Liquidity Pools](#verifying-and-managing-liquidity-pools)  
    13.5. [Additional Recommendations](#additional-recommendations)  
14. [Conclusion](#conclusion)

---

## Introduction
This document provides a comprehensive plan for deploying the COIN100 (C100) token, setting up a public sale (ICO), establishing liquidity pools for dynamic pricing (C100 Price), and handling ongoing maintenance and future governance transitions.

## Goals and Principles
- **Transparency:** Ensure every step is clear to stakeholders and investors.
- **Stability:** Dynamically reference on-chain liquidity pools to determine C100 Price.
- **Flexibility:** Allow fallback mechanisms and periodic adjustments to respond to market conditions.
- **Growth Path to Decentralized Governance:** Initially admin-driven, with plans to introduce community governance.

## Token Deployment

### Initial Token Parameters
- Deploy `COIN100(initialMarketCap, initialC100Price)`:
  - `initialMarketCap`: Sets the initial total supply.
  - `initialC100Price`: A starting price for the system before pools are established.

### Owner Allocation (3%)
- 3% of the total supply goes to the owner, with the remaining 97% also initially controlled by the owner’s account.
- The owner can decide how much to allocate to the PublicSale contract.

### Index Fund Concept Integration
- C100’s supply rebases daily/periodically to reflect changes in the top 100 crypto market cap.
- This underpins the token’s value proposition as an index tracker.

## Public Sale (ICO) Deployment

### Defining ICO Parameters
- Deploy `C100PublicSale(c100Address, treasury, startTime, endTime, initialC100Price)`.
- `startTime` and `endTime` define the ICO window.
- `treasury`: Where raised funds (POL and tokens) go.
- `initialC100Price`: Matches or closely aligns with the initial price set in C100.

### Accepted Payment Methods
- POL (chain’s native token, e.g., MATIC) and possibly USDC or other ERC20 tokens (set via `updateErc20Rate()`).

### Initial C100 Price and Temporary Pricing
- Until liquidity pools are set, rely on `initialC100Price`.
- Once pools are ready, `rebase()` will fetch live C100 Price from the pools.

## Liquidity Pool Setup

### C100/USDC Pool Creation
- On a DEX, create a C100/USDC pool to establish a stable reference price in USD terms.
- Add liquidity to target a desired initial price (e.g., $0.001 per C100).

### C100/POL Pool Creation
- Create a C100/POL pool to get a direct on-chain C100 Price (C100 per POL).
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
- This allows C100 to push updated C100 Price to PublicSale after each rebase.

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
- Provide clarity on how C100 Price dynamically updates from pools.

### Investor Participation
- Investors buy C100 from PublicSale using POL or allowed tokens.
- As C100 Price updates at rebase, prices remain aligned with market conditions.

### Dynamic C100 Price Updates via Rebases
- Each `rebase(newMarketCap)` call in C100:
  - Fetches new C100 Price from pools.
  - Updates PublicSale C100 Price accordingly.
  - Adjusts total supply to reflect index changes.

## Rebase Operations During and After ICO

### Periodic Rebase Calls
- Likely daily or as per strategy.
- Reflects index growth or contraction.

### Synchronizing C100 Price with PublicSale
- Automatic in `rebase()`; no manual updates needed once pools are set.

### Fallback Conditions if Liquidity is Insufficient
- If no C100/POL liquidity:
  - Use C100/USDC + `polInUSDCRate`.
- If no pools at all, continue using last known C100 Price or consider reverting rebase until setup is corrected.

## Post-ICO Finalization

### Ending the ICO
- After `endTime`, call `publicSaleContract.finalize()`.
- No more purchases allowed.

### Burning Unsold Tokens
- Unsold tokens are burned (transferred to `0x...dEaD`) to reduce supply dilution.

### Transition to Post-ICO Market Phase
- The token now trades freely on DEXs.
- C100 Price updates continue with rebases, maintaining alignment with market-driven liquidity pools.

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
8. Rebase daily: updates C100 Price and reflects market cap.
9. After `endTime`, finalize ICO and burn unsold tokens.
10. Continue rebasing post-ICO. Introduce governance as project matures.

## Post-Deployment Steps

After deploying the COIN100 (C100) token and initiating the ICO, the following steps ensure the smooth establishment of liquidity pools, accurate pricing, and the ongoing stability of the token ecosystem.

### 13.1. Creating Liquidity Pools

#### Understanding Liquidity Pools and Initial Pricing

**Liquidity Pools** on decentralized exchanges (DEXs) like Uniswap or SushiSwap are smart contracts that hold reserves of two tokens. Liquidity providers (LPs) add equal value of both tokens to the pool, facilitating decentralized trading without the need for traditional order books.

**Initial Pricing:** The ratio of the two tokens you add determines the initial price of your token in the pool. For example, in a **C100/USDC** pool, the amount of C100 and USDC you provide sets the initial price of C100 in terms of USDC.

#### Target Initial Price

- **C100 Initial Price:** $0.001 per C100
- **POL Price:** $0.5985 per POL
- **USDC Price:** $1 per USDC

### 13.2. Calculating Token Amounts for Initial Liquidity

To achieve the target initial price of $0.001 per C100 in the **C100/USDC** pool and ensure accurate pricing in the **C100/POL** pool, calculate the required token amounts as follows:

#### A. **C100/USDC Pool**

**Target Initial Price:** $0.001 per C100

**USDC Price:** $1 per USDC

**Calculation:**
- **1 USDC = 1 / 0.001 = 1000 C100**

**Liquidity Addition:**
- Decide the amount of USDC you want to provide. For example, to add $10,000 worth of USDC:
  - **USDC Amount:** 10,000 USDC
  - **C100 Amount:** 10,000 USDC * 1000 C100/USDC = 10,000,000 C100

#### B. **C100/POL Pool**

**POL Price:** $0.5985 per POL

**C100 Price:** $0.001 per C100

**Calculation:**
- **1 POL = $0.5985 / $0.001 = 598.5 C100**

**Liquidity Addition:**
- Decide the amount of POL you want to provide. For example, to add $10,000 worth of POL:
  - **POL Amount:** 10,000 USD / 0.5985 USD/POL ≈ 16,738 POL
  - **C100 Amount:** 16,738 POL * 598.5 C100/POL ≈ 10,000,000 C100

**Note:** Ensure that the C100 amounts in both pools are consistent to maintain the desired initial pricing.

### 13.3. Adding Liquidity to Pools

#### Step-by-Step Guide

1. **Access the DEX:**
   - Navigate to your chosen DEX on the Polygon network, such as [Uniswap](https://app.uniswap.org/#/add/v2/137) or [SushiSwap](https://sushi.com/add).

2. **Connect Your Wallet:**
   - Use a Polygon-compatible wallet like MetaMask.
   - Ensure you have sufficient POL (MATIC) for gas fees and the required tokens (C100, USDC, POL).

3. **Add Liquidity to C100/USDC Pool:**
   - Select the C100 and USDC tokens.
   - Input the calculated amounts (e.g., 10,000 USDC and 10,000,000 C100).
   - Approve the transaction and confirm the liquidity addition.

4. **Add Liquidity to C100/POL Pool:**
   - Select the C100 and POL tokens.
   - Input the calculated amounts (e.g., 16,738 POL and 10,000,000 C100).
   - Approve the transaction and confirm the liquidity addition.

5. **Confirm Pool Creation:**
   - Once liquidity is added, the pools will be created with the specified initial prices.
   - Verify the pools on the DEX to ensure accurate token ratios.

### 13.4. Verifying and Managing Liquidity Pools

1. **Verify Pool Addresses:**
   - After creating the pools, obtain the pool contract addresses from the DEX.
   - Use `c100Contract.setC100USDCPool(poolAddress)` and `c100Contract.setC100POLPool(poolAddress)` to register these addresses in your C100 contract.

2. **Monitor Pool Health:**
   - Regularly check the liquidity pool reserves to ensure sufficient liquidity.
   - Adjust liquidity as needed based on trading activity and market conditions.

3. **Implement Fallback Logic:**
   - If the C100/POL pool becomes insufficient, ensure that the fallback to C100/USDC + `polInUSDCRate` is operational.
   - Set `c100Contract.setPolInUSDCRate(...)` with the predefined rate to maintain pricing stability.

### 13.5. Additional Recommendations

- **Liquidity Incentives:**
  - Consider offering incentives for early liquidity providers to ensure deep liquidity and reduce slippage.
  
- **Continuous Monitoring:**
  - Use analytics tools to monitor pool performance, trading volumes, and price stability.
  
- **Community Engagement:**
  - Engage with the community to encourage liquidity provision and participation in governance decisions related to liquidity pools.

## Conclusion
This plan ensures a smooth, dynamic, and transparent deployment and ICO execution. By leveraging on-chain liquidity pools to determine C100 Price and providing a fallback mechanism, the system remains robust and adaptable. Over time, governance can transition from a centralized admin model to a community-driven process, aligning with industry best practices and the project’s long-term vision.

---

## Download the Updated `COIN100 Deployment & ICO Execution Plan.md`

You can download the updated `COIN100 Deployment & ICO Execution Plan.md` by copying the above markdown content into a file named `COIN100 Deployment & ICO Execution Plan.md` in your project repository.

---
