// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {
    AllowListData,
    PublicDrop,
    TokenGatedDropStage,
    SignedMintValidationParams
} from "../lib/SeaDropStructs.sol";

/// @notice Minimal SeaDrop interface used by SeaDrop-compatible token contracts.
interface ISeaDrop {
    function updateDropURI(string calldata dropURI) external;
    function updatePublicDrop(PublicDrop calldata publicDrop) external;
    function updateAllowList(AllowListData calldata allowListData) external;
    function updateTokenGatedDrop(address allowedNftToken, TokenGatedDropStage calldata dropStage) external;
    function updateCreatorPayoutAddress(address payoutAddress) external;
    function updateAllowedFeeRecipient(address feeRecipient, bool allowed) external;
    function updateSignedMintValidationParams(address signer, SignedMintValidationParams calldata signedMintValidationParams) external;
    function updatePayer(address payer, bool allowed) external;
    function getPublicDrop(address nftContract) external view returns (PublicDrop memory);
    function getCreatorPayoutAddress(address nftContract) external view returns (address);
}
