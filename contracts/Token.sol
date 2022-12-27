//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Upgradeable contracts
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20CappedUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Token is Initializable, ERC20CappedUpgradeable, UUPSUpgradeable {
    // @notice deployer of contract
    address deployer;

    address public controller;
    uint256 public tokensPerWei;

    // @dev  must set implementation and initalize in the same transaction
    function initialize(
        string calldata _tokenName,
        string calldata _tokenSymbol,
        uint256 _tokenSupplyCap,
        uint256 _tokensPerWei
    ) external initializer {
        deployer = msg.sender;

        // ERC20 initilization
        __ERC20_init(_tokenName, _tokenSymbol);
        __ERC20Capped_init(_tokenSupplyCap);

        // init upgradeable interface
        __UUPSUpgradeable_init();

        tokensPerWei = _tokensPerWei;
    }

    // @dev deployer sets the controller
    function initalizeController(address _controller) external {
        require(msg.sender == deployer && controller == address(0));
        controller = _controller;
    }

    modifier onlyController() {
        require(msg.sender == controller);
        _;
    }

    /*
     *  @dev mint specified amount of tokens per wei
     */
    function buyTokens() external payable {
        _mint(msg.sender, msg.value * tokensPerWei);
    }

    /*
     *  @dev mints specified tokens for each day they had staked to the depositee of NFT
     *  only callable by the controller contract, if it's interal records are valid
     */
    function stakingMint(address tokenOwner, uint256 tokens)
        external
        onlyController
    {
        // mints specified tokens each 24 hours they had staked to depositee of NFT
        _mint(tokenOwner, tokens);
    }

    // @dev Transfer all erc20 tokens sold to the controller contract to the address of owner
    function executiveTransfer() external onlyController {
        _transfer(controller, deployer, balanceOf(controller));
    }

    // @dev internal check that ensures only initial deployer can upgrade the contract
    function _authorizeUpgrade(
        address /* newImplementation */
    ) internal view override {
        require(msg.sender == deployer);
    }
}
