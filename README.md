```shell
npx hardhat compile


# deploy 3 implementation (ERC721, ERC20 and Controller) and 3 matching proxies
env $(cat .env) npx hardhat run --network goerli scripts/deployAll.js

# deploy demo upgrade
env $(cat .env) npx hardhat run --network goerli scripts/upgrade_box_v2.js

# verify all 3 proxies
env $(cat .env) npx hardhat verify --network goerli {tokenAddress}
env $(cat .env) npx hardhat verify --network goerli {NFT Address}
env $(cat .env) npx hardhat verify --network goerli {Controller Address}
```
