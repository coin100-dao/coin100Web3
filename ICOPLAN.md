# COIN100 ICO Plan (Simplicity-Focused)

## Table of Contents

1. [Introduction](#introduction)  
2. [Goals and Principles](#goals-and-principles)  
3. [Token Deployment](#token-deployment)  
   3.1. Initial Token Parameters  
   3.2. Owner Allocation (3%)  
   3.3. Relationship to the Index Fund Concept  
4. [ICO (Public Sale) Deployment](#ico-public-sale-deployment)  
   4.1. Defining Sale Parameters  
   4.2. Accepted Payment Methods (MATIC, USDC, etc.)  
   4.3. Price and Duration  
5. [Conducting the ICO](#conducting-the-ico)  
   5.1. Marketing and Communication  
   5.2. Investor Participation  
   5.3. Daily Upkeep and Rebase During ICO  
6. [Post-ICO Finalization](#post-ico-finalization)  
   6.1. Ending the ICO  
   6.2. Burning Unsold Tokens  
   6.3. Rationale for Burning  
7. [Maintaining the Index Post-ICO](#maintaining-the-index-post-ico)  
   7.1. Ongoing Daily/Periodic Rebase  
   7.2. Transparent Value Tracking  
8. [Future Governance Introduction](#future-governance-introduction)  
   8.1. Governor Contract Deployment (Later Phase)  
   8.2. Community Decision-Making  
   8.3. Transitioning Control from Owner to Governance  
9. [Chronological Checklist](#chronological-checklist)  
10. [Conclusion](#conclusion)


---

## 1. Introduction

COIN100 (C100) is designed to represent a dynamic, rebasing index of the top 100 cryptocurrencies by market cap. To fund development and distribution of tokens, an Initial Coin Offering (ICO) will be held. The approach described here prioritizes simplicity and clarity:

- Deploy token first.
- Deploy a public sale contract and run the ICO.
- At the end of the ICO, burn any unsold tokens to ensure a clean, accurate index representation.
- At a later stage, introduce a governor contract to enable decentralized governance.

---

## 2. Goals and Principles

- **Simplicity:** A clear and linear progression from token deployment to ICO to post-ICO cleanup.
- **Fairness:** All participants get the same proportional benefits from market cap-driven rebase adjustments.
- **Transparency:** Unsold tokens are removed from circulation to prevent confusion and maintain trust.
- **Future-Proofing:** Governance can be introduced later for advanced community-driven decisions.

---

## 3. Token Deployment

### 3.1 Initial Token Parameters

- **Initial Supply:** Set equal to the initial top 100 market cap (e.g., `M0` units of C100).
- **Decimals:** 18 decimals to maintain standard ERC20 compatibility.
- **Owner Allocation (3%):** The token contract mints the entire supply to the owner’s address. The owner keeps 3% and prepares to use the remaining 97% for the public sale.

### 3.2 Owner Allocation (3%)

The owner retains 3% of the supply as a reward for performing initial upkeep and shouldering early administrative overhead. This allocation is clearly defined and minted at deployment.

### 3.3 Relationship to the Index Fund Concept

The token’s total supply starts as a direct mapping to the top 100 market cap. Daily or periodic rebasing will adjust everyone’s balances proportionally, ensuring each C100 token always represents the same fraction of the index.

---

## 4. ICO (Public Sale) Deployment

### 4.1 Defining Sale Parameters

- **Percentage for Sale:** Approximately 97% of the supply is allocated for the ICO.
- **ICO Contract:** Deploy a separate crowdsale contract that:
  - Receives the 97% of tokens from the owner.
  - Sells these tokens to contributors in exchange for MATIC, USDC, or another predetermined currency.
  
### 4.2 Accepted Payment Methods (MATIC, USDC, etc.)

The crowdsale contract can be designed to accept multiple payment methods. For simplicity, start with one primary payment method (e.g., MATIC) and optionally support USDC with a fixed rate.

### 4.3 Price and Duration

- **Price:** Establish a fixed conversion rate (e.g., 1 MATIC = 1000 C100) for the ICO period.
- **Duration:** A defined timeframe (e.g., 12 months) during which contributions are accepted.

---

## 5. Conducting the ICO

### 5.1 Marketing and Communication

- Announce start and end times, accepted currencies, and token rates on your website (coin100.link).
- Provide user instructions and connect wallet integrations.

### 5.2 Investor Participation

- Investors visit coin100.link.
- Connect their wallet (e.g., MetaMask) and send MATIC/USDC to the crowdsale contract.
- Instantly receive C100 tokens at the prescribed rate.

### 5.3 Daily Upkeep and Rebase During ICO

- The daily/periodic rebase occurs as planned.  
- The public sale contract’s unsold tokens also get rebased, maintaining their fractional representation of the index.

---

## 6. Post-ICO Finalization

### 6.1 Ending the ICO

- At the conclusion of the 12-month ICO window, no further purchases are allowed.
- The final state: some tokens are sold and now distributed among many holders. Some tokens may remain unsold in the public sale contract.

### 6.2 Burning Unsold Tokens

- Immediately burn any remaining unsold tokens in the public sale contract.
- This action ensures that the total supply now corresponds only to tokens held by actual participants and the 3% owner allocation.

### 6.3 Rationale for Burning

- Eliminates distortions caused by non-circulating tokens.
- Ensures future rebases accurately reflect the true circulating supply.
- Enhances trust and simplicity—no idle tokens remain.

---

## 7. Maintaining the Index Post-ICO

### 7.1 Ongoing Daily/Periodic Rebase

- Continue performing manual upkeep calls that adjust supply based on the top 100 market cap.
- Now that only actively held tokens exist, every holder’s balance changes proportionally and transparently.

### 7.2 Transparent Value Tracking

- Users can verify that their tokens truly represent an undiluted fraction of the index’s market cap.
- The market price should reflect the index’s performance over time.

---

## 8. Future Governance Introduction

### 8.1 Governor Contract Deployment (Later Phase)

- After the ecosystem matures, deploy a governor contract and possibly a timelock.
- The governor contract allows token holders to propose and vote on changes.

### 8.2 Community Decision-Making

- Governance can decide on future enhancements, allocation of treasury funds, and protocol parameters.
- Gradually transition decision-making from the owner to the governor contract, promoting decentralization.

### 8.3 Transitioning Control

- Eventually, the owner’s admin keys can be relinquished to governance.
- The community takes the reins of the project’s direction and policy-making.

---

## 9. Chronological Checklist

1. **Deploy Token Contract**  
   - Mint total supply to owner.
   - Owner keeps 3%, intends to sell 97%.

2. **Deploy Public Sale Contract**  
   - Transfer 97% of tokens from owner to this contract.
   - Set pricing and duration parameters.

3. **Start ICO**  
   - Advertise on coin100.link.
   - Investors buy tokens during the next 12 months.
   - Perform daily/periodic rebases as planned.

4. **ICO Ends**  
   - Stop accepting contributions.
   - Unsold tokens remain in the public sale contract.

5. **Burn Unsold Tokens**  
   - Immediately burn any tokens not sold.
   - Supply now reflects only actual holders + 3% owner share.

6. **Continue Index Operations**  
   - Keep performing upkeep and rebases.
   - Token supply and holder balances now cleanly track the top 100 market cap changes.

7. **Later: Deploy Governance Contracts**  
   - Introduce a governor and timelock controller after the market stabilizes.
   - Over time, shift decision-making powers to the community.

---

## 10. Conclusion

This simplicity-focused approach ensures a straightforward, fair, and transparent ICO process aligned with the C100 token’s index fund concept. By burning unsold tokens at the end of the ICO, the circulating supply remains meaningful and unambiguous. Future governance introduction can follow once the community is established, ensuring that the token’s long-term evolution is driven by its stakeholders rather than a single centralized authority.
