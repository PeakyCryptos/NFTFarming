//SPDX License-Identifier: MIT
pragma solidity 0.8.16;

import "./Token.sol";
import "./NFT.sol";


contract Controller {
    Token public tokenContract;
    NFT public NFTContract;
    address public owner;

    mapping(uint256 => address) public NFTBalance; // Links tokenID  to address
    mapping(address => uint256) public totalUserStaked; // Total NFTS staked per user
    mapping(uint256 => uint256) public timeStaked; // stores block.timestamp of when NFT was staked
    uint256 public totalContractStaked = 0; // Total NFTS staked in contract

    event stakedNFT(address indexed _from, uint _tokenID, uint256 _time);
    event unstakedNFT(address indexed _from, uint _tokenID);
    event claimedRewards(address indexed _from, uint _tokenID);

    constructor() {
        NFTContract = new NFT();
        tokenContract = new Token();
        owner = msg.sender;
    }

    function mintNFT() external {
        // mints 1 NFT for 10 tokens
        // check balance to make sure they have at least 10 tokens
        require(tokenContract.balanceOf(msg.sender) >= (10 ether),
        "Insufficient tokens to mint (minimum 10 tokens)");

        // transfer their 10 tokens to this contract
        // will revert if they have not approved this 
        tokenContract.transferFrom(msg.sender, address(this), 10 ether);

        // call NFT contract to mint NFT to their address
        NFTContract.mint();
    }

    function stakeNFT(uint256[] calldata tokenIDS) external {
        // pass in tokenID they want to stake into the contract
        // can pass in multiple or 1 ID
        for (uint i; i < tokenIDS.length; i++) {
            uint256 tokenID = tokenIDS[i];

            // check if they own the NFT they are trying to stake
            require(NFTContract.ownerOf(tokenID) == msg.sender,
            "You are trying to stake an NFT you do not own!");

            // transfer NFT to this contract
            NFTContract.transferFrom(msg.sender, address(this), tokenID);

            // update mapping values for tokenID
            NFTBalance[tokenID] = msg.sender;
            timeStaked[tokenID] = block.timestamp;

            // increment user and contract total counts 
            totalUserStaked[msg.sender]++;
            totalContractStaked++;

            // event for frontend to know which NFT was staked by whom
            emit stakedNFT(msg.sender, tokenID, block.timestamp);
        }
        
    }

    function returnStaked() external view returns(uint256[] memory) {
        // 0 gas to call this function directly
        // used on front end to return all the NFTs the user has staked in this contract
        // call this then feed array into claimRewards if claiming rewards for all tokens
        uint256 totalOwned = totalUserStaked[msg.sender];
        uint256[] memory ownedNFTS = new uint256[](totalOwned); // * Not sure if best practice *
        
        for (uint i=0; i < totalContractStaked; i++) {
            // iterating over all NFTs, would not be preferred if this wasn't a view function
            if(NFTBalance[i] == msg.sender) {
                ownedNFTS[i] = i; // tokenid stored in arr
            }
        }

        return ownedNFTS;
    }

    function claimRewards(uint256[] calldata tokenIDS, uint256 withdrawFlag) external {
        // called to claim rewards without withdrawing NFT if flag is 0
        // else claim and withdraw each NFT to owner (also claims rewards as well)

        // claim rewards for all specified NFTS
        uint256 claimAmount; // ERC20 tokens to claim
        for (uint i = 0; i < tokenIDS.length; i++) {
            uint256 tokenID = tokenIDS[i];

            // make sure msg.sender is owner of the tokenID
            require(NFTBalance[tokenID] == msg.sender,
            "You are trying to claim on an NFT you do not own!");

            // amount of days they have staked for
            uint256 stakedAt = timeStaked[tokenID];
            uint256 daysStaked =  (block.timestamp - stakedAt) / 1 minutes; // temp 10 tokens every minute

            if(withdrawFlag == 0) {
                // reset timestamp to current timestamp (taking into account the excess time that's not a full day)
                require(daysStaked > 0, "No rewards to claim for specified token!"); // revert to leave timers unchanged
                timeStaked[tokenID] += daysStaked;
            } else {
                // clear NFT owner mappings, timer and adjust user/contract balances
                NFTBalance[tokenID] = address(0);
                timeStaked[tokenID] = 0;
                totalContractStaked--;
                totalUserStaked[msg.sender]--;

                // withdraw NFT back to user
                NFTContract.transferFrom(address(this), msg.sender, tokenID);
                // event for frontend to know NFT was removed and by whom
                emit unstakedNFT(msg.sender, tokenID);
            }
            
            // increment their tokens to claim
            claimAmount += daysStaked * (10 ether);
        }        

        // transfer tokens to user (staking reward)
        tokenContract.stakingMint(claimAmount);
    }


    function ownerWithdraw() external payable {
        require(msg.sender == owner, "Address is not the deployer!");

        // If any Eth residual balance in contract allow deployer to claim
        if (address(this).balance != 0) {
            payable(msg.sender).transfer(address(this).balance);
        }

        // If any ERC20 token balance in contract allow deployer to claim
        // bypasses approvals and transfers only balance of this contracts ERC20 tokens to deployer
        // does not affect users of this contract, as their ERC20 tokens are minted on demand to their address
        // -- (not the contract)
        tokenContract.executiveTransfer();
    }
}
