//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";

contract Token is ERC20Capped {
    address public immutable controller;

    uint256 tokensPerWei;

    constructor(uint256 _tokensPerWei)
        ERC20("Token", "TK")
        ERC20Capped(1_000_000 ether) // totaly supply capped to 1 mil tokens
    {
        controller = msg.sender;
        tokensPerWei = _tokensPerWei;
    }

    modifier onlyController() {
        require(msg.sender == controller);
        _;
    }

    /*
     *  mint specified amount of tokens per wei
     */
    function buyTokens() external payable {
        _mint(msg.sender, msg.value * tokensPerWei);
    }

    /*
     *  mints specified tokens for each day they had staked to the depositee of NFT
     *  only callable by the controller contract, if it's interal records are valid
     */
    function stakingMint(address tokenOwner, uint256 tokens)
        external
        onlyController
    {
        // mints specified tokens each 24 hours they had staked to depositee of NFT
        _mint(tokenOwner, tokens);
    }

    /*
     *  Transfer all erc20 tokens sold to the controller contract to the address of owner
     */
    function executiveTransfer(address owner) external onlyController {
        _transfer(controller, owner, balanceOf(controller));
    }
}
