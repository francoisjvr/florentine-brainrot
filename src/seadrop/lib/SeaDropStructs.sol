// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/// @notice SeaDrop public mint configuration. Copied from ProjectOpenSea/seadrop for interface compatibility.
struct PublicDrop {
    uint80 mintPrice;
    uint48 startTime;
    uint48 endTime;
    uint16 maxTotalMintableByWallet;
    uint16 feeBps;
    bool restrictFeeRecipients;
}

/// @notice SeaDrop token-gated mint configuration. Copied from ProjectOpenSea/seadrop for interface compatibility.
struct TokenGatedDropStage {
    uint80 mintPrice;
    uint16 maxTotalMintableByWallet;
    uint48 startTime;
    uint48 endTime;
    uint8 dropStageIndex;
    uint32 maxTokenSupplyForStage;
    uint16 feeBps;
    bool restrictFeeRecipients;
}

/// @notice SeaDrop allow-list mint parameters. Copied from ProjectOpenSea/seadrop for interface compatibility.
struct MintParams {
    uint256 mintPrice;
    uint256 maxTotalMintableByWallet;
    uint256 startTime;
    uint256 endTime;
    uint256 dropStageIndex;
    uint256 maxTokenSupplyForStage;
    uint256 feeBps;
    bool restrictFeeRecipients;
}

/// @notice SeaDrop token-gated mint parameters. Copied from ProjectOpenSea/seadrop for interface compatibility.
struct TokenGatedMintParams {
    address allowedNftToken;
    uint256[] allowedNftTokenIds;
}

/// @notice SeaDrop allow-list data. Copied from ProjectOpenSea/seadrop for interface compatibility.
struct AllowListData {
    bytes32 merkleRoot;
    string[] publicKeyURIs;
    string allowListURI;
}

/// @notice SeaDrop signed-mint validation parameters. Copied from ProjectOpenSea/seadrop for interface compatibility.
struct SignedMintValidationParams {
    uint80 minMintPrice;
    uint24 maxMaxTotalMintableByWallet;
    uint40 minStartTime;
    uint40 maxEndTime;
    uint40 maxMaxTokenSupplyForStage;
    uint16 minFeeBps;
    uint16 maxFeeBps;
}
