# COIN100 (C100)

## Table of Contents
1. [Introduction](#introduction)
2. [Problem Statement](#problem-statement)
3. [Solution: COIN100 (C100) Token](#solution-coin100-c100-token)
4. [Key Principles and Features](#key-principles-and-features)
   4.1. [Fairness and Equal Treatment of Holders](#fairness-and-equal-treatment-of-holders)  
   4.2. [Global Rebase Mechanism](#global-rebase-mechanism)  
   4.3. [Manual Upkeep in Initial Phase](#manual-upkeep-in-initial-phase)  
   4.4. [Dynamic `polRate` Update](#dynamic-polrate-update)  
   4.5. [Fee-Based Treasury Growth](#fee-based-treasury-growth)  
   4.6. [Configurable Liquidity Provider Rewards](#configurable-liquidity-provider-rewards)  
   4.7. [No Complex Public Sale Mechanics](#no-complex-public-sale-mechanics)
5. [Tokenomics](#tokenomics)
   5.1. [Initial Parameters](#initial-parameters)  
   5.2. [Distribution (Owner Allocation & ICO)](#distribution-owner-allocation--ico)  
   5.3. [Rebase Formula ("Genius" Formula)](#rebase-formula-genius-formula)  
   5.4. [Market Dynamics and Price Stability](#market-dynamics-and-price-stability)
   5.5. [Liquidity Provider Rewards](#liquidity-provider-rewards)
   5.6. [Fee-Based Treasury](#fee-based-treasury)
6. [Technical Architecture](#technical-architecture)
   6.1. [Polygon Network](#polygon-network)  
   6.2. [C100 Token Contract](#c100-token-contract)  
   6.3. [ICO (Public Sale) Contract](#ico-public-sale-contract)  
   6.4. [Scaling and GonsPerFragment](#scaling-and-gonsperfragment)
   6.5. [Dynamic `polRate` Mechanism](#dynamic-polrate-mechanism)
7. [Governance](#governance)
   7.1. [Transition from Owner to Governor](#transition-from-owner-to-governor)  
   7.2. [Future Governor Contract](#future-governor-contract)  
   7.3. [Community Involvement](#community-involvement)
8. [Security](#security)
   8.1. [Ownership Controls](#ownership-controls)  
   8.2. [Pause/Unpause Mechanisms](#pauseunpause-mechanisms)  
   8.3. [Reentrancy Guards](#reentrancy-guards)  
   8.4. [Audits and Best Practices](#audits-and-best-practices)
   8.5. [Token Rescue and Burning](#token-rescue-and-burning)
9. [Roadmap](#roadmap)
10. [ICO Plan (Simplicity-Focused)](#ico-plan-simplicity-focused)
    10.1. [ICO Parameters](#ico-parameters)  
    10.2. [During the ICO](#during-the-ico)  
    10.3. [Post-ICO Finalization and Burning Unsold Tokens](#post-ico-finalization-and-burning-unsold-tokens)  
    10.4. [Maintaining the Index Post-ICO](#maintaining-the-index-post-ico)
    10.5. [Liquidity Provider Participation During ICO](#liquidity-provider-participation-during-ico)
11. [FAQ (112 Questions & Answers)](#faq-112-questions--answers)
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
- Implementing dynamic pricing mechanisms for `polRate`.
- Introducing fee-based treasury growth and configurable liquidity provider rewards.
- Reducing complexity for investors who want broad market exposure without active rebalancing.

## Key Principles and Features

### Fairness and Equal Treatment of Holders
Every holder’s balance scales proportionally with changes in the total market cap. No single participant is advantaged or disadvantaged during rebases.

### Global Rebase Mechanism
On each upkeep call, the total supply adjusts to reflect the updated top 100 crypto market cap. All balances scale equally, maintaining each holder’s fractional ownership.

### Manual Upkeep in Initial Phase
Early on, the owner will manually call the rebase function with updated market cap figures. Over time, this process can transition to an automated system (e.g., via a governance proposal and oracle integration).

### Dynamic `polRate` Update
The `polRate` (C100 per POL) is dynamically updated based on the reserves in the `C100-POL` liquidity pool. If the primary pool is unavailable, the system falls back to the `C100-USDC` pool using a predefined `polInUSDCRate`. This ensures accurate and real-time pricing adjustments aligned with market conditions.

### Fee-Based Treasury Growth
C100 introduces transfer fees that can be enabled or disabled by the admin. When enabled, a portion of each transaction is sent to a designated treasury address, facilitating continuous growth and funding for development, marketing, and other strategic initiatives.

### Configurable Liquidity Provider Rewards
Liquidity providers are incentivized through a configurable reward system. Initially set to 5% of supply changes during rebases, this percentage can be adjusted up to a maximum of 10% based on community governance, allowing flexibility in rewarding liquidity contributors.

### No Complex Public Sale Mechanics
C100 emphasizes simplicity in its public sale to ensure broad accessibility and ease of participation for all investors.

## Tokenomics

### Initial Parameters
- **Total Supply:** Equal to the initial top 100 crypto market cap (denominated in C100 units).
- **Initial Price:** Approximately $1 per C100 token, assuming pairing with a stable asset in a DEX.

### Distribution (Owner Allocation & ICO)
- **Owner Allocation:** 10% of total supply is retained by the owner for development, liquidity provision, and other strategic purposes.
- **ICO Allocation:** 90% of total supply is allocated for the Initial Coin Offering (ICO), enabling widespread distribution and community participation.

### Rebase Formula ("Genius" Formula)
**ratio = M_new / M_old**  
- **New Supply = Old Supply * ratio**  
- Every holder’s balance is multiplied by the same ratio.

This ensures fair and transparent tracking of the market cap changes.

### Market Dynamics and Price Stability
If the market cap doubles, all balances double, maintaining the token’s value reference. As the community matures and markets become more efficient, the token price should remain stable around its baseline in response to these proportional adjustments.

### Liquidity Provider Rewards
A dedicated percentage of the supply changes during rebases is allocated as rewards to liquidity providers. Initially set to 5%, this can be adjusted up to 10% based on governance decisions. This incentivizes users to provide liquidity, ensuring deep liquidity pools, reducing slippage, and fostering a robust trading environment.

### Fee-Based Treasury
When enabled, transfer fees are collected and sent to a designated treasury address. This mechanism supports the growth and sustainability of the project by funding development, marketing, audits, and other strategic initiatives.

## Technical Architecture

### Polygon Network
Deployed on Polygon for low gas fees and high throughput, ensuring efficient and cost-effective transactions for users.

### C100 Token Contract
Implements ERC20 standards, rebase logic, ownership control, pause/unpause functionalities, transfer fee mechanisms, liquidity provider rewards allocation, and integration points for future governance.

### ICO (Public Sale) Contract
Handles the initial distribution of 90% tokens. Investors purchase C100 with POL or approved ERC20 tokens (e.g., USDC) during the ICO period. Unsold tokens are burned at the end, ensuring only the circulating supply reflects real participants. Additionally, during the ICO, a configurable reward percentage is allocated to liquidity providers from the transaction fees to incentivize liquidity provisioning.

### Scaling and GonsPerFragment
Balances are tracked in a large integer unit called “gons.” The global `gonsPerFragment` variable determines how these translate into user balances. On rebase, adjusting `gonsPerFragment` updates everyone’s balance proportionally in O(1) complexity.

### Dynamic `polRate` Mechanism
The `polRate` is dynamically determined based on the reserves in the `C100-POL` liquidity pool. If unavailable, it falls back to the `C100-USDC` pool using a predefined `polInUSDCRate`. This ensures accurate pricing aligned with market conditions.

## Governance

### Transition from Owner to Governor
Initially, the owner manages the contract. Later, a governor contract can be introduced. The governor can propose and vote on changes (parameters, treasury usage, etc.), enabling community-driven evolution.

### Future Governor Contract
By deploying a governor contract and timelock controller, the project gradually moves towards full decentralization. Governance token holders can vote on upgrades, new features, or parameter changes (e.g., adjusting the rebase frequency, transfer fees, or liquidity rewards).

### Community Involvement
Over time, the community will shape the project’s future. They can propose:
- Adjusting parameters (fees, rebase frequency)
- Allocating treasury funds for development, marketing, or liquidity
- Introducing new features or improvements
- Managing liquidity provider reward percentages

## Security

### Ownership Controls
The `onlyAdmin` modifiers ensure that only authorized parties (owner or governor) can make critical changes, safeguarding the contract against unauthorized modifications.

### Pause/Unpause Mechanisms
The contract can be paused in emergencies, preventing transfers and safeguarding against exploits during uncertain times.

### Reentrancy Guards
NonReentrant modifiers protect against complex reentrancy attacks, ensuring safe execution of functions like buying tokens or rebasing.

### Audits and Best Practices
Smart contract auditing and community code reviews will enhance trust and security. Following industry standards, best practices, and thorough testing before mainnet deployment is crucial.

### Token Rescue and Burning
Admins can rescue non-C100 tokens sent to the contract and burn unsold C100 tokens post-ICO. Additionally, tokens can be burned from the treasury to manage supply and support market stability.

## Roadmap
- **Phase 1:** Token and ICO launch, manual upkeep.
- **Phase 2:** Introduce governance, set governor contract.
- **Phase 3:** Integrate oracles for automated updates.
- **Phase 4:** Community-driven proposals for enhancements, treasury usage, fee adjustments.
- **Phase 5:** Implement configurable liquidity provider reward mechanisms, scaling, and ecosystem expansion.
- **Phase 6:** Ongoing refinement, security audits, and feature additions based on community feedback.

## ICO Plan (Simplicity-Focused)

### ICO Parameters
- **Duration:** 12 months.
- **Accepted Currencies:** POL, USDC, and other approved ERC20 tokens.
- **Rate:** Fixed C100 per POL/USDC, with dynamic updates based on `polRate`.
- **Liquidity Provider Reward:** Configurable percentage of transaction fees allocated to liquidity providers during the ICO.

### During the ICO
- **Purchases:** Investors buy C100 directly from the public sale contract using POL or approved ERC20 tokens.
- **Rebase Operations:** Owner or governor periodically calls rebase to keep C100 supply aligned with the top 100 market cap.
- **Liquidity Provision:** Liquidity providers contribute to the C100-POL and C100-USDC liquidity pools and earn rewards based on their contribution.

### Post-ICO Finalization and Burning Unsold Tokens
At the end of the ICO:
- **No More Purchases:** ICO phase concludes, preventing further token sales.
- **Burn Unsold Tokens:** Any unsold tokens are burned, ensuring the supply reflects only actively held tokens.

### Maintaining the Index Post-ICO
After the ICO:
- **Continuous Rebasing:** Continue daily/periodic rebases to adjust supply based on market cap changes.
- **Automated Upkeep:** Transition to automated rebase operations using oracles and governance decisions.
- **Governance Enhancements:** Introduce advanced features such as treasury management, automated liquidity rewards, and fee adjustments through community proposals.

### Liquidity Provider Participation During ICO
- **Incentives:** During the ICO, liquidity providers are rewarded with a configurable percentage of the total transaction fees generated.
- **Participation:** Anyone can become a liquidity provider by adding C100 and POL (MATIC) or other approved tokens to supported DEXs.
- **Rewards Distribution:** Rewards are distributed proportionally based on the amount of liquidity each provider contributes, ensuring fair compensation for contributions.

---

## FAQ (112 Questions & Answers)

1. **Q:** What is COIN100 (C100)?  
   **A:** It’s a decentralized index fund token on Polygon, tracking the top 100 cryptos by market cap.

2. **Q:** How does C100 track the top 100 crypto market cap?  
   **A:** Through a global rebase mechanism. As the total market cap changes, the supply and balances adjust proportionally.

3. **Q:** Is C100 an ERC20 token?  
   **A:** Yes, it follows the ERC20 standard with additional rebasing logic.

4. **Q:** On which network is C100 deployed?  
   **A:** Polygon (POL) network.

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

16. **Q:** What happens to the remaining 90% at launch?  
    **A:** It’s used for ICO or directly to provide liquidity and let the market buy freely.

17. **Q:** Is there an ICO?  
    **A:** Yes, the owner may run an ICO to distribute the 90% of tokens.

18. **Q:** What if not all tokens sell in the ICO?  
    **A:** Unsold tokens are burned at the end of the ICO.

19. **Q:** Why burn unsold tokens?  
    **A:** To ensure the supply accurately reflects actively held tokens, maintaining fairness and index integrity.

20. **Q:** Can I buy C100 after the ICO?  
    **A:** Yes, on DEXs where liquidity is provided by the owner and early participants.

21. **Q:** Will there be a stable price?  
    **A:** Price aims to stay near the index-based reference. Market forces and arbitrage help maintain this.

22. **Q:** Does C100 pay dividends?  
    **A:** Not directly. The value accrues by tracking the market cap of top 100 cryptos.

23. **Q:** How do I store C100?  
    **A:** In any Polygon-compatible ERC20 wallet.

24. **Q:** How do I track the top 100 market cap changes?  
    **A:** Initially, trust the owner’s manual updates. Later, an oracle might provide on-chain data.

25. **Q:** Is the contract audited?  
    **A:** The team plans for audits before mainnet release.

26. **Q:** Can C100 be paused?  
    **A:** Yes, the admin can pause the contract in emergencies.

27. **Q:** Why pause the contract?  
    **A:** To prevent malicious exploitation during unexpected issues.

28. **Q:** What is `gonsPerFragment`?  
    **A:** An internal scaling factor that efficiently adjusts balances during rebases.

29. **Q:** Does rebase affect my token count in my wallet?  
    **A:** Yes, your balance number changes, but proportionally to everyone else’s, preserving your share.

30. **Q:** Can I lose my fraction of ownership?  
    **A:** Not due to rebases. Your fraction relative to total supply remains constant (unless you trade).

31. **Q:** What if someone doesn’t trust the owner’s data?  
    **A:** Eventually, governance and oracles will automate and decentralize updates, reducing trust issues.

32. **Q:** Could governance change the parameters?  
    **A:** Yes, once set, governance can vote on parameters like rebase frequency, fees, or treasuries.

33. **Q:** Will there be a treasury?  
    **A:** Yes, a fee-based treasury is introduced. Governance can introduce treasury fees and funds to support project growth.

34. **Q:** How would treasury fees work?  
    **A:** A portion of transaction fees can be enabled to go to a treasury wallet, later allocated by governance.

35. **Q:** What is the benefit of a treasury?  
    **A:** It supports future development, marketing, audits, or liquidity incentives.

36. **Q:** Is there a whitelist or KYC?  
    **A:** No. Anyone on Polygon can buy C100; it’s permissionless.

37. **Q:** Can I sell C100 anytime?  
    **A:** Yes, on any DEX where liquidity is available.

38. **Q:** Is C100 inflationary?  
    **A:** Rebase adjusts supply proportionally. It’s not traditional inflation; it’s a representation of the index.

39. **Q:** Does market cap growth dilute existing holders?  
    **A:** No, growth increases everyone’s balance proportionally.

40. **Q:** If the index grows, do I earn more tokens?  
    **A:** Yes, your token balance increases on rebase events.

41. **Q:** Can governance remove the owner’s rights?  
    **A:** Yes, if coded accordingly, after governance takes over, the owner can relinquish control.

42. **Q:** What if governance makes bad decisions?  
    **A:** Governance is controlled by token holders. It’s community-driven. If bad proposals pass, that’s a community risk.

43. **Q:** Can I propose changes without being the governor?  
    **A:** Typically, you need a minimum token amount to propose. Details depend on the governor contract design.

44. **Q:** Will the token’s name or symbol change?  
    **A:** Unlikely. It’s set at deployment.

45. **Q:** How do I add C100 to my wallet interface?  
    **A:** Import the token’s contract address into your Polygon-compatible wallet.

46. **Q:** Are rebases taxable events?  
    **A:** Consult a tax professional. Tax treatment may vary by jurisdiction.

47. **Q:** Is there a minimum or maximum investment?  
    **A:** No strict limits by the contract. Market liquidity and token price determine practical limits.

48. **Q:** What if I buy right before a rebase?  
    **A:** Your purchase includes the upcoming rebase changes. You neither gain nor lose unfairly.

49. **Q:** Do I need to claim my rebased tokens?  
    **A:** No. Rebase updates balances automatically.

50. **Q:** How often will the owner rebase initially?  
    **A:** Possibly daily, but it’s flexible. The owner decides until governance sets rules.

51. **Q:** Will there be an official oracle integration?  
    **A:** In the future, yes, to automate market cap updates.

52. **Q:** Can governance integrate Chainlink oracles?  
    **A:** Yes, governance can approve contracts and integrate reliable oracles.

53. **Q:** Are there smart contract upgrade plans?  
    **A:** Possibly. With governance, changes can be proposed and voted on, potentially including upgrades.

54. **Q:** What if Polygon network faces issues?  
    **A:** The token resides on Polygon. Any network-wide issues affect all tokens equally.

55. **Q:** Is there a limit to how large the top 100 crypto market cap can grow?  
    **A:** Practically no. As it grows, C100 supply and balances grow proportionally.

56. **Q:** How do I know the top 100 composition?  
    **A:** Initially off-chain data. In the future, oracles or references can be introduced on-chain.

57. **Q:** Does composition of the top 100 matter for holders?  
    **A:** Not directly. You always hold a fraction of the total cap, regardless of composition changes.

58. **Q:** What if the top 100 changes (some coins leave, others enter)?  
    **A:** The index’s total cap changes, reflected at next rebase. No direct action needed by holders.

59. **Q:** Can I use C100 in DeFi (lending, staking)?  
    **A:** Potentially yes, if DeFi protocols support C100.

60. **Q:** Is there a whitepaper available?  
    **A:** This README and future documentation serve as a whitepaper. Detailed docs are planned.

61. **Q:** Will the contract be verified on PolygonScan?  
    **A:** Yes, for transparency and trust.

62. **Q:** How do I participate in governance voting?  
    **A:** Acquire enough C100 to vote, and interact with the governor contract once deployed.

63. **Q:** Can governance freeze rebases?  
    **A:** If coded, yes, governance might pause or adjust rebase conditions.

64. **Q:** Is there a maximum supply cap?  
    **A:** No hard cap. Supply floats with market cap.

65. **Q:** Could C100 track a different index in the future?  
    **A:** Governance could propose changing index parameters if such flexibility is allowed.

66. **Q:** Does the token have a logo?  
    **A:** Initially, a simple logo. The community can decide on rebranding later.

67. **Q:** Are there any partnerships?  
    **A:** Partnerships may be pursued. Check announcements.

68. **Q:** Will liquidity be locked?  
    **A:** Owner or governance may decide on liquidity locking for trust.

69. **Q:** Does C100 rely on a single entity?  
    **A:** Initially owner-managed, aiming to evolve into fully decentralized governance.

70. **Q:** Can C100 survive if the owner disappears?  
    **A:** Once governance is established, yes. The project can run autonomously.

71. **Q:** How can I suggest improvements?  
    **A:** Join Discord, Reddit, or submit proposals once governance is live.

72. **Q:** Can I fork C100?  
    **A:** The code is open-source. Others can fork, but trust, community, and liquidity matter.

73. **Q:** Will large holders influence votes heavily?  
    **A:** Yes, governance is token-weighted. More tokens mean more voting power.

74. **Q:** Could governance introduce fees on transfers?  
    **A:** Yes, if proposals pass, a fee could be implemented.

75. **Q:** Where do fees go if introduced?  
    **A:** Fees are sent to the treasury for project development, marketing, and other strategic uses.

76. **Q:** How is treasury managed?  
    **A:** By governance votes on how to allocate or use funds.

77. **Q:** Can I redeem my tokens for underlying assets?  
    **A:** No direct redemption. C100 is synthetic exposure, not a claim on underlying coins.

78. **Q:** What if the top 100 index calculation method changes?  
    **A:** Governance could adapt the model if needed.

79. **Q:** How frequently is market cap data updated manually?  
    **A:** Initially at owner’s discretion. Possibly daily or weekly until automated.

80. **Q:** Does holding C100 require any special steps?  
    **A:** No, just hold it in a Polygon-compatible wallet.

81. **Q:** Is there a minimum gas token needed?  
    **A:** Yes, POL for gas fees on Polygon.

82. **Q:** Can I bridge C100 to other chains?  
    **A:** Possibly in the future if bridges support it.

83. **Q:** Will listing on centralized exchanges happen?  
    **A:** Up to exchanges’ interest. The community can encourage listings.

84. **Q:** Does C100 track stablecoins in the top 100?  
    **A:** If stablecoins are in top 100 by market cap, they are included. It’s a neutral index.

85. **Q:** Are smart contract addresses known at launch?  
    **A:** Yes, published once deployed and verified.

86. **Q:** Will there be a testnet version?  
    **A:** Likely, for community testing before mainnet.

87. **Q:** Does the token support EIP-2612 (permit)?  
    **A:** Not initially. Could be added by governance if desired.

88. **Q:** Is there a referral program?  
    **A:** Not currently. Community can propose incentive programs later.

89. **Q:** How is liquidity provided initially?  
    **A:** Owner adds initial liquidity to a DEX, possibly at $1/C100.

90. **Q:** Can I track C100 price on aggregators?  
    **A:** Yes, once listed, price data will appear on coin trackers.

91. **Q:** Is C100 correlated with Bitcoin/Ethereum alone?  
    **A:** It’s correlated with the entire top 100 cryptos, not just one coin.

92. **Q:** Can I short C100?  
    **A:** Only if a DeFi platform offers derivatives. C100 doesn’t provide native shorting.

93. **Q:** Does C100 have a roadmap for oracle integration?  
    **A:** Yes, after community matures, oracles may automate index tracking.

94. **Q:** What if no one calls rebase?  
    **A:** Then the index isn’t updated. Market price may drift from $1. Eventually governance or oracles will handle this.

95. **Q:** Will the team remain anonymous?  
    **A:** The team may reveal themselves over time. Governance reduces reliance on team identity.

96. **Q:** Is the code open source?  
    **A:** Yes, allowing transparency and community audits.

97. **Q:** How do I get support?  
    **A:** Via email, Discord, Reddit, or X as listed in Contact Information.

98. **Q:** Why trust C100 over other tokens?  
    **A:** C100 provides a broad, fair, and transparent index exposure with a clear path to decentralization and community governance.

99. **Q:** How are liquidity providers rewarded?  
    **A:** Liquidity providers receive a configurable percentage of the supply changes during rebases as rewards. This incentivizes providing liquidity and ensures a healthy trading environment.

100. **Q:** What is the configurable LP reward percentage?  
     **A:** Initially set to 5%, it can be adjusted up to a maximum of 10% based on governance decisions.

101. **Q:** How is the `polRate` updated dynamically?  
     **A:** The `polRate` is calculated based on the reserves in the `C100-POL` pool. If unavailable, it falls back to the `C100-USDC` pool using a predefined `polInUSDCRate`.

102. **Q:** Can the `polRate` be updated without a rebase?  
     **A:** No, the `polRate` is tied to the rebase mechanism and is updated alongside market cap adjustments.

103. **Q:** How are liquidity providers rewarded during the ICO?  
     **A:** Liquidity providers receive a configurable percentage of the total supply changes allocated as rewards during rebases, incentivizing providing liquidity and ensuring a stable and liquid trading environment.

104. **Q:** Can I become a liquidity provider for C100?  
     **A:** Yes, anyone can provide liquidity by adding C100 and POL (MATIC) or other approved tokens to a supported DEX. In return, you earn a share of the configurable reward based on your contribution.

105. **Q:** How does governance update the `polRate` in the public sale contract?  
     **A:** During each rebase, the `C100` contract calculates the new `polRate` and updates it in the `publicSaleContract` via the `updatePOLRate` function, ensuring that the rate remains aligned with current market conditions.

106. **Q:** Can governance adjust the liquidity provider reward percentage?  
     **A:** Yes, governance can propose and vote on changes to the liquidity provider reward percentage, allowing the community to adjust incentives as needed.

107. **Q:** How secure are the liquidity rewards?  
     **A:** Liquidity rewards are managed through smart contracts with rigorous security audits to ensure that funds are distributed fairly and without vulnerabilities.

108. **Q:** What measures are in place to prevent exploitation of the rebase mechanism?  
     **A:** The rebase mechanism is governed by decentralized governance and audited smart contracts, minimizing the risk of exploitation. Additionally, any changes to the rebase logic require community approval.

109. **Q:** Where are the treasury funds stored?  
     **A:** Treasury funds are held in a secure, multi-signature wallet controlled by the governance contract to ensure transparency and security.

110. **Q:** Can treasury funds be used for liquidity provider rewards?  
     **A:** Yes, governance can allocate treasury funds to support liquidity provider rewards or other community incentives as needed.

111. **Q:** How do liquidity provider rewards impact the market?  
     **A:** Liquidity provider rewards encourage more liquidity, reducing price volatility and improving the trading experience for all users.

112. **Q:** Are there community-led initiatives for liquidity?  
     **A:** Yes, community proposals can include initiatives to enhance liquidity, such as incentive programs or partnerships with liquidity pools.

---

## Contact Information
For further inquiries, support, or to engage with the COIN100 team, please reach out through the following channels:

- **Website:** [https://coin100.link](https://coin100.link)
- **Email:** [mayor@coin100.link](mailto:mayor@coin100.link)
- **Discord:** [Join Our Discord](https://discord.com/channels/1312498183485784236/1312498184500674693)
- **Reddit:** [r/Coin100](https://www.reddit.com/r/Coin100)
- **X:** [@Coin100token](https://x.com/Coin100token)
- **coin100:** `0x1459884924e7e973d1579ee4ebcaa4ef0b1c8f21`
- **publicSale:** `0x2cdac1848b1c14d36e173e10315da97bb17b5489`

---

## Conclusion
COIN100 (C100) provides a seamless, fair, and transparent way to invest in the top 100 cryptocurrencies. Through a global rebase mechanism, dynamic pricing adjustments, fee-based treasury growth, configurable liquidity provider incentives, and robust security, it aims to become a trusted and stable representation of the crypto market’s collective growth. With a clear path towards decentralized governance and community-driven evolution, C100 empowers investors to participate in a diversified crypto index without the complexities of active portfolio management. Join the community, contribute to liquidity provisioning, and help shape the future of decentralized index investing.
