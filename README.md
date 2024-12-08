# COIN100 (C100)
## White Paper / Detailed Plan
**COIN100** is a decentralized cryptocurrency index fund built on the polygon network. It represents the top 100 cryptocurrencies by market capitalization, offering users a diversified portfolio that mirrors the performance of the overall crypto market. Inspired by traditional index funds like the S&P 500, COIN100

**Ultimate Goal:** To dynamically track and reflect the top 100 cryptocurrencies by market capitalization, ensuring that COIN100 remains a relevant and accurate representation of the cryptocurrency market.

**Name:** COIN100 (C100)
**Network:** Polygon

**Mission Statement:**
COIN100 (C100) is designed to track the total market capitalization of the top 100 cryptocurrencies in a simple, fair, and transparent manner. The token functions like an index fund share: each token always represents the same proportional share of the top 100 crypto market cap. As the index’s total market cap changes, all token balances adjust proportionally, ensuring holders retain their exact fractional ownership of the index over time.

**Key Principles:**

Fairness and Equal Treatment of All Holders:
Every holder should experience the same proportional gains or losses when the underlying top 100 market cap changes. No single address (other than at initial distribution) gets preferential treatment in supply adjustments.

**Global Rebase Mechanism:**
Instead of minting or burning tokens for selective addresses, we use a global “rebase” approach. On each update (called “upkeep”), the total supply and every holder’s balance scale together based on the ratio of new market cap to old market cap. This keeps every holder’s fraction of the total supply identical before and after the rebase.

**Manual Upkeep in Initial Phase:**
While the ultimate goal is to have an automated governance system (a future governor contract) and potentially use oracles, the initial phase will be manually managed by the contract owner. The owner can call an “upkeep” function with the new top 100 market cap figure. This allows for flexible testing and refinement before decentralizing control.

**No Complex Public Sale Mechanics:**
There is no dedicated “public sale” address. Instead:

At deployment, we mint the entire initial supply to the owner.
The owner retains a small percentage (e.g. 3%) for themselves.
The owner then provides liquidity or otherwise makes the remaining tokens available for trading on decentralized exchanges (DEXs), enabling a free and open market.
This ensures immediate and permissionless access to tokens.
Initial Parameters and Reference Price:
To create a stable and intuitive reference point:

Let the initial top 100 market cap at deployment be M₀ (a number provided by the admin at launch).
We set the initial total supply to be equal to M₀ tokens.
This implies if we pair it with a stable reference asset (like USDC) at $1 per C100, each token represents exactly $1 of the index at launch.
Thus:
Initial total supply = M₀ (matching the initial market cap for a simple 1:1 ratio).
Owner receives M₀ tokens at deployment.
Owner keeps 3% of M₀ as a developer allocation.
Owner uses the remaining ~97% to create a liquidity pool with a stable asset (e.g., USDC) so that the market can freely discover and trade C100 at around $1 per token initially.
Rebase Formula (The “Genius” Formula):
After launch, as the top 100 market cap changes, the owner (admin) will periodically update the contract with a new market cap figure M_new. Let’s call the previously known market cap M_old. We compute the ratio:

ratio = M_new / M_old

A ratio > 1 means the market cap grew (e.g., if ratio = 1.2, the top 100 cap grew by 20%).
A ratio < 1 means the market cap shrank (e.g., if ratio = 0.8, the top 100 cap dropped by 20%).

On calling the rebase function, the contract adjusts every holder’s balance as follows:

New Total Supply = Old Total Supply * ratio
Every holder’s balance is multiplied by ratio
Because we started with the total supply equal to the index market cap at launch, and we always adjust supply by the exact ratio of change in market cap, the token’s “fair value” remains close to $1. If the underlying index grows by 20%, the total supply and each holder’s balance also grow by 20%. In a well-arbitraged market, the token price will remain near its baseline reference.

Implementation Detail - Balances and Scaling Factor: Instead of manually adjusting each account (which would be infeasible), we store balances in a special “scaled” form:

Define a large internal unit called “gons” to prevent rounding issues.
Each user’s balance is tracked in gons.
A global variable gonsPerFragment defines how many gons represent one visible token (fragment).
On rebase, we simply adjust gonsPerFragment by dividing it by the ratio or multiplying it inversely, which changes the effective visible balances for all holders at once.
This approach ensures O(1) complexity for rebasing, no matter how many holders there are.

**Market Dynamics and Price Stability:**

Initially, C100 tokens can be added to a liquidity pool at $1 per token.
If the underlying index (top 100 mcap) doubles, and a rebase doubles everyone’s token count, theoretically, each token should still be worth about $1 because each token now represents half the original fraction (as total supply also doubled), but the underlying value doubled too, netting out to the same $1 baseline.
This stable baseline helps the market understand the token’s value. When the index is up, everyone has more tokens at roughly the same unit price. When the index is down, everyone has fewer tokens, but each still represents the same fraction of the index. The intuitive baseline price reduces confusion and encourages trust.

**Future Governance and Automation:**

Initially, the owner (admin) can manually call rebase(newMcap) whenever they have updated information.
In the future, a governance contract chosen by the community can replace the owner, and an oracle can provide fully automated, trust-minimized updates.
This phased approach enables careful iteration and stability before handing over to a community-driven governance model.
Sustainability and Fairness:

Because all holders’ balances scale together, no one is disadvantaged or favored by the rebasing process.
The reference price of $1 and the direct link to total market cap changes create a transparent system where everyone understands how and why their balances change.
This simple, direct mapping (total supply ≈ market cap) makes the token behave like a share in the top 100 crypto index fund, ensuring the project remains sustainable, fair, and trusted.


## Table of Contents

1. [Introduction](#introduction)
2. [Problem Statement](#problem-statement)
3. [Solution: COIN100 (C100) Token](#solution-coin100-c100-token)
4. [Features](#features)
5. [Tokenomics](#tokenomics)
6. [Technical Architecture](#technical-architecture)
7. [Governance](#governance)
8. [Security](#security)
9. [Roadmap](#roadmap)
---

## Introduction

The cryptocurrency market is renowned for its volatility and rapid growth. However, navigating this landscape can be challenging for both new and seasoned investors. Traditional financial instruments like index funds have provided a balanced and diversified investment approach in conventional markets. Drawing inspiration from these, **COIN100 (C100)** emerges as a decentralized cryptocurrency index fund built on the Polygon network, aiming to offer a similar diversified and stable investment vehicle in the crypto space.

## Problem Statement

Investing in cryptocurrencies individually exposes investors to high volatility and risk associated with specific assets. Tracking and managing a diversified portfolio of top-performing cryptocurrencies manually is time-consuming and complex. Additionally, the lack of regulated and easily accessible index-based investment options in the crypto market limits opportunities for investors seeking balanced exposure.

## Solution: COIN100 (C100) Token

**COIN100 (C100)** addresses these challenges by offering a decentralized index fund that tracks the top 100 cryptocurrencies by market capitalization. By holding C100 tokens, investors gain diversified exposure to the leading cryptocurrencies, mitigating the risks associated with individual asset volatility. Built on the Polygon network, C100 ensures low transaction fees, high scalability, and robust security.

## Features

### Decentralized Index Fund

COIN100 represents the top 100 cryptocurrencies by market capitalization, providing a diversified portfolio that mirrors the overall crypto market's performance. This approach reduces the risk inherent in investing in individual cryptocurrencies and offers a balanced investment strategy.

### Dynamic Rebase Mechanism

The C100 token incorporates a dynamic rebase mechanism that adjusts the token supply based on the total market capitalization. This ensures that the token remains a true reflection of the underlying index, maintaining its relevance and accuracy in tracking market movements.

### Automated Rewards Distribution

C100 holders are rewarded through an automated distribution system. A portion of transaction fees is allocated to rewards, incentivizing long-term holding and participation in the network. The reward rate adjusts based on the token's price, ensuring sustainability and alignment with market conditions.

### Governance and Security

The token leverages robust governance mechanisms, allowing designated governors to manage key parameters. Security features such as pausability, ownership controls, and protection against reentrancy attacks ensure the contract's integrity and resilience against potential threats.

## Tokenomics

### Total Supply

- **Total Supply:** 1,000,000,000 C100 tokens
- **Decimals:** 18
