// scripts/addNFTBackDoor.js
const { ethers, upgrades } = require("hardhat");

// Address of deployed NFT proxy
const proxyContract = "0x0fC3d5AD9066F0251a8eCD48A37C51AeaD6e95DE";

/**
 * Change these initilization parameters to your desired values
 */

/* NFT Initalization Parameters */
const _nftCollectionName = "testNFT";
const _nftCollectionSymbol = "tNFT";
const _MAX_SUPPLY = "10";

async function main() {
  /* Upgrade NFT */
  NFTBackDoor = await ethers.getContractFactory("NFTBackDoor");
  await upgrades.upgradeProxy(proxyContract, NFTBackDoor);
  console.log("NFT contract upgrade started");
}

main();
