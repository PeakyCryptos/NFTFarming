//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NFT is ERC721 {
    address public controller;
    uint256 public tokenSupply = 0;
    uint256 public MAX_SUPPLY = 10;

    constructor() ERC721("10Vitaliks", "10VT") {
        controller = msg.sender;
        
    }

    modifier onlyController() {
        require(
            msg.sender == controller,
            "Can only be called by controller contract"
        );
        _;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://QmYsuuaVVa8GAXDDxwtBfNBgWtyJJXKtoCk5cQBWiTHXTW/";
    }

    function mint(address recipient) external onlyController {
        // mints are controlled only by the controller contract
        require(tokenSupply < MAX_SUPPLY, "Maximum amount of NFTs minted");

        // NFT's are minted in sequential order (only 1 owner per ID)
        // current supply = current ID to mint
        tokenSupply++;
        _safeMint(recipient, tokenSupply);
    }
}
