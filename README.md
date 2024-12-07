# COIN100 (C100)
****COIN100** is a decentralized cryptocurrency index fund built on the polygon network. It represents the top 100 cryptocurrencies by market capitalization, offering users a diversified portfolio that mirrors the performance of the overall crypto market. Inspired by traditional index funds like the S&P 500, COIN100

**Ultimate Goal:** To dynamically track and reflect the top 100 cryptocurrencies by market capitalization, ensuring that COIN100 remains a relevant and accurate representation of the cryptocurrency market.

**Contract Address:** [0xdbe819ddf0d14a54ffe611c6d070b32a7f9d23d1](https://polygonscan.com/token/0xdbe819ddf0d14a54ffe611c6d070b32a7f9d23d1)

## Installation and Deployment

### Local Development
1. Clone the repository
2. Install dependencies:
```bash
npm install
```
3. Create a `.env` file with the required environment variables
4. Start the development server:
```bash
npm start
```

### Production Deployment with PM2
PM2 is used for process management in production. Here are the common commands:

#### Starting/Restarting the Service
```bash
# Restart if exists, otherwise start new instance
pm2 restart coin100-api || pm2 start /home/ec2-user/coin100Api/index.js --name "coin100-api"
```

#### Monitoring
```bash
# View logs in real-time
pm2 logs coin100-api

# View last 1000 lines of logs
pm2 logs coin100-api --lines 1000

# View dashboard
pm2 monit
```

#### Other Useful PM2 Commands
```bash
# List all processes
pm2 list

# Stop the service
pm2 stop coin100-api

# Delete the service
pm2 delete coin100-api

# View process details
pm2 show coin100-api
```

## Table of Contents

1. [Introduction](#introduction)
2. [Problem Statement](#problem-statement)
3. [Solution: COIN100 (C100) Token](#solution-coin100-c100-token)
4. [Features](#features)
    - [Decentralized Index Fund](#decentralized-index-fund)
    - [Dynamic Rebase Mechanism](#dynamic-rebase-mechanism)
    - [Automated Rewards Distribution](#automated-rewards-distribution)
    - [Governance and Security](#governance-and-security)
5. [Tokenomics](#tokenomics)
    - [Total Supply](#total-supply)
    - [Distribution](#distribution)
    - [Transaction Fees](#transaction-fees)
    - [Fee Allocation](#fee-allocation)
6. [Technical Architecture](#technical-architecture)
    - [Smart Contract Overview](#smart-contract-overview)
    - [Price Feeds and Oracles](#price-feeds-and-oracles)
    - [Uniswap Integration](#uniswap-integration)
7. [Governance](#governance)
8. [Security](#security)
9. [Roadmap](#roadmap)
10. [Team](#team)
11. [Community and Social Media](#community-and-social-media)
12. [Frequently Asked Questions (FAQ)](#frequently-asked-questions-faq)
13. [Contact Information](#contact-information)

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

### Distribution

- **Public Sale + Treasury:** 90% (900,000,000 C100)
- **Developer Allocation:** 5% (50,000,000 C100)
- **Rewards Pool:** 5% (50,000,000 C100)

### Transaction Fees

- **Total Fee Percent:** 3% per transaction
    - **Developer Fee:** 1.2% (40% of total fees)
    - **Burn Fee:** 1.2% (40% of total fees)
    - **Reward Fee:** 0.6% (20% of total fees)

### Fee Allocation

- **Developer Fee:** Allocated to the developer wallet for ongoing development and operational costs.
- **Burn Fee:** Tokens are burned, reducing the total supply and potentially increasing the value of remaining tokens.
- **Reward Fee:** Accumulated in the rewards pool and distributed to token holders based on their stake.

## Technical Architecture

### Smart Contract Overview

The C100 smart contract is built using Solidity ^0.8.20 and leverages OpenZeppelin's robust library for secure and efficient contract development. Key functionalities include:

- **ERC20 Standard:** Ensures compatibility with existing wallets and exchanges.
- **Pausable:** Allows the contract owner or governor to pause all token transfers in case of emergencies.
- **Ownable:** Establishes ownership controls for administrative functions.
- **ReentrancyGuard:** Protects against reentrancy attacks, enhancing contract security.

### Price Feeds and Oracles

COIN100 integrates Chainlink's AggregatorV3Interface to obtain reliable price feeds for MATIC/USD and C100/USD. These oracles ensure accurate and tamper-proof pricing data, essential for the dynamic rebase mechanism and reward distribution.

### Uniswap Integration

The contract interacts with Uniswap V2's router and factory interfaces to manage liquidity pools and facilitate token swaps. By creating a pair with WMATIC, C100 ensures liquidity and enables seamless trading on decentralized exchanges.

## Governance

Governance is a critical aspect of COIN100, allowing for decentralized decision-making and adaptability. Initially, the contract owner has administrative control. However, a governor role can be set to transition governance to a dedicated address, promoting decentralization and community involvement. The governor can manage parameters such as fees, wallet addresses, router settings, and price feeds.

## Security

Security is paramount for COIN100. The contract incorporates multiple security measures:

- **Pausable Functionality:** Enables halting of all transfers during suspicious activities or emergencies.
- **Ownership Controls:** Restricts administrative functions to authorized entities.
- **Reentrancy Protection:** Guards against reentrancy attacks, ensuring contract integrity.
- **External Audits:** Regular audits by reputable firms are recommended to identify and mitigate vulnerabilities.

## Roadmap

1. **Q1 2024:**  
    - Smart contract development and internal testing.
    - Community building and initial marketing campaigns.
    - Deployment on the Polygon network.
    - Listing on major DEXs.

2. **Q2 2024:**  
    - Integration with Chainlink oracles.
    - Launch of liquidity pools and staking mechanisms.

3. **Q3 2024:**  
    - Implementation of governance features.
    - Expansion of reward distribution systems.
    - Strategic partnerships and collaborations.

4. **Q4 2024:**  
    - Launch of advanced features such as automated portfolio rebalancing.
    - Continuous security audits and upgrades.
    - Global marketing and user acquisition initiatives.

## Team

The COIN100 team comprises experienced professionals from blockchain development, finance, and marketing sectors. Our collective expertise ensures the successful development, deployment, and growth of the C100 token.

*Details about the team members can be added here.*

## Community and Social Media

Engage with the COIN100 community through our various social media channels:

- **Website:** [https://coin100.link](https://coin100.link)
- **Reddit:** [r/Coin100](https://www.reddit.com/r/Coin100)
- **Discord:** [Join Our Discord](https://discord.com/channels/1312498183485784236/1312498184500674693)
- **X:** [@Coin100token](https://x.com/Coin100token)

Stay updated with the latest news, participate in discussions, and contribute to the future of COIN100.

## Frequently Asked Questions (FAQ)

### General

1. **What is COIN100 (C100)?**  
   COIN100 (C100) is a decentralized cryptocurrency index fund built on the Polygon network, representing the top 100 cryptocurrencies by market capitalization.

2. **How does COIN100 work?**  
   C100 aggregates the top 100 cryptocurrencies, allowing holders to gain diversified exposure through a single token. The smart contract manages token distribution, fees, and rewards based on market dynamics.

3. **Why choose COIN100 over individual cryptocurrency investments?**  
   C100 offers diversification, reducing the risk associated with individual assets. It simplifies portfolio management and mirrors the performance of the overall crypto market.

4. **On which blockchain is COIN100 deployed?**  
   COIN100 is deployed on the Polygon network, ensuring low transaction fees and high scalability.

5. **What are the benefits of holding C100 tokens?**  
   Benefits include diversified exposure, participation in a dynamic index fund, rewards distribution, and potential token value appreciation through burn mechanisms.

### Tokenomics

6. **What is the total supply of C100 tokens?**  
   The total supply is 1,000,000,000 C100 tokens.

7. **How is the total supply of C100 distributed?**  
   - 90% for Public Sale and Treasury  
   - 5% for Developer Allocation  
   - 5% for Rewards Pool

8. **Are there any minting or burning mechanisms?**  
   Yes, the contract includes burning mechanisms based on transaction fees and dynamic rebasing to adjust the total supply in response to market conditions.

9. **What are the transaction fees associated with C100?**  
   A total fee of 3% per transaction is applied, divided into 1.2% for developers, 1.2% burned, and 0.6% allocated to rewards.

10. **Can transaction fees be changed?**  
    Yes, the admin (owner or governor) can update the fee percentages within defined limits through governance functions.

### Rewards

11. **How are rewards distributed to C100 holders?**  
    A portion of transaction fees is allocated to a rewards pool. Holders can claim their rewards based on their stake and participation in the liquidity pool.

12. **What determines the reward rate?**  
    The reward rate adjusts based on the token's price. Lower prices yield higher rewards to incentivize holding, while higher prices reduce rewards to maintain sustainability.

13. **How often are rewards distributed?**  
    Rewards are distributed upon successful upkeep operations, which are performed at least once every seven days.

14. **Can rewards be claimed automatically?**  
    Currently, rewards must be claimed manually by holders through the `claimRewards` function in the smart contract.

15. **What happens if there are insufficient rewards in the pool?**  
    The contract ensures that only available rewards are distributed. If insufficient, the distribution amount is adjusted accordingly.

### Governance

16. **Who can govern the COIN100 protocol?**  
    Initially, the contract owner has administrative control. Once a governor is set, governance shifts to the designated governor address.

17. **Can the governor be changed?**  
    The governor can be set only once by the owner and cannot be changed thereafter, ensuring a stable governance structure.

18. **What governance actions can the governor perform?**  
    The governor can update fees, wallet addresses, router settings, price feeds, rebase intervals, and other critical parameters.

19. **Is governance decentralized?**  
    Governance is centralized initially but can transition to a more decentralized model by setting a governor, potentially allowing for community governance in the future.

20. **Are there any governance tokens?**  
    Currently, governance is managed through the C100 token holders and the designated governor, without a separate governance token.

### Technical

21. **Is the C100 smart contract audited?**  
    Security audits are recommended and may be conducted by reputable firms to ensure contract integrity and safety.

22. **What security measures are in place?**  
    The contract includes pausability, ownership controls, and reentrancy protection to safeguard against common vulnerabilities.

23. **Can the contract be paused?**  
    Yes, authorized entities (owner or governor) can pause all token transfers in case of emergencies or suspicious activities.

24. **How does the dynamic rebase mechanism work?**  
    The contract adjusts the token supply based on the total market capitalization, minting or burning tokens within defined limits to maintain price stability.

25. **What happens during a rebase?**  
    If the market cap exceeds or falls below certain thresholds, the contract mints or burns tokens accordingly, ensuring the token remains a true representation of the index.

### Market and Liquidity

26. **Where can I buy or sell C100 tokens?**  
    C100 is available on major decentralized exchanges (DEXs) like Uniswap. Check the website for specific listings.

27. **Is there a liquidity pool for C100?**  
    Yes, a liquidity pool with WMATIC is created on Uniswap V2 to facilitate trading and ensure liquidity.

28. **Can I provide liquidity to the C100 pool?**  
    Yes, users can provide liquidity to the C100/WMATIC pair on Uniswap to earn fees and rewards.

29. **What ensures liquidity for C100 tokens?**  
    Initial liquidity is provided by the contract, and ongoing liquidity is maintained through user participation and strategic partnerships.

30. **Are there any incentives for providing liquidity?**  
    Yes, liquidity providers may earn rewards from transaction fees and additional incentives from the rewards pool.

### Usage and Integration

31. **Can C100 be integrated into other DeFi platforms?**  
    Yes, C100 can be integrated into various DeFi applications, including lending platforms, yield aggregators, and portfolio management tools.

32. **Is there a staking mechanism for C100?**  
    Currently, staking is managed through liquidity provision and rewards distribution. Future updates may include dedicated staking pools.

33. **How can I participate in the COIN100 ecosystem?**  
    Participate by holding C100 tokens, providing liquidity, claiming rewards, and engaging in governance decisions.

34. **Are there any partnerships planned for COIN100?**  
    Strategic partnerships are part of the roadmap to enhance utility, liquidity, and adoption of C100.

35. **Can developers build on top of the C100 protocol?**  
    Yes, developers can integrate C100 into their applications, leveraging its decentralized index fund features.

### Financial

36. **How does the burn mechanism affect the token price?**  
    Burning reduces the total supply, which can potentially increase the token's value by creating scarcity, assuming demand remains constant or increases.

37. **Is there a maximum cap on the number of tokens that can be burned?**  
    The contract enforces maximum burn amounts per rebase to prevent excessive burning and maintain supply stability.

38. **How are developer funds utilized?**  
    Developer fees support ongoing development, maintenance, marketing, and operational expenses to ensure the project's sustainability.

39. **Are there any vesting schedules for developer allocations?**  
    Details about vesting schedules can be implemented to ensure long-term commitment from developers and prevent large sell-offs.

40. **Can fees be increased beyond the initial percentage?**  
    Fees can be adjusted by the admin within predefined limits to balance between rewarding developers, burning tokens, and distributing rewards.

### Community and Support

41. **How can I stay updated with COIN100 developments?**  
    Follow our social media channels, join the Discord community, and subscribe to newsletters on our website.

42. **Is there a referral or affiliate program?**  
    Plans for referral programs may be introduced to incentivize community growth and engagement.

43. **Where can I seek support or ask questions?**  
    Join our Discord server, post on Reddit, or reach out through official communication channels listed on our website.

44. **Can I suggest features or improvements?**  
    Yes, community feedback is valuable. Suggestions can be submitted through governance proposals or community forums.

45. **Are there any community rewards or airdrops?**  
    Periodic community rewards or airdrops may be conducted to reward active participants and promote engagement.

### Legal and Compliance

46. **Is COIN100 compliant with regulations?**  
    Compliance measures are implemented to adhere to relevant regulations. Legal counsel is consulted to ensure adherence to jurisdictional requirements.

47. **Are there any KYC/AML requirements for C100 holders?**  
    Currently, there are no KYC/AML requirements for holding or transacting C100 tokens, promoting decentralization and accessibility.

48. **Can COIN100 be used in regulated financial products?**  
    Integration with regulated financial products depends on jurisdictional approvals and compliance with relevant laws.

49. **Is there a risk of regulatory changes affecting COIN100?**  
    Regulatory landscapes are dynamic. The project continuously monitors and adapts to ensure compliance and mitigate risks.

50. **How is user privacy handled?**  
    User privacy is maintained by adhering to best practices in smart contract development, ensuring no sensitive data is stored on-chain.

### Future Developments

51. **What are the future plans for COIN100?**  
    Future developments include advanced governance mechanisms, expanded integrations with DeFi platforms, enhanced reward systems, and continuous security enhancements.

52. **Will there be additional token utilities introduced?**  
    Potential utilities may include staking rewards, governance voting power, and integration with other financial instruments.

53. **How will COIN100 adapt to market changes?**  
    Through its dynamic rebase mechanism, governance flexibility, and responsive reward systems, COIN100 is designed to adapt to evolving market conditions.

54. **Are there plans to expand beyond the top 100 cryptocurrencies?**  
    Future iterations may consider expanding the index to include more assets or introducing different indices based on specific criteria.

55. **Can COIN100 integrate with centralized exchanges?**  
    Listings on centralized exchanges are part of the long-term strategy to enhance accessibility and liquidity.

### Miscellaneous

56. **What is the role of the Uniswap V2 Router in the C100 contract?**  
    The Uniswap V2 Router facilitates token swaps, liquidity pool creation, and interactions with the Uniswap ecosystem, ensuring seamless trading experiences.

57. **How does the contract handle price adjustments?**  
    Price adjustments are managed through Chainlink price feeds and Uniswap reserve data, allowing the contract to accurately track and respond to market cap changes.

58. **Is there a minimum holding period for C100 tokens?**  
    There is no enforced minimum holding period, but rewards distribution incentivizes long-term holding.

59. **How transparent is the COIN100 project?**  
    The project emphasizes transparency through open-source smart contracts, regular updates, and active community engagement.

60. **Can I integrate C100 into my own smart contract?**  
    Yes, developers can interact with the C100 contract via its public interfaces to integrate its functionalities into their applications.

### Technical Support

61. **What should I do if I encounter a bug or vulnerability?**  
    Report any bugs or vulnerabilities through official channels like the Discord server or via email to the development team for prompt resolution.

62. **Are there any tools or dashboards to monitor C100 performance?**  
    Tools and dashboards may be available on the website or through third-party integrations to track token performance, rewards, and market data.

63. **How are updates to the smart contract managed?**  
    Updates are managed through governance decisions, ensuring that any changes are transparent and agreed upon by authorized entities.

64. **Is the C100 contract upgradeable?**  
    The current contract design does not support upgrades. Future versions may consider upgradeability through proxy patterns if deemed necessary.

65. **What programming standards does the C100 contract adhere to?**  
    The contract follows Solidity best practices, adheres to the ERC20 standard, and utilizes OpenZeppelin's audited libraries for enhanced security.

### Investment

66. **Is COIN100 a good investment?**  
    As with all investments, especially in the cryptocurrency space, potential investors should conduct thorough research and consider risks before investing.

67. **What are the potential risks associated with C100?**  
    Risks include market volatility, smart contract vulnerabilities, regulatory changes, and liquidity challenges.

68. **How can I assess the performance of C100?**  
    Performance can be tracked through market data on exchanges, the project's website, and community dashboards that display key metrics.

69. **Does COIN100 have any insurance or protection mechanisms?**  
    Currently, there are no insurance mechanisms. Security measures are in place to protect against common vulnerabilities.

70. **Can I earn dividends from C100 holdings?**  
    Rewards distribution acts similarly to dividends, where a portion of transaction fees is allocated to holders based on their stake.

### Integration with Traditional Finance

71. **Can C100 be used as collateral in DeFi lending platforms?**  
    Integration with lending platforms depends on the platform's support for C100 tokens. Future collaborations may enable such use cases.

72. **Is there a way to convert C100 tokens to fiat?**  
    Through exchanges that support fiat gateways, users can convert C100 tokens to fiat currencies, depending on platform availability.

73. **Can institutional investors participate in C100?**  
    Yes, institutional investors can acquire C100 tokens through supported exchanges and participate in the ecosystem's benefits.

### Miscellaneous

74. **How is the developer wallet secured?**  
    The developer wallet employs multi-signature mechanisms and secure storage practices to protect funds and prevent unauthorized access.

75. **Are there any tax implications for holding or trading C100?**  
    Tax obligations vary by jurisdiction. Users should consult with tax professionals to understand their specific responsibilities.

76. **Can I recover my tokens if I lose access to my wallet?**  
    No, token recovery is not possible without access to the private keys. Users are advised to secure their wallets diligently.

77. **Does COIN100 support multiple languages?**  
    The project aims to support multiple languages in documentation and community channels to cater to a global audience.

78. **How does COIN100 compare to other crypto index funds?**  
    COIN100 differentiates itself through its dynamic rebase mechanism, integration with Polygon for scalability, and a robust rewards system.

79. **Are there any partnership opportunities with COIN100?**  
    Potential partners can reach out through official channels to explore collaboration opportunities that enhance the ecosystem.

80. **How does the rebase interval affect token supply?**  
    The rebase interval determines how frequently the token supply can be adjusted based on market cap changes, maintaining the token's alignment with the index.

81. **Is there a limit to how much I can earn in rewards?**  
    Rewards are proportionate to the stake and participation. There is no predefined cap, but sustainability is maintained through dynamic adjustments.

82. **Can I use C100 tokens in NFT marketplaces?**  
    If NFT marketplaces support ERC20 tokens on Polygon, C100 can potentially be used, subject to marketplace integration.

83. **How does the contract handle extreme market conditions?**  
    The dynamic rebase mechanism and fee adjustments help the contract adapt to extreme volatility, ensuring stability and alignment with the market.

84. **Is there a maximum number of tokens I can hold?**  
    No, there is no maximum holding limit. Users can acquire as many C100 tokens as they desire, subject to market availability.

85. **How does COIN100 ensure compliance with DeFi standards?**  
    By adhering to established ERC20 standards, integrating with reputable oracles like Chainlink, and following best security practices.

86. **Are there any hidden fees associated with C100?**  
    All fees are transparently defined in the smart contract and can be reviewed by users before participation.

87. **Can I transfer my C100 tokens to another blockchain?**  
    Currently, C100 is deployed on Polygon. Bridging to other blockchains would require integration with cross-chain protocols.

88. **How is the developer wallet funded?**  
    Developer fees from transaction allocations provide ongoing funding for development and operational expenses.

89. **Does COIN100 have a mobile application?**  
    Future developments may include mobile integrations for easier access and management of C100 tokens.

90. **Can I participate in governance without holding C100 tokens?**  
    Governance participation typically requires holding C100 tokens, aligning voting power with stake.

91. **How does the contract ensure fair distribution of rewards?**  
    Rewards are distributed based on the proportion of tokens held and participation in liquidity pools, ensuring fairness and alignment with contributions.

92. **What happens if the market cap data is incorrect?**  
    Reliance on Chainlink oracles ensures accurate data. In case of discrepancies, the contract includes safeguards to prevent manipulation.

93. **Is there a vesting period for tokens acquired through rewards?**  
    Currently, there is no vesting period, allowing immediate access to earned rewards.

94. **How does COIN100 handle token swaps and liquidity provision?**  
    Through integration with Uniswap V2, facilitating seamless swaps and liquidity management directly within the smart contract.

95. **Can I delegate my rewards to another address?**  
    The current contract does not support delegation. Rewards must be claimed and managed by the holder.

96. **Are there any plans for a mobile wallet integration?**  
    Future plans may include partnerships with mobile wallet providers to enhance accessibility and user experience.

97. **How can I participate in the initial token sale?**  
    Details about the initial token sale can be found on the official website and through official communication channels.

98. **What measures are in place to prevent market manipulation?**  
    The dynamic rebase mechanism, combined with decentralized governance, helps mitigate risks of market manipulation.

99. **Can I use C100 tokens for online purchases?**  
    Acceptance depends on merchant integrations. As adoption grows, more platforms may accept C100 as a payment method.

100. **How does COIN100 differentiate itself in the competitive crypto market?**  
    Through its unique dynamic rebase mechanism, robust governance structure, and comprehensive rewards system, C100 offers a balanced and innovative approach to cryptocurrency index funds.

## Contact Information

For further inquiries, support, or to engage with the COIN100 team, please reach out through the following channels:

- **Website:** [https://coin100.link](https://coin100.link)
- **Email:** [support@coin100.link](mailto:support@coin100.link)
- **Discord:** [Join Our Discord](https://discord.com/channels/1312498183485784236/1312498184500674693)
- **Reddit:** [r/Coin100](https://www.reddit.com/r/Coin100)
- **X:** [@Coin100token](https://x.com/Coin100token)
