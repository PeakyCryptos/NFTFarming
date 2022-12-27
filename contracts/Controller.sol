//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// ERC20 and ERC721 contracts
import "./Token.sol";
import "./NFT.sol";

// Upgradeable contracts
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Controller is
    Initializable,
    IERC721ReceiverUpgradeable,
    UUPSUpgradeable
{
    struct nftRecord {
        // current owner
        address owner;
        // block.timestamp of when NFT was staked
        uint256 timeStaked;
    }

    // @notice deployer of contract
    address deployer;

    // @notice contracts being interacted with
    Token public tokenContract;
    NFT public NFTContract;

    // @notice current owner of controller contract
    address public owner;

    // @notice amount of tokens required to mint a single NFT
    uint256 public tokensPerNFT;

    // @notice reward tokens per day staked
    uint256 public rewardTokens;

    // @notice Links tokenID  to address and total time staked
    mapping(uint256 => nftRecord) public controllerNFTRecord;

    // @notice Total NFTS staked per user
    mapping(address => uint256) public totalUserStaked;

    // @notice Total NFTS staked in contract
    uint256 public totalContractStaked;

    event stakedNFT(address indexed _from, uint256 _tokenID, uint256 _time);
    event unstakedNFT(address indexed _from, uint256 _tokenID);
    event claimedRewards(address indexed _from, uint256 _claimAmount);

    // @dev  must set implementation and initalize in the same transaction
    function initialize(
        address _NFT,
        address _Token,
        uint256 _tokensPerNFT,
        uint256 _rewardTokens
    ) external initializer {
        deployer = msg.sender;

        // ERC20, and NFT contracts
        NFTContract = NFT(_NFT);
        tokenContract = Token(_Token);

        // init upgradeable interface
        __UUPSUpgradeable_init();

        tokensPerNFT = _tokensPerNFT;

        rewardTokens = _rewardTokens;
    }

    // @dev mints 1 NFT for specified amount of token
    function mintNFT() external {
        uint256 tokensBalance = tokenContract.balanceOf(msg.sender);

        // check balance to make sure they have enough tokens for 1 NFT
        require(tokensBalance >= (tokensPerNFT), "Insufficient tokens to mint");

        // transfer their token to this contract
        // will revert if they have not approved this
        require(
            tokenContract.transferFrom(msg.sender, address(this), tokensPerNFT)
        );

        // call NFT contract to mint NFT to their address
        NFTContract.mint(msg.sender);
    }

    /*
     *  @dev sending to this function stakes NFTs automatically
     *  more gas efficient and considered best practice over a custom implementation
     *  also signifies to sender that this smart contract can handle ERC721's correctly
     */
    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes calldata
    ) external returns (bytes4) {
        // update mapping values for tokenID
        controllerNFTRecord[tokenId].owner = from;
        controllerNFTRecord[tokenId].timeStaked = block.timestamp;

        // increment user and contract total counts
        totalUserStaked[from]++;
        totalContractStaked++;

        // event for frontend to know which NFT was staked by whom
        emit stakedNFT(from, tokenId, block.timestamp);

        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }

    /*
     *  @dev 0 gas to call this function directly
     *  used on front end to return all the NFTs the user has staked in this contract
     *  call this then feed array into claimRewards if claiming rewards for all token
     */
    function returnStaked() external view returns (uint256[] memory) {
        uint256 totalOwned = totalUserStaked[msg.sender];
        uint256[] memory ownedNFTS = new uint256[](totalOwned);

        //uint256 maxSupplyNFT = NFTContract.MAX_SUPPLY;
        (bool success, bytes memory data) = address(NFTContract).staticcall(
            abi.encodeWithSignature("MAX_SUPPLY()")
        );
        require(success);

        uint256 MAX_SUPPLY = uint256(bytes32(data));
        for (uint256 i = 1; i < MAX_SUPPLY; i++) {
            // iterating over all NFTs, would not be preferred if this wasn't a view function
            if (controllerNFTRecord[i].owner == msg.sender) {
                // tokenid stored in arr
                ownedNFTS[ownedNFTS.length - 1] = i;
            }
        }

        return ownedNFTS;
    }

    /*
     *  @dev called to claim rewards without withdrawing NFT if flag is true
     *  else claim and withdraw each NFT to owner (also claims rewards as well)
     */
    function claimRewards(uint256[] calldata tokenIDS, bool withdrawFlag)
        external
    {
        // ERC20 token to claim
        uint256 claimAmount;

        // claim rewards for all specified NFTS
        for (uint256 i = 0; i < tokenIDS.length; i++) {
            uint256 tokenID = tokenIDS[i];

            // make sure msg.sender is owner of the tokenID
            require(
                controllerNFTRecord[tokenID].owner == msg.sender,
                "You are trying to claim on an NFT you do not own!"
            );

            // amount of days they have staked for
            uint256 stakedAt = controllerNFTRecord[tokenID].timeStaked;
            uint256 daysStaked = (block.timestamp - stakedAt) / 1 seconds;

            if (!withdrawFlag) {
                require(
                    daysStaked > 0,
                    "No rewards to claim for specified token!"
                ); // revert to leave timers unchanged

                // reset timestamp to current timestamp (taking into account the excess time that's not a full day)
                controllerNFTRecord[tokenID].timeStaked += daysStaked;
            } else {
                // clear NFT owner mappings, timer and adjust user/contract balances
                controllerNFTRecord[tokenID].owner = address(0);
                controllerNFTRecord[tokenID].timeStaked = 0;
                totalContractStaked--;
                totalUserStaked[msg.sender]--;

                // event for frontend to know NFT was removed and by whom
                emit unstakedNFT(msg.sender, tokenID);

                // withdraw NFT back to user
                NFTContract.safeTransferFrom(
                    address(this),
                    msg.sender,
                    tokenID
                );
            }

            // increment their amount to claim
            claimAmount += daysStaked * rewardTokens;
        }

        // event for frontend to know rewards were claimed
        emit claimedRewards(msg.sender, claimAmount);

        // Get token max supply
        (bool success, bytes memory data) = address(tokenContract).staticcall(
            abi.encodeWithSignature("cap()")
        );
        require(success);

        uint256 maxSupply = uint256(bytes32(data));

        // Get token current supply
        (success, data) = address(tokenContract).staticcall(
            abi.encodeWithSignature("totalSupply()")
        );
        require(success);

        uint256 currentSupply = uint256(bytes32(data));

        /*
         *  @dev only transfer staking rewards if it doesn't exceed max supply
         *  else transfer possible claimable reward
         */
        uint256 maxClaimable = maxSupply - currentSupply;
        if (claimAmount < maxClaimable) {
            tokenContract.stakingMint(msg.sender, claimAmount);
        } else {
            tokenContract.stakingMint(msg.sender, maxClaimable);
        }
    }

    /*
     *  @dev If any ERC20 token balance in contract allow owner to claim
     *  bypasses approvals and transfers only balance of this contract's ERC20 token to owner
     *  does not affect users of this contract, as their ERC20 token are minted on demand to their address
     */
    function ownerWithdraw() external payable {
        require(msg.sender == deployer, "Address is not the deployer!");

        if (address(this).balance != 0) {
            payable(msg.sender).transfer(address(this).balance);
        }

        tokenContract.executiveTransfer();
    }

    // @dev internal check that ensures only initial deployer can upgrade the contract
    function _authorizeUpgrade(
        address /* newImplementation */
    ) internal view override {
        require(msg.sender == deployer);
    }
}
