# COIN100 (C100)

## Table of Contents
1. [Introduction](#introduction)
2. [Problem Statement](#problem-statement)
3. [Solution: COIN100 (C100) Token](#solution-coin100-c100-token)
4. [Key Principles and Features](#key-principles-and-features)
   4.1. [Fairness and Equal Treatment of Holders](#fairness-and-equal-treatment-of-holders)  
   4.2. [Global Rebase Mechanism](#global-rebase-mechanism)  
   4.3. [Manual Upkeep in Initial Phase](#manual-upkeep-in-initial-phase)  
   4.4. [No Complex Public Sale Mechanics](#no-complex-public-sale-mechanics)
5. [Tokenomics](#tokenomics)
   5.1. [Initial Parameters](#initial-parameters)  
   5.2. [Distribution (Owner Allocation & ICO)](#distribution-owner-allocation--ico)  
   5.3. [Rebase Formula ("Genius" Formula)](#rebase-formula-genius-formula)  
   5.4. [Market Dynamics and Price Stability](#market-dynamics-and-price-stability)
6. [Technical Architecture](#technical-architecture)
   6.1. [Polygon Network](#polygon-network)  
   6.2. [C100 Token Contract](#c100-token-contract)  
   6.3. [ICO (Public Sale) Contract](#ico-public-sale-contract)  
   6.4. [Scaling and GonsPerFragment](#scaling-and-gonsperfragment)
7. [Governance](#governance)
   7.1. [Transition from Owner to Governor](#transition-from-owner-to-governor)  
   7.2. [Future Governor Contract](#future-governor-contract)  
   7.3. [Community Involvement](#community-involvement)
8. [Security](#security)
   8.1. [Ownership Controls](#ownership-controls)  
   8.2. [Pause/Unpause Mechanisms](#pauseunpause-mechanisms)  
   8.3. [Reentrancy Guards](#reentrancy-guards)  
   8.4. [Audits and Best Practices](#audits-and-best-practices)
9. [Roadmap](#roadmap)
10. [ICO Plan (Simplicity-Focused)](#ico-plan-simplicity-focused)
    10.1. [ICO Parameters](#ico-parameters)  
    10.2. [During the ICO](#during-the-ico)  
    10.3. [Post-ICO Finalization and Burning Unsold Tokens](#post-ico-finalization-and-burning-unsold-tokens)  
    10.4. [Maintaining the Index Post-ICO](#maintaining-the-index-post-ico)
11. [FAQ (100 Questions & Answers)](#faq-100-questions--answers)
12. [Contact Information](#contact-information)
13. [Conclusion](#conclusion)

---

## Introduction
COIN100 (C100) is a decentralized cryptocurrency index fund built on the Polygon network. It represents the top 100 cryptocurrencies by market capitalization, mirroring the performance of the overall crypto market. Inspired by traditional index funds like the S&P 500, C100 provides a diversified, market-wide exposure to the crypto industry without requiring active portfolio management from investors.

## Problem Statement
The crypto market can be volatile and fragmented. Investors seeking broad exposure face challenges in selecting and maintaining a balanced portfolio of top assets. Without a simple mechanism to track the aggregate performance of the top 100 cryptocurrencies, investors may either miss growth opportunities or take on unnecessary risk.

## Solution: COIN100 (C100) Token
C100 solves these challenges by:
- Offering a token that represents a proportional share of the top 100 crypto market cap.
- Automatically adjusting each holder’s balance through global rebases as the top 100 market cap changes.
- Reducing complexity for investors who want broad market exposure without active rebalancing.

## Key Principles and Features

### Fairness and Equal Treatment of Holders
Every holder’s balance scales proportionally with changes in the total market cap. No single participant is advantaged or disadvantaged during rebases.

### Global Rebase Mechanism
On each upkeep call, the total supply adjusts to reflect the updated top 100 crypto market cap. All balances scale equally, maintaining each holder’s fractional ownership.

### Manual Upkeep in Initial Phase
Early on, the owner will manually call the rebase function with updated market cap figures. Over time, this process can transition to an automated system (e.g., via a governance proposal and oracle integration).

### No Complex Public Sale Mechanics
At launch, the entire supply is minted to the owner. The owner retains 3% for initial upkeep and distributes 97% through an ICO or directly to a DEX liquidity pool, allowing free market discovery of the token price.

## Tokenomics

### Initial Parameters
- **Initial Supply = Initial Market Cap (M₀)**: If M₀ is the initial top 100 crypto market cap in USD, we set total supply = M₀ C100.
- **Reference Price (~$1/C100)**: By pairing C100 with a stable asset (e.g., USDC) in a liquidity pool, initial market participants can anchor the price around $1.

### Distribution (Owner Allocation & ICO)
- Owner receives 100% at deployment.
- Owner keeps 3% (developer allocation).
- Owner allocates remaining 97% for ICO or liquidity provisioning.

### Rebase Formula ("Genius" Formula)
**ratio = M_new / M_old**  
- New Supply = Old Supply * ratio  
- Every holder’s balance is multiplied by the same ratio.

This ensures fair and transparent tracking of the market cap changes.

### Market Dynamics and Price Stability
If the market cap doubles, all balances double, maintaining the token’s value reference. As the community matures and markets become more efficient, the token price should remain stable around its baseline in response to these proportional adjustments.

## Technical Architecture

### Polygon Network
Deployed on Polygon for low gas fees and high throughput.

### C100 Token Contract
Implements ERC20 standards, rebase logic, ownership control, pause/unpause functionalities, and integration points for future governance.

### ICO (Public Sale) Contract
Handles the initial distribution of 97% tokens. Investors purchase C100 with MATIC or ERC20 tokens (e.g., USDC) during the ICO period. Unsold tokens are burned at the end, ensuring only the circulating supply reflects real participants.

### Scaling and GonsPerFragment
Balances are tracked in a large integer unit called “gons.” The global `gonsPerFragment` variable determines how these translate into user balances. On rebase, adjusting `gonsPerFragment` updates everyone’s balance proportionally in O(1) complexity.

## Governance

### Transition from Owner to Governor
Initially, the owner manages the contract. Later, a governor contract can be introduced. The governor can propose and vote on changes (parameters, treasury usage, etc.), enabling community-driven evolution.

### Future Governor Contract
By deploying a governor contract and timelock controller, the project gradually moves towards full decentralization. Governance token holders can vote on upgrades, new features, or parameter changes (e.g., adjusting the rebase frequency or introducing a treasury fee).

### Community Involvement
Over time, the community will shape the project’s future. They can propose:
- Adjusting parameters (fees, rebase frequency)
- Allocating treasury funds for development, marketing, or liquidity
- Introducing new features or improvements

## Security

### Ownership Controls
The `onlyOwner` and `onlyAdmin` modifiers ensure that only authorized parties (owner or governor) can make critical changes.

### Pause/Unpause Mechanisms
The contract can be paused in emergencies, preventing transfers and safeguarding against exploits during uncertain times.

### Reentrancy Guards
NonReentrant modifiers protect against complex reentrancy attacks, ensuring safe execution of functions like buy tokens or rebase.

### Audits and Best Practices
Smart contract auditing and community code reviews will enhance trust and security. Following industry standards, best practices, and thorough testing before mainnet deployment is crucial.

## Roadmap
- **Phase 1:** Token and ICO launch, manual upkeep.
- **Phase 2:** Introduce governance, set governor contract.
- **Phase 3:** Possibly add oracles for automated updates.
- **Phase 4:** Community-driven proposals for enhancements, treasury usage, fee adjustments.
- **Phase 5:** Ongoing refinement, scaling, and ecosystem expansion.

## ICO Plan (Simplicity-Focused)

### ICO Parameters
- Duration: e.g., 12 months.
- Accepted Currencies: MATIC, optionally USDC.
- Rate: Fixed C100 per MATIC/USDC.

### During the ICO
- Investors buy C100 directly from the crowdsale contract.
- Owner periodically calls rebase to keep C100 supply aligned with the top 100 market cap.
- Unsold tokens remain in the ICO contract, also getting rebased.

### Post-ICO Finalization and Burning Unsold Tokens
At the end of the ICO:
- No more purchases allowed.
- Any unsold tokens are burned, ensuring the supply reflects only actively held tokens plus the owner’s 3%.

### Maintaining the Index Post-ICO
After the ICO:
- Continue daily/periodic rebases.
- Future governance can introduce advanced features (e.g., treasury, automated oracles).

---

## FAQ (100 Questions & Answers)

1. **Q:** What is COIN100 (C100)?  
   **A:** It’s a decentralized index fund token on Polygon, tracking the top 100 cryptos by market cap.

2. **Q:** How does C100 track the top 100 crypto market cap?  
   **A:** Through a global rebase mechanism. As the total market cap changes, the supply and balances adjust proportionally.

3. **Q:** Is C100 an ERC20 token?  
   **A:** Yes, it follows the ERC20 standard with additional rebasing logic.

4. **Q:** On which network is C100 deployed?  
   **A:** Polygon (Matic) network.

5. **Q:** Why Polygon?  
   **A:** Low fees, fast transactions, and high scalability.

6. **Q:** What is the initial supply of C100?  
   **A:** Equal to the initial top 100 crypto market cap (denominated in C100 units).

7. **Q:** What is the reference price at launch?  
   **A:** Around $1 per C100 token, assuming the owner pairs it with a stable asset in a DEX.

8. **Q:** What does rebase mean?  
   **A:** Rebase changes everyone’s balances proportionally to reflect changes in total market cap.

9. **Q:** Who initiates the rebase initially?  
   **A:** The owner (admin) does this manually until governance is set.

10. **Q:** Will there be automated rebasing eventually?  
    **A:** Yes, once governance and oracles are established.

11. **Q:** What happens if the market cap doubles?  
    **A:** All token balances double, maintaining the same fractional ownership.

12. **Q:** What if the market cap halves?  
    **A:** All balances reduce proportionally, preserving fractional ownership.

13. **Q:** Is there a fixed time interval for rebases?  
    **A:** Initially manual. Later, governance may define a frequency or trigger conditions.

14. **Q:** How is fairness ensured?  
    **A:** Every holder’s balance changes by the same ratio on rebases, no exceptions.

15. **Q:** Does the owner get special treatment in rebases?  
    **A:** No, after initial allocation, the owner’s tokens also rebase equally.

16. **Q:** What is the owner’s initial allocation?  
    **A:** 3% of total supply for their initial upkeep efforts.

17. **Q:** What happens to the remaining 97% at launch?  
    **A:** It’s used for ICO or directly to provide liquidity and let the market buy freely.

18. **Q:** Is there an ICO?  
    **A:** Yes, the owner may run an ICO to distribute the 97% of tokens.

19. **Q:** What if not all tokens sell in the ICO?  
    **A:** Unsold tokens are burned at the end of the ICO.

20. **Q:** Why burn unsold tokens?  
    **A:** To ensure the supply accurately reflects actively held tokens, maintaining fairness and index integrity.

21. **Q:** Can I buy C100 after the ICO?  
    **A:** Yes, on DEXs where liquidity is provided by the owner and early participants.

22. **Q:** Will there be a stable price?  
    **A:** Price aims to stay near the index-based reference. Market forces and arbitrage help maintain this.

23. **Q:** Does C100 pay dividends?  
    **A:** Not directly. The value accrues by tracking the market cap of top 100 cryptos.

24. **Q:** How do I store C100?  
    **A:** In any Polygon-compatible ERC20 wallet.

25. **Q:** Is there a vesting schedule?  
    **A:** None by default. The owner’s 3% is fully unlocked at launch.

26. **Q:** How do I track the top 100 market cap changes?  
    **A:** Initially, trust the owner’s manual updates. Later, an oracle might provide on-chain data.

27. **Q:** Is the contract audited?  
    **A:** The team plans for audits before mainnet release.

28. **Q:** Can C100 be paused?  
    **A:** Yes, the admin can pause the contract in emergencies.

29. **Q:** Why pause the contract?  
    **A:** To prevent malicious exploitation during unexpected issues.

30. **Q:** What is `gonsPerFragment`?  
    **A:** An internal scaling factor that efficiently adjusts balances during rebases.

31. **Q:** Does rebase affect my token count in my wallet?  
    **A:** Yes, your balance number changes, but proportionally to everyone else’s, preserving your share.

32. **Q:** Can I lose my fraction of ownership?  
    **A:** Not due to rebases. Your fraction relative to total supply remains constant (unless you trade).

33. **Q:** What if someone doesn’t trust the owner’s data?  
    **A:** Eventually, governance and oracles will automate and decentralize updates, reducing trust issues.

34. **Q:** Could governance change the parameters?  
    **A:** Yes, once set, governance can vote on parameters like rebase frequency, fees, or treasuries.

35. **Q:** Will there be a treasury?  
    **A:** Possibly. Governance can introduce treasury fees and funds to support project growth.

36. **Q:** How would treasury fees work?  
    **A:** A small portion of transactions could go to a treasury wallet, later allocated by governance.

37. **Q:** What is the benefit of a treasury?  
    **A:** It supports future development, marketing, audits, or liquidity incentives.

38. **Q:** Is there a whitelist or KYC?  
    **A:** No. Anyone on Polygon can buy C100; it’s permissionless.

39. **Q:** Can I sell C100 anytime?  
    **A:** Yes, on any DEX where liquidity is available.

40. **Q:** Is C100 inflationary?  
    **A:** Rebase adjusts supply proportionally. It’s not traditional inflation; it’s a representation of the index.

41. **Q:** Does market cap growth dilute existing holders?  
    **A:** No, growth increases everyone’s balance proportionally.

42. **Q:** If the index grows, do I earn more tokens?  
    **A:** Yes, your token balance increases on rebase events.

43. **Q:** Can governance remove the owner’s rights?  
    **A:** Yes, if coded accordingly, after governance takes over, the owner can relinquish control.

44. **Q:** What if governance makes bad decisions?  
    **A:** Governance is controlled by token holders. It’s community-driven. If bad proposals pass, that’s a community risk.

45. **Q:** Can I propose changes without being the governor?  
    **A:** Typically, you need a minimum token amount to propose. Details depend on the governor contract design.

46. **Q:** Will the token’s name or symbol change?  
    **A:** Unlikely. It’s set at deployment.

47. **Q:** How do I add C100 to my wallet interface?  
    **A:** Import the token’s contract address into your Polygon-compatible wallet.

48. **Q:** Are rebases taxable events?  
    **A:** Consult a tax professional. Tax treatment may vary by jurisdiction.

49. **Q:** Is there a minimum or maximum investment?  
    **A:** No strict limits by the contract. Market liquidity and token price determine practical limits.

50. **Q:** What if I buy right before a rebase?  
    **A:** Your purchase includes the upcoming rebase changes. You neither gain nor lose unfairly.

51. **Q:** Do I need to claim my rebased tokens?  
    **A:** No. Rebase updates balances automatically.

52. **Q:** How often will the owner rebase initially?  
    **A:** Possibly daily, but it’s flexible. The owner decides until governance sets rules.

53. **Q:** Will there be an official oracle integration?  
    **A:** In the future, yes, to automate market cap updates.

54. **Q:** Can governance integrate Chainlink oracles?  
    **A:** Yes, governance can approve contracts and integrate reliable oracles.

55. **Q:** Are there smart contract upgrade plans?  
    **A:** Possibly. With governance, changes can be proposed and voted on, potentially including upgrades.

56. **Q:** What if Polygon network faces issues?  
    **A:** The token resides on Polygon. Any network-wide issues affect all tokens equally.

57. **Q:** Is there a limit to how large the top 100 crypto market cap can grow?  
    **A:** Practically no. As it grows, C100 supply and balances grow proportionally.

58. **Q:** How do I know the top 100 composition?  
    **A:** Initially off-chain data. In the future, oracles or references can be introduced on-chain.

59. **Q:** Does composition of the top 100 matter for holders?  
    **A:** Not directly. You always hold a fraction of the total cap, regardless of composition changes.

60. **Q:** What if the top 100 changes (some coins leave, others enter)?  
    **A:** The index’s total cap changes, reflected at next rebase. No direct action needed by holders.

61. **Q:** Can I use C100 in DeFi (lending, staking)?  
    **A:** Potentially yes, if DeFi protocols support C100.

62. **Q:** Is there a whitepaper available?  
    **A:** This README and future documentation serve as a whitepaper. Detailed docs are planned.

63. **Q:** Will the contract be verified on PolygonScan?  
    **A:** Yes, for transparency and trust.

64. **Q:** How do I participate in governance voting?  
    **A:** Acquire enough C100 to vote, and interact with the governor contract once deployed.

65. **Q:** Can governance freeze rebases?  
    **A:** If coded, yes, governance might pause or adjust rebase conditions.

66. **Q:** Is there a maximum supply cap?  
    **A:** No hard cap. Supply floats with market cap.

67. **Q:** Could C100 track a different index in the future?  
    **A:** Governance could propose changing index parameters if such flexibility is allowed.

68. **Q:** Does the token have a logo?  
    **A:** Initially, a simple logo. The community can decide on rebranding later.

69. **Q:** Are there any partnerships?  
    **A:** Partnerships may be pursued. Check announcements.

70. **Q:** Will liquidity be locked?  
    **A:** Owner or governance may decide on liquidity locking for trust.

71. **Q:** Does C100 rely on a single entity?  
    **A:** Initially owner-managed, aiming to evolve into fully decentralized governance.

72. **Q:** Can C100 survive if the owner disappears?  
    **A:** Once governance is established, yes. The project can run autonomously.

73. **Q:** How can I suggest improvements?  
    **A:** Join Discord, Reddit, or submit proposals once governance is live.

74. **Q:** Can I fork C100?  
    **A:** The code is open-source. Others can fork, but trust, community, and liquidity matter.

75. **Q:** Will large holders influence votes heavily?  
    **A:** Yes, governance is token-weighted. More tokens mean more voting power.

76. **Q:** Could governance introduce fees on transfers?  
    **A:** Yes, if proposals pass, a fee could be implemented.

77. **Q:** Where do fees go if introduced?  
    **A:** Potentially a treasury governed by token holders.

78. **Q:** How is treasury managed?  
    **A:** By governance votes on how to allocate or use funds.

79. **Q:** Can I redeem my tokens for underlying assets?  
    **A:** No direct redemption. C100 is synthetic exposure, not a claim on underlying coins.

80. **Q:** What if the top 100 index calculation method changes?  
    **A:** Governance could adapt the model if needed.

81. **Q:** How frequently is market cap data updated manually?  
    **A:** Initially at owner’s discretion. Possibly daily or weekly until automated.

82. **Q:** Does holding C100 require any special steps?  
    **A:** No, just hold it in a Polygon-compatible wallet.

83. **Q:** Is there a minimum gas token needed?  
    **A:** Yes, MATIC for gas fees on Polygon.

84. **Q:** Can I bridge C100 to other chains?  
    **A:** Possibly in the future if bridges support it.

85. **Q:** Will listing on centralized exchanges happen?  
    **A:** Up to exchanges’ interest. The community can encourage listings.

86. **Q:** Does C100 track stablecoins in the top 100?  
    **A:** If stablecoins are in top 100 by market cap, they are included. It’s a neutral index.

87. **Q:** Are smart contract addresses known at launch?  
    **A:** Yes, published once deployed and verified.

88. **Q:** Will there be a testnet version?  
    **A:** Likely, for community testing before mainnet.

89. **Q:** Does the token support EIP-2612 (permit)?  
    **A:** Not initially. Could be added by governance if desired.

90. **Q:** Is there a referral program?  
    **A:** Not currently. Community can propose incentive programs later.

91. **Q:** How is liquidity provided initially?  
    **A:** Owner adds initial liquidity to a DEX, possibly at $1/C100.

92. **Q:** Can I track C100 price on aggregators?  
    **A:** Yes, once listed, price data will appear on coin trackers.

93. **Q:** Is C100 correlated with Bitcoin/Ethereum alone?  
    **A:** It’s correlated with the entire top 100 cryptos, not just one coin.

94. **Q:** Can I short C100?  
    **A:** Only if a DeFi platform offers derivatives. C100 doesn’t provide native shorting.

95. **Q:** Does C100 have a roadmap for oracle integration?  
    **A:** Yes, after community matures, oracles may automate index tracking.

96. **Q:** What if no one calls rebase?  
    **A:** Then the index isn’t updated. Market price may drift from $1. Eventually governance or oracles will handle this.

97. **Q:** Will the team remain anonymous?  
    **A:** The team may reveal themselves over time. Governance reduces reliance on team identity.

98. **Q:** Is the code open source?  
    **A:** Yes, allowing transparency and community audits.

99. **Q:** How do I get support?  
    **A:** Via email, Discord, Reddit, or X as listed in Contact Information.

100. **Q:** Why trust C100 over other tokens?  
     **A:** C100 provides a broad, fair, and transparent index exposure with a clear path to decentralization and community governance.

---

## Contact Information
For further inquiries, support, or to engage with the COIN100 team, please reach out through the following channels:

- **Website:** [https://coin100.link](https://coin100.link)
- **Email:** [support@coin100.link](mailto:support@coin100.link)
- **Discord:** [Join Our Discord](https://discord.com/channels/1312498183485784236/1312498184500674693)
- **Reddit:** [r/Coin100](https://www.reddit.com/r/Coin100)
- **X:** [@Coin100token](https://x.com/Coin100token)
- **coin100:** 0x6402778921629ffbfeb3b683a4da099f74a2d4c5
- **publicSale:** 

---

## Conclusion
COIN100 (C100) provides a seamless, fair, and transparent way to invest in the top 100 cryptocurrencies. Through a global rebase mechanism, manual-to-automated governance transition, and robust security, it aims to become a trusted and stable representation of the crypto market’s collective growth. Join the community and help shape the future of decentralized index investing.
