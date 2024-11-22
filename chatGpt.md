**COIN100** is a decentralized cryptocurrency index fund built on the Polygon network. It represents the top 100 cryptocurrencies by market capitalization, offering users a diversified portfolio that mirrors the performance of the overall crypto market. Inspired by traditional index funds like the S\&P 500, COIN100 aims to provide a secure, transparent, and efficient investment vehicle for both novice and experienced crypto investors.

**Ultimate Goal:** To dynamically track and reflect the top 100 cryptocurrencies by market capitalization, ensuring that COIN100 remains a relevant and accurate representation of the cryptocurrency market.



its 2024 so lets use newest best practice 
in my project i have this in json 
{
  "name": "coin100",
  "version": "1.0.0",
  "description": "## **Table of Contents**",
  "main": "index.js",
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "keywords": [],
  "author": "",
  "license": "ISC",
  "devDependencies": {
    "@eslint/js": "^9.15.0",
    "@nomicfoundation/hardhat-verify": "^2.0.12",
    "@nomiclabs/hardhat-ethers": "^2.2.3",
    "@nomiclabs/hardhat-waffle": "^2.0.6",
    "chai": "^5.1.2",
    "eslint": "^9.15.0",
    "ethereum-waffle": "^4.0.10",
    "ethers": "^5.7.2",
    "globals": "^15.12.0",
    "hardhat": "^2.22.16",
    "prettier": "^3.3.3",
    "solc": "^0.8.28"
  },
  "dependencies": {
    "@openzeppelin/contracts": "^4.9.2",
    "dotenv": "^16.4.5"
  }
}


test net is amoy 

so now we need the contract 
mint 1 billion (or a better suitable number ofr this project)
contract will have 5% depositted to developer address 

we need a liquidity wallet 5%
rest is public sale 

then we need to introduce fees on transactions 0.3% for both developer wallet and liquidity wallet 
keep in mind that we wont add liquidty in the beggining it'll be from fees 
but we need to adjust the coin price based on top 100 coin in marekt cap so we need a modern way of tracking that and adjusting price without spending tokens to adjust 
so when you give me plan, give me first Dynamic Price Adjustment via chainlink ... give me full steps with production ready examples .... full code for all ... need to bootstrap this quickly and cheaply
decide quickest chainlink data feed ... write the full code for the feed and dynamic price adjustment
you'll give me steps to testing chainlink locally 
developer can mint more and can burn based on need ... developer can do anything with the contract ... think of all the function that controls future values and minting and all and add them 
how could that be done ???
give me a full plan 
need easiest way of tracking market caps 
keep in mind initial token sale is at $0.01 , so give e steps to decide that value somehow
you'll finally give me steps to test both chainlink data logic then the contract locally before we deploy to amoy testnet(do we need balance from faucet?) 
then deploy to prod 
dont make it complicated ... this is mvp ..... we need to launch it quick and very very cheap 
whats the easiest way ( but production ready ) to create a token that tracks topp100 coins ? similar to s&p500 

what needs to be done .. whats the algorithm ... how do we value the initial token launch for 0.01 a token and how we increae its values ? 
whats the easiest way to dynamically adjust the price based on 100 top coins in market cap and if that market cap changes ? 
dont use '//your-api-endpoin' just use live coingecko example 

provide the full logic for burrning and minting to track coins and change index value  
also there is no more mumbai test net ... its amoy 