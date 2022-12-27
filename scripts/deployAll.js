// scripts/deployAll.js
const { ethers, upgrades } = require("hardhat");

/**
 * Change these initilization parameters to your desired values
 */

/* Token Initalization Parameters */
const _tokenName = "testToken";
const _tokenSymbol = "TT";
const _tokenSupplyCap = "100000000";
const _tokensPerWei = "1";

/* NFT Initalization Parameters */
const _nftCollectionName = "testNFT";
const _nftCollectionSymbol = "tNFT";
const _MAX_SUPPLY = "10";

/* Controller Initalization Parameters */
const _tokensPerNFT = "10";
const _rewardTokens = "100";

async function main() {
  /* Deploy Token */
  const Token = await ethers.getContractFactory("Token");
  console.log("\nDeploying Token...");
  const token = await upgrades.deployProxy(
    Token,
    [_tokenName, _tokenSymbol, _tokenSupplyCap, _tokensPerWei],
    {
      kind: "uups",
      initializer: "initialize",
    }
  );
  await token.deployed();
  console.log("Token proxy contract deployed to:", token.address);

  /* Deploy NFT */
  const NFT = await ethers.getContractFactory("NFT");
  console.log("\nDeploying NFT...");
  const nft = await upgrades.deployProxy(
    NFT,
    [_nftCollectionName, _nftCollectionSymbol, _MAX_SUPPLY],
    {
      kind: "uups",
      initializer: "initialize",
    }
  );
  await nft.deployed();
  console.log("NFT proxy contract deployed to:", nft.address);

  /* Deploy Controller */
  const Controller = await ethers.getContractFactory("Controller");
  console.log("\nDeploying Controller...");
  const controller = await upgrades.deployProxy(
    Controller,
    [nft.address, token.address, _tokensPerNFT, _rewardTokens],
    {
      kind: "uups",
      initializer: "initialize",
    }
  );
  await controller.deployed();
  console.log("Controller proxy contract deployed to:", controller.address);

  /* Initalize Controller on Token and NFT */
  await nft.initalizeController(controller.address);
  await token.initalizeController(controller.address);
  console.log("\nController initalized on NFT, and Token contract");
}

main();
