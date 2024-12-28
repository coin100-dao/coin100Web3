# COIN100 Public Sale

This repository contains the smart contracts and deployment scripts for the COIN100 token and its public sale contract.

## Prerequisites

- Node.js (v14+ recommended)
- npm or yarn
- Git

## Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd coin100
```

2. Install dependencies:
```bash
npm install
```

3. Set up environment variables:
```bash
cp .env.example .env
```

Edit `.env` file and fill in your values:
- `ALCHEMY_API_KEY`: Your Alchemy API key for network access
- `PRIVATE_KEY`: Your wallet's private key (without 0x prefix)
- For public sale deployment:
  - `COIN100_ADDRESS`: Address of the deployed COIN100 token
  - `PAYMENT_TOKEN`: Payment token address (use zero address for ETH)
  - `RATE`: Exchange rate (e.g., 0.001 means 0.001 payment token per C100)
  - `TOKEN_SYMBOL`: Symbol of the payment token
  - `TOKEN_NAME`: Name of the payment token
  - `TOKEN_DECIMALS`: Decimals of the payment token

## Local Development and Testing

1. Start local Hardhat network:
```bash
npx hardhat node
```

2. Run tests:
```bash
npx hardhat test
```

3. Deploy contracts locally:
```bash
# Deploy COIN100 token
npx hardhat run scripts/deploy_coin100.js --network localhost

# Deploy Public Sale (after updating COIN100_ADDRESS in .env)
npx hardhat run scripts/deploy_public_sale.js --network localhost
```

## Production Deployment

### Option 1: Using Hardhat (Recommended for automated deployments)

1. Deploy to testnet first (e.g., Goerli):
```bash
npx hardhat run scripts/deploy_coin100.js --network goerli
npx hardhat run scripts/deploy_public_sale.js --network goerli
```

2. Once tested, deploy to mainnet:
```bash
npx hardhat run scripts/deploy_coin100.js --network mainnet
npx hardhat run scripts/deploy_public_sale.js --network mainnet
```

### Option 2: Using Remix (For manual deployments)

1. Install Remix IDE plugin in your browser
2. Copy the contract code from `contracts/` directory to Remix
3. Set up your environment in Remix:
   - Select appropriate Solidity version
   - Choose "Injected Web3" as your environment
4. Deploy process:
   - First deploy COIN100 token
   - Copy the deployed COIN100 address
   - Deploy C100PublicSale with the following parameters:
     - `_coin100`: The deployed COIN100 address
     - `_paymentToken`: Payment token address (zero address for ETH)
     - `_rate`: Rate in wei (e.g., "1000000000000000" for 0.001)
     - `_symbol`: Payment token symbol
     - `_name`: Payment token name
     - `_decimals`: Payment token decimals
     - `_treasury`: Treasury wallet address
     - `_startTime`: Unix timestamp for sale start
     - `_endTime`: Unix timestamp for sale end

## Contract Verification

After deployment, verify your contracts on Etherscan:

```bash
npx hardhat verify --network <network> <deployed-contract-address> "constructor" "arguments" "here"
```

## Security Considerations

- Always test thoroughly on testnet before mainnet deployment
- Keep private keys secure and never commit them to git
- Use a hardware wallet for production deployments
- Audit contracts before mainnet deployment

## Support

For any questions or issues, please open a GitHub issue or contact the development team. 