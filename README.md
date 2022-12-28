# Upgradeable Multi-Token Staking

This project includes three upgradeable contracts (UUPS) whose functionalities are dependent on one another. Included is a script that demonstrates how an upgradeable contract can be leveraged by the owners for malovelent purposes. The script upgrades the implementation of the NFT proxy to point to a malicious backdoor contract which allows the deployer to forecefully move NFT balances as they wish.

## Controller Contract

The Controller is intended to act as a staking vault and record keeper. Only it has authority to call onto the NFT contract to mint new NFT's based on construtor defined tokensPerNFT parameter. As to mint an NFT a user must exchange a specified amount of ERC20 tokens from the Token contract.

In terms of staking users are expected to transfer their NFT's to the controller contract using safeTransferFrom. Which allows the controller to log the time at which they staked. The user accrues staking rewards in ERC20 tokens for each full day they have staked. The amount of ERC20 tokens gained is defined via the constructor defined rewardTokens parameter.

## Token Contract (ERC20)

The Token contract inherits from Openzeppelin's ERC20 capped allowing it to have the extended functionality of a cap on max supply. As a custom implementation tokens can only be minted based on a constructor defined wei per token value.

The Controller contract has priviliges to mint tokens at it's discretion (see controller section).

## NFT Contract (ERC721)

The NFT contract uses Openzeppelin's ERC721 standard. A cap on max supply is set via a constructor defined argument.

Only the controller contract has authorization to mint NFT's based on it's logic (see controller section). All mints begin at tokenID of 1 and are minted in numerical order.

# Deployment Execution Flow

All actions here must be conducted by a singular administrator. See scripts/deployAll.js for the pre-configured set up of the deployment process. Below is the instructions on how to deploy the contracts manually.

1. Deploy the Token and NFT contracts and call the initalize function on them passing in their required parameters (must be done in same transaction)

2. Deploy the controller contract and call initalize passing in it's required parameters which includes the deployed token and NFT contract addresses

3. On the Token and NFT contracts call initializeController passing in the address of the Controller contract

# User Execution Flow

1. buys tokens from the token contract based on predefined tokens per wei value

   - Token buyTokens()

2. gives allowance to the controller contract to move tokens on its behalf

   - Token increaseAllowance(spender, amount)

3. calls mint on controller contract to receive 1 NFT for the predefined number of tokens

   - Controller mintNFT()

4. Using safeTransferFrom the user transfers the NFT to the controller contract, initating the staking process

   - NFT safeTransferFrom()

5. User accumulates staking rewards in tokens for the predefined stakingRewards amount per day

6. They can either claim rewards WITHOUT removing their NFT from the controller

   - claimRewards(amount, false)

   or claim AND remove - claimRewards(amount, true)

Claiming without removing ensures the staked NFT continues to accrue staking rewards

# How To Run

By default this configuration is set up to run on Goerli

Compile contracts:

```
npx hardhat compile
```

deploy 3 implementations (ERC721, ERC20 and Controller) and 3 corresponding proxies

```
env $(cat .env) npx hardhat run --network goerli scripts/deployAll.js
```

verify all 3 proxies on etherscan (must pass in addresses for your deployed instance)

```
env $(cat .env) npx hardhat verify --network goerli {tokenAddress}
env $(cat .env) npx hardhat verify --network goerli {NFT Address}
env $(cat .env) npx hardhat verify --network goerli {Controller Address}
```

deploy demo malicious upgrade

```
env $(cat .env) npx hardhat run --network goerli scripts/addNFTBackdoor.js
```
