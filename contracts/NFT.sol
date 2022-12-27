//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20CappedUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

//import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

contract Token is Initializable, ERC20CappedUpgradeable {
    address public controller;
    address immutable deployer = msg.sender;

    uint256 public tokensPerWei;

    // must set implementation and initalize in the transaction
    function initialize(
        string calldata _tokenName,
        string calldata _tokenSymbol,
        uint256 _tokenSupplyCap,
        uint256 _tokensPerWei
    ) external initializer {
        __ERC20_init(_tokenName, _tokenSymbol);
        __ERC20Capped_init(_tokenSupplyCap);

        tokensPerWei = _tokensPerWei;
    }

    // @dev deployer sets the controller
    function initalizeController(address _controller) external {
        require(deployer == msg.sender && controller == address(0));
        controller = _controller;
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
