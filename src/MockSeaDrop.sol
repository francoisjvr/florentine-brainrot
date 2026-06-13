// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.25;

import {INonFungibleSeaDropToken} from "./seadrop/interfaces/INonFungibleSeaDropToken.sol";
import {
    AllowListData,
    PublicDrop,
    TokenGatedDropStage,
    SignedMintValidationParams
} from "./seadrop/lib/SeaDropStructs.sol";

/// @notice Minimal local SeaDrop double for Hardhat tests and preview generation.
contract MockSeaDrop {
    mapping(address => PublicDrop) public publicDrops;
    mapping(address => address) public creatorPayouts;
    mapping(address => string) public dropURIs;
    mapping(address => mapping(address => bool)) public allowedFeeRecipients;
    mapping(address => mapping(address => bool)) public allowedPayers;

    event PublicDropUpdated(address indexed nftContract, PublicDrop publicDrop);
    event CreatorPayoutAddressUpdated(address indexed nftContract, address payoutAddress);

    function mintPublic(address nftContract, address minter, uint256 quantity) external payable {
        PublicDrop memory publicDrop = publicDrops[nftContract];
        require(block.timestamp >= publicDrop.startTime, "drop not started");
        require(block.timestamp <= publicDrop.endTime, "drop ended");
        require(msg.value == uint256(publicDrop.mintPrice) * quantity, "wrong value");
        INonFungibleSeaDropToken(nftContract).mintSeaDrop(minter, quantity);
    }

    function updatePublicDrop(PublicDrop calldata publicDrop) external {
        publicDrops[msg.sender] = publicDrop;
        emit PublicDropUpdated(msg.sender, publicDrop);
    }

    function updateCreatorPayoutAddress(address payoutAddress) external {
        creatorPayouts[msg.sender] = payoutAddress;
        emit CreatorPayoutAddressUpdated(msg.sender, payoutAddress);
    }

    function updateDropURI(string calldata dropURI) external {
        dropURIs[msg.sender] = dropURI;
    }

    function updateAllowedFeeRecipient(address feeRecipient, bool allowed) external {
        allowedFeeRecipients[msg.sender][feeRecipient] = allowed;
    }

    function updatePayer(address payer, bool allowed) external {
        allowedPayers[msg.sender][payer] = allowed;
    }

    function updateAllowList(AllowListData calldata) external {}
    function updateTokenGatedDrop(address, TokenGatedDropStage calldata) external {}
    function updateSignedMintValidationParams(address, SignedMintValidationParams calldata) external {}

    function getPublicDrop(address nftContract) external view returns (PublicDrop memory) {
        return publicDrops[nftContract];
    }

    function getCreatorPayoutAddress(address nftContract) external view returns (address) {
        return creatorPayouts[nftContract];
    }
}
