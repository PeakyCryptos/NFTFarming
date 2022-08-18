require("@nomicfoundation/hardhat-toolbox");
require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-waffle");

/** @type import('hardhat/config').HardhatUserConfig */

const metamask_private_key = "0x" + "eae0d8c4d4925393178e0ffb1eea196501e04583468e7cc3c144b480c9d1582d";

module.exports = {
  solidity: "0.8.16",

  networks: {
    rinkeby: {
      url: "https://rinkeby.infura.io/v3/f0b82a68edab448794f0113419d54b18",
      accounts: [metamask_private_key]  
    }
  },
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey: "ZAEAVSMNS25P1VUFSV285XGRCFSKQ18XI4"
  }
};
