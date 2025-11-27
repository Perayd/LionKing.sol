// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @notice ERC-721 collectible "Lion King" with supply cap, public minting, owner minting,
///         ERC-2981 royalties, pausable, and withdraw function.
/// @dev Uses OpenZeppelin contracts (install: @openzeppelin/contracts)
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract LionKing is ERC721Enumerable, ERC2981, Ownable, Pausable {
    using Strings for uint256;

    uint256 public immutable MAX_SUPPLY;
    uint256 public mintPrice;
    uint256 public maxPerTx;
    string private baseTokenURI;
    bool public metadataFrozen;

    event Minted(address indexed to, uint256 indexed tokenId);
    event BaseURISet(string newBaseURI);
    event Withdraw(address indexed to, uint256 amount);

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply,
        uint256 _mintPrice,
        uint256 _maxPerTx,
        string memory _baseTokenURI,
        address royaltyReceiver,
        uint96 royaltyFeeNumerator // out of 10000 (e.g., 500 = 5%)
    ) ERC721(_name, _symbol) {
        MAX_SUPPLY = _maxSupply;
        mintPrice = _mintPrice;
        maxPerTx = _maxPerTx;
        baseTokenURI = _baseTokenURI;
        _setDefaultRoyalty(royaltyReceiver, royaltyFeeNumerator);
    }

    /// @notice Public payable mint
    function publicMint(uint256 quantity) external payable whenNotPaused {
        require(quantity > 0 && quantity <= maxPerTx, "invalid quantity");
        require(totalSupply() + quantity <= MAX_SUPPLY, "sold out");
        require(msg.value == mintPrice * quantity, "incorrect ETH");

        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = totalSupply() + 1; // token IDs start at 1
            _safeMint(msg.sender, tokenId);
            emit Minted(msg.sender, tokenId);
        }
    }

    /// @notice Owner can mint for giveaways, team, etc.
    function ownerMint(address to, uint256 quantity) external onlyOwner {
        require(totalSupply() + quantity <= MAX_SUPPLY, "exceeds supply");
        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = totalSupply() + 1;
            _safeMint(to, tokenId);
            emit Minted(to, tokenId);
        }
    }

    /// @notice Set base URI (only if metadata not frozen)
    function setBaseURI(string calldata _baseURI) external onlyOwner {
        require(!metadataFrozen, "metadata frozen");
        baseTokenURI = _baseURI;
        emit BaseURISet(_baseURI);
    }

    /// @notice Freeze metadata permanently (irreversible)
    function freezeMetadata() external onlyOwner {
        metadataFrozen = true;
    }

    /// @notice Update mint price
    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    /// @notice Update max per tx
    function setMaxPerTx(uint256 _maxPerTx) external onlyOwner {
        maxPerTx = _maxPerTx;
    }

    /// @notice Pause/unpause contract (stops public mint)
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpause contract
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Set default royalty receiver and fee
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /// @notice Delete royalties (if needed)
    function deleteDefaultRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }

    /// @notice Withdraw contract balance to owner
    function withdraw(address payable to) external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "no funds");
        (bool ok, ) = to.call{value: balance}("");
        require(ok, "withdraw failed");
        emit Withdraw(to, balance);
    }

    /// @notice Token URI - concatenates baseTokenURI + tokenId + ".json"
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "nonexistent token");
        if (bytes(baseTokenURI).length == 0) {
            return "";
        }
        return string(abi.encodePacked(baseTokenURI, tokenId.toString(), ".json"));
    }

    // --- Overrides required by Solidity ---
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // Hook to prevent transfers when paused
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721Enumerable)
        whenNotPaused
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // Accept ETH
    receive() external payable {}
    fallback() external payable {}
}
