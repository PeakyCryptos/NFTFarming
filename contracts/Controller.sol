//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Token.sol";
import "./NFT.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract Controller is IERC721Receiver {
    // contracts being interacted with
    Token public tokenContract;
    NFT public NFTContract;

    // current owner of controller contract
    address public owner;

    // NFT contract max supply
    uint256 maxSupplyNFT;

    // amount of tokens required to mint a single NFT
    uint256 public tokensPerNFT;

    // reward tokens per day staked
    uint256 public rewardTokens;

    struct nftRecord {
        // current owner
        address owner;
        // block.timestamp of when NFT was staked
        uint256 timeStaked;
    }

    // Links tokenID  to address and total time staked
    mapping(uint256 => nftRecord) public controllerNFTRecord;

    // Total NFTS staked per user
    mapping(address => uint256) public totalUserStaked;

    // Total NFTS staked in contract
    uint256 public totalContractStaked = 0;

    event stakedNFT(address indexed _from, uint256 _tokenID, uint256 _time);
    event unstakedNFT(address indexed _from, uint256 _tokenID);
    event claimedRewards(address indexed _from, uint256 _claimAmount);

    constructor(
        uint256 _tokensPerWei,
        uint256 _maxSupplyNFT,
        uint256 _tokensPerNFT,
        uint256 _rewardTokens
    ) {
        NFTContract = new NFT();
        tokenContract = new Token(_tokensPerWei);

        owner = msg.sender;

        maxSupplyNFT = _maxSupplyNFT;

        tokensPerNFT = _tokensPerNFT;

        rewardTokens = _rewardTokens;
    }

    /*
     *  mints 1 NFT for specified amount of token
     */
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
     *  sending to this function stakes NFTs automatically
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

        return IERC721Receiver.onERC721Received.selector;
    }

    /*
     *  0 gas to call this function directly
     *  used on front end to return all the NFTs the user has staked in this contract
     *  call this then feed array into claimRewards if claiming rewards for all token
     */
    function returnStaked() external view returns (uint256[] memory) {
        uint256 totalOwned = totalUserStaked[msg.sender];
        uint256[] memory ownedNFTS = new uint256[](totalOwned);

        for (uint256 i = 1; i < maxSupplyNFT; i++) {
            // iterating over all NFTs, would not be preferred if this wasn't a view function
            if (controllerNFTRecord[i].owner == msg.sender) {
                // tokenid stored in arr
                ownedNFTS[ownedNFTS.length - 1] = i;
            }
        }

        return ownedNFTS;
    }

    /*
     *  called to claim rewards without withdrawing NFT if flag is true
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
            uint256 daysStaked = (block.timestamp - stakedAt) / 1 days;

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

            // increment their token to claim
            claimAmount += daysStaked * rewardTokens;
        }

        // event for frontend to know rewards were claimed
        emit claimedRewards(msg.sender, claimAmount);

        // transfer token to user (staking reward)
        tokenContract.stakingMint(msg.sender, claimAmount);
    }

    /*
     *  If any ERC20 token balance in contract allow deployer to claim
     *  bypasses approvals and transfers only balance of this contract's ERC20 token to deployer
     *  does not affect users of this contract, as their ERC20 token are minted on demand to their address
     */
    function ownerWithdraw() external payable {
        require(msg.sender == owner, "Address is not the owner!");

        if (address(this).balance != 0) {
            payable(msg.sender).transfer(address(this).balance);
        }

        tokenContract.executiveTransfer(msg.sender);
    }
}
