//SPDX License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";

contract Token is ERC20Capped {
    address public immutable controller;

    constructor() 
    ERC20("Token", "TK") 
    ERC20Capped(1_000_000 ether) // All mints capped to 1 mil tokens
    {
       controller = msg.sender; 
    }

    modifier onlyController {
        require(msg.sender == controller);
        _;
    } 

    function buyTokens() external payable  {
        // Users can buy tokens freely up until the cap amount
        require(msg.value >= 1 ether,
        "minimum amount to mint is 1000 tokens which is 1 ether");

        // 1000 tokens per 1 eth, refund excess to user
        uint256 excess = msg.value % 10**18; // fractional porition
        uint256 amount = (msg.value / 10**18) * 10**18; // get integer value (intentionally throwing after decimal)
        _mint(msg.sender, amount * 1_000);

        if (excess != 0) {
            payable(msg.sender).transfer(excess);
        }
    }

    function stakingMint(uint256 tokens) external onlyController {
        // mints 10 per each 24 hours they had staked to depositee of NFT
        _mint(tx.origin, tokens);
    }

    function executiveTransfer() external onlyController {
        // Transfer without approval entire balance of erc20 tokens in controller contract
        // to the address of entity that deployed it
        _transfer(controller, tx.origin, balanceOf(controller));
    }
}