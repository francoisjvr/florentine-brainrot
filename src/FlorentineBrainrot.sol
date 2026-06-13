// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.25;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import {INonFungibleSeaDropToken} from "./seadrop/interfaces/INonFungibleSeaDropToken.sol";
import {ISeaDropTokenContractMetadata} from "./seadrop/interfaces/ISeaDropTokenContractMetadata.sol";
import {ISeaDrop} from "./seadrop/interfaces/ISeaDrop.sol";
import {
    AllowListData,
    PublicDrop,
    TokenGatedDropStage,
    SignedMintValidationParams
} from "./seadrop/lib/SeaDropStructs.sol";

/// @title Florentine Brainrot
/// @notice OpenSea SeaDrop-compatible ERC721 for the Florentine Brainrot collection.
/// @dev Primary minting should happen through an allowed SeaDrop contract. Includes the project-required agent burn path.
contract FlorentineBrainrot is ERC721, ERC2981, Ownable, ReentrancyGuard, INonFungibleSeaDropToken {
    using Strings for uint256;

    uint256 public constant DEFAULT_MAX_SUPPLY = 1_401;
    uint256 public constant MAX_DEV_MINT = 100;
    address public constant SEA_DROP_MAINNET = 0x00005EA00Ac477B1030CE78506496e8C2dE24bf5;

    uint256 public totalMinted;
    uint256 public totalBurned;
    uint256 public agentBurnedCount;
    address public payoutWallet;

    mapping(address => bool) public allowedSeaDrop;
    address[] private _enumeratedAllowedSeaDrop;
    mapping(address => uint256) private _seaDropMintedByWallet;
    mapping(address => bool) public isAdmin;

    uint256 private _maxSupply = DEFAULT_MAX_SUPPLY;
    string private _baseTokenURI;
    string private _uriSuffix = ".json";
    string private _contractURI;
    bytes32 private _provenanceHash;
    address private _royaltyAddress;
    uint96 private _royaltyBps;

    error InvalidAmount();
    error SoldOut();
    error EthNotAccepted();
    error ZeroAddress();
    error NotSeaDropCompatibleMintPath();
    error NotOwnerOrAdmin();
    error NotTokenOwnerOrApproved();

    event PayoutWalletSet(address payoutWallet);
    event AdminSet(address indexed account, bool enabled);
    event TokenBurned(address indexed burner, uint256 indexed tokenId);
    event CollectionBurned(address indexed collection, uint256 indexed tokenId);
    event URISuffixUpdated(string uriSuffix);

    constructor(address owner_, address payoutWallet_, uint96 royaltyBps_, address[] memory allowedSeaDrop_)
        ERC721("Florentine Brainrot", "FBRAIN")
        Ownable(owner_)
    {
        if (owner_ == address(0) || payoutWallet_ == address(0)) revert ZeroAddress();
        payoutWallet = payoutWallet_;
        _setRoyalty(payoutWallet_, royaltyBps_);
        _setAllowedSeaDrop(allowedSeaDrop_);
    }

    modifier onlyOwnerOrAdmin() {
        if (owner() != msg.sender && !isAdmin[msg.sender]) revert NotOwnerOrAdmin();
        _;
    }

    receive() external payable {
        revert EthNotAccepted();
    }

    fallback() external payable {
        if (msg.value > 0) revert EthNotAccepted();
    }

    /// @notice Disabled intentionally: OpenSea/SeaDrop should control the public free mint limits.
    function mint(uint256) external pure {
        revert NotSeaDropCompatibleMintPath();
    }

    function mintSeaDrop(address minter, uint256 quantity) external nonReentrant override {
        if (!allowedSeaDrop[msg.sender]) revert OnlyAllowedSeaDrop();
        if (minter == address(0)) revert ZeroAddress();
        if (quantity == 0) revert InvalidAmount();
        if (totalMinted + quantity > _maxSupply) revert SoldOut();

        _seaDropMintedByWallet[minter] += quantity;
        uint256 nextTokenId = totalMinted + 1;
        totalMinted += quantity;

        for (uint256 i = 0; i < quantity; ) {
            _safeMint(minter, nextTokenId + i);
            unchecked {
                ++i;
            }
        }
    }

    function devMint(address to, uint256 amount) external onlyOwner {
        if (to == address(0)) revert ZeroAddress();
        if (amount == 0 || amount > MAX_DEV_MINT) revert InvalidAmount();
        if (totalMinted + amount > _maxSupply) revert SoldOut();

        uint256 nextTokenId = totalMinted + 1;
        totalMinted += amount;
        for (uint256 i = 0; i < amount; ) {
            _safeMint(to, nextTokenId + i);
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Token owner or approved operator can burn a token. Does not reopen mint supply.
    function burn(uint256 tokenId) external {
        address tokenOwner = _requireOwned(tokenId);
        if (!_isAuthorized(tokenOwner, msg.sender, tokenId)) revert NotTokenOwnerOrApproved();
        _burn(tokenId);
        totalBurned++;
        emit TokenBurned(msg.sender, tokenId);
    }

    /// @notice Admin burn path for collection management / agent operations. Does not reopen mint supply.
    function agentBurnFromCollection(uint256 tokenId) external onlyOwnerOrAdmin {
        _requireOwned(tokenId);
        _burn(tokenId);
        totalBurned++;
        agentBurnedCount++;
        emit CollectionBurned(address(this), tokenId);
    }

    function getAgentBurnedCount() external view returns (uint256) {
        return agentBurnedCount;
    }

    function setAdmin(address account, bool enabled) external onlyOwner {
        if (account == address(0)) revert ZeroAddress();
        isAdmin[account] = enabled;
        emit AdminSet(account, enabled);
    }

    function totalSupply() public view returns (uint256) {
        return totalMinted - totalBurned;
    }

    function getMintStats(address minter)
        external
        view
        override
        returns (uint256 minterNumMinted, uint256 currentTotalSupply, uint256 supplyCap)
    {
        return (_seaDropMintedByWallet[minter], totalMinted, _maxSupply);
    }

    function updateAllowedSeaDrop(address[] calldata seaDropImpls) external override onlyOwner {
        _setAllowedSeaDrop(seaDropImpls);
    }

    function updatePublicDrop(address seaDropImpl, PublicDrop calldata publicDrop) external override onlyOwner {
        _onlyAllowedSeaDrop(seaDropImpl);
        ISeaDrop(seaDropImpl).updatePublicDrop(publicDrop);
    }

    function updateAllowList(address seaDropImpl, AllowListData calldata allowListData) external override onlyOwner {
        _onlyAllowedSeaDrop(seaDropImpl);
        ISeaDrop(seaDropImpl).updateAllowList(allowListData);
    }

    function updateTokenGatedDrop(address seaDropImpl, address allowedNftToken, TokenGatedDropStage calldata dropStage)
        external
        override
        onlyOwner
    {
        _onlyAllowedSeaDrop(seaDropImpl);
        ISeaDrop(seaDropImpl).updateTokenGatedDrop(allowedNftToken, dropStage);
    }

    function updateDropURI(address seaDropImpl, string calldata dropURI) external override onlyOwner {
        _onlyAllowedSeaDrop(seaDropImpl);
        ISeaDrop(seaDropImpl).updateDropURI(dropURI);
    }

    function updateCreatorPayoutAddress(address seaDropImpl, address payoutAddress) external override onlyOwner {
        if (payoutAddress == address(0)) revert ZeroAddress();
        _onlyAllowedSeaDrop(seaDropImpl);
        payoutWallet = payoutAddress;
        emit PayoutWalletSet(payoutAddress);
        ISeaDrop(seaDropImpl).updateCreatorPayoutAddress(payoutAddress);
    }

    function updateAllowedFeeRecipient(address seaDropImpl, address feeRecipient, bool allowed) external override onlyOwner {
        _onlyAllowedSeaDrop(seaDropImpl);
        ISeaDrop(seaDropImpl).updateAllowedFeeRecipient(feeRecipient, allowed);
    }

    function updateSignedMintValidationParams(
        address seaDropImpl,
        address signer,
        SignedMintValidationParams memory signedMintValidationParams
    ) external override onlyOwner {
        _onlyAllowedSeaDrop(seaDropImpl);
        ISeaDrop(seaDropImpl).updateSignedMintValidationParams(signer, signedMintValidationParams);
    }

    function updatePayer(address seaDropImpl, address payer, bool allowed) external override onlyOwner {
        _onlyAllowedSeaDrop(seaDropImpl);
        ISeaDrop(seaDropImpl).updatePayer(payer, allowed);
    }

    function setBaseURI(string calldata tokenURI_) external override onlyOwner {
        _baseTokenURI = tokenURI_;
        emit BatchMetadataUpdate(1, _maxSupply);
    }

    function setURISuffix(string calldata newSuffix) external onlyOwner {
        _uriSuffix = newSuffix;
        emit URISuffixUpdated(newSuffix);
        emit BatchMetadataUpdate(1, _maxSupply);
    }

    function setContractURI(string calldata newContractURI) external override onlyOwner {
        _contractURI = newContractURI;
        emit ContractURIUpdated(newContractURI);
    }

    function setMaxSupply(uint256 newMaxSupply) external override onlyOwner {
        if (newMaxSupply > type(uint64).max) revert CannotExceedMaxSupplyOfUint64(newMaxSupply);
        if (newMaxSupply < totalMinted) revert NewMaxSupplyCannotBeLessThenTotalMinted(newMaxSupply, totalMinted);
        _maxSupply = newMaxSupply;
        emit MaxSupplyUpdated(newMaxSupply);
    }

    function setProvenanceHash(bytes32 newProvenanceHash) external override onlyOwner {
        if (totalMinted != 0) revert ProvenanceHashCannotBeSetAfterMintStarted();
        bytes32 previousHash = _provenanceHash;
        _provenanceHash = newProvenanceHash;
        emit ProvenanceHashUpdated(previousHash, newProvenanceHash);
    }

    function setRoyaltyInfo(ISeaDropTokenContractMetadata.SeaDropRoyaltyInfo calldata newInfo) external override onlyOwner {
        _setRoyalty(newInfo.royaltyAddress, newInfo.royaltyBps);
    }

    function setRoyaltyInfo(address receiver, uint96 feeNumerator) external onlyOwner {
        _setRoyalty(receiver, feeNumerator);
    }

    function baseURI() external view override returns (string memory) {
        return _baseTokenURI;
    }

    function uriSuffix() external view returns (string memory) {
        return _uriSuffix;
    }

    function contractURI() external view override returns (string memory) {
        return _contractURI;
    }

    function maxSupply() external view override returns (uint256) {
        return _maxSupply;
    }

    function provenanceHash() external view override returns (bytes32) {
        return _provenanceHash;
    }

    function royaltyAddress() external view override returns (address) {
        return _royaltyAddress;
    }

    function royaltyBasisPoints() external view override returns (uint256) {
        return _royaltyBps;
    }

    function getAllowedSeaDrop() external view returns (address[] memory) {
        return _enumeratedAllowedSeaDrop;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        return string.concat(_baseTokenURI, tokenId.toString(), _uriSuffix);
    }

    function _setAllowedSeaDrop(address[] memory seaDropImpls) internal {
        for (uint256 i = 0; i < _enumeratedAllowedSeaDrop.length; ) {
            allowedSeaDrop[_enumeratedAllowedSeaDrop[i]] = false;
            unchecked {
                ++i;
            }
        }
        for (uint256 i = 0; i < seaDropImpls.length; ) {
            if (seaDropImpls[i] == address(0)) revert ZeroAddress();
            allowedSeaDrop[seaDropImpls[i]] = true;
            unchecked {
                ++i;
            }
        }
        _enumeratedAllowedSeaDrop = seaDropImpls;
        emit AllowedSeaDropUpdated(seaDropImpls);
    }

    function _onlyAllowedSeaDrop(address seaDropImpl) internal view {
        if (!allowedSeaDrop[seaDropImpl]) revert OnlyAllowedSeaDrop();
    }

    function _setRoyalty(address receiver, uint96 feeNumerator) internal {
        if (receiver == address(0)) revert RoyaltyAddressCannotBeZeroAddress();
        if (feeNumerator > 10_000) revert InvalidRoyaltyBasisPoints(feeNumerator);
        _royaltyAddress = receiver;
        _royaltyBps = feeNumerator;
        _setDefaultRoyalty(receiver, feeNumerator);
        emit RoyaltyInfoUpdated(receiver, feeNumerator);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC2981, IERC165) returns (bool) {
        return interfaceId == type(INonFungibleSeaDropToken).interfaceId
            || interfaceId == type(ISeaDropTokenContractMetadata).interfaceId
            || interfaceId == 0xaf2f5366 // Full SeaDrop token interface id, including inherited metadata + ERC165 selectors.
            || interfaceId == 0xb7bfade8 // SeaDrop metadata interface id, including inherited ERC2981 + ERC165 selectors.
            || super.supportsInterface(interfaceId);
    }
}
