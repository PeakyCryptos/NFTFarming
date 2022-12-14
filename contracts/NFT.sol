//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Upgradeable contracts
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract NFT is Initializable, ERC721Upgradeable, UUPSUpgradeable {
    // @notice deployer of contract
    address deployer;

    address public controller;
    uint256 public tokenSupply = 1;
    uint256 public MAX_SUPPLY;

    // @dev  must set implementation and initalize in the same transaction
    function initialize(
        string calldata _nftCollectionName,
        string calldata _nftCollectionSymbol,
        uint256 _MAX_SUPPLY
    ) external initializer {
        deployer = msg.sender;

        // nft initilization
        __ERC721_init(_nftCollectionName, _nftCollectionSymbol);

        // init upgradeable interface
        __UUPSUpgradeable_init();

        MAX_SUPPLY = _MAX_SUPPLY;
    }

    // @dev deployer sets the controller
    function initalizeController(address _controller) external {
        require(msg.sender == deployer && controller == address(0));
        controller = _controller;
    }

    modifier onlyController() {
        require(
            msg.sender == controller,
            "Can only be called by controller contract"
        );
        _;
    }

    function _baseURI() internal pure virtual override returns (string memory) {
        return "ipfs://QmYsuuaVVa8GAXDDxwtBfNBgWtyJJXKtoCk5cQBWiTHXTW/";
    }

    /*
     *  @dev mints are controlled only by the controller contract
     *  NFT's are minted in sequential order (only 1 owner per ID)
     *  current supply = current ID to mint + 1
     */
    function mint(address recipient) external onlyController {
        // cache storage variable on stack for gas efficiency
        uint256 _tokenSupply = tokenSupply;
        require(_tokenSupply < MAX_SUPPLY, "Maximum amount of NFTs minted");

        // mint total supply - 1 as we start the totalSupply at 1
        unchecked {
            // unchecked as we already place a cap on the sequential mints
            tokenSupply = _tokenSupply;
        }
        _safeMint(recipient, _tokenSupply - 1);
    }

    // @dev internal check that ensures only initial deployer can upgrade the contract
    function _authorizeUpgrade(
        address /* newImplementation */
    ) internal view virtual override {
        require(msg.sender == deployer);
    }
}
