// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";

/// @notice Minimal vendored OpenSea SeaDrop token metadata interface.
interface ISeaDropTokenContractMetadata is IERC2981 {
    error CannotExceedMaxSupplyOfUint64(uint256 newMaxSupply);
    error NewMaxSupplyCannotBeLessThenTotalMinted(uint256 got, uint256 totalMinted);
    error ProvenanceHashCannotBeSetAfterMintStarted();
    error InvalidRoyaltyBasisPoints(uint256 basisPoints);
    error RoyaltyAddressCannotBeZeroAddress();

    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
    event ContractURIUpdated(string newContractURI);
    event MaxSupplyUpdated(uint256 newMaxSupply);
    event ProvenanceHashUpdated(bytes32 previousHash, bytes32 newHash);
    event RoyaltyInfoUpdated(address receiver, uint256 bps);

    // Renamed from SeaDrop's `RoyaltyInfo` to avoid colliding with OpenZeppelin
    // ERC2981's internal struct name when a token inherits both surfaces. The
    // ABI selector is unchanged because external tuple field type/name labels do
    // not affect the function signature.
    struct SeaDropRoyaltyInfo {
        address royaltyAddress;
        uint96 royaltyBps;
    }

    function setBaseURI(string calldata tokenURI) external;
    function setContractURI(string calldata newContractURI) external;
    function setMaxSupply(uint256 newMaxSupply) external;
    function setProvenanceHash(bytes32 newProvenanceHash) external;
    function setRoyaltyInfo(SeaDropRoyaltyInfo calldata newInfo) external;

    function baseURI() external view returns (string memory);
    function contractURI() external view returns (string memory);
    function maxSupply() external view returns (uint256);
    function provenanceHash() external view returns (bytes32);
    function royaltyAddress() external view returns (address);
    function royaltyBasisPoints() external view returns (uint256);
}
