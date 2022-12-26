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

    function buyTokens() external payable {
        // mint specified amount of tokens per wei
        _mint(msg.sender, msg.value * tokensPerWei);
    }

    function stakingMint(address tokenOwner, uint256 tokens)
        external
        onlyController
    {
        // mints specified tokens each 24 hours they had staked to depositee of NFT
        _mint(tokenOwner, tokens);
    }

    function executiveTransfer(address owner) external onlyController {
        // Transfer entire balance of erc20 tokens in controller contract
        // to the address of owner
        _transfer(controller, owner, balanceOf(controller));
    }
}
