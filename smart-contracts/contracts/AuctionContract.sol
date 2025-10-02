// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title AuctionContract
 * @dev Manages blockchain auctions with ERC-721 tokenization for Cancer Warrior Foundation
 */
contract AuctionContract is 
    ERC721, 
    ERC721URIStorage, 
    ERC721Holder,
    AccessControl, 
    ReentrancyGuard, 
    Pausable 
{
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant AUCTIONEER_ROLE = keccak256("AUCTIONEER_ROLE");

    address public treasuryWallet;
    uint256 private _tokenIdCounter;
    uint256 public totalAuctionsCount;

    struct Auction {
        uint256 tokenId;
        address seller;
        uint256 startingBid;
        uint256 currentBid;
        address currentBidder;
        uint256 startTime;
        uint256 endTime;
        bool active;
        bool finalized;
        string itemName;
        string itemDescription;
        string itemImageUrl;
    }

    mapping(uint256 => Auction) public auctions;
    mapping(uint256 => mapping(address => uint256)) public bids;
    mapping(address => uint256[]) public userAuctions;
    mapping(address => uint256[]) public userBids;

    event AuctionCreated(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 startingBid,
        uint256 startTime,
        uint256 endTime,
        string itemName
    );

    event BidPlaced(
        uint256 indexed auctionId,
        address indexed bidder,
        uint256 amount,
        uint256 timestamp
    );

    event AuctionFinalized(
        uint256 indexed auctionId,
        address indexed winner,
        uint256 finalAmount,
        uint256 timestamp
    );

    event AuctionCancelled(
        uint256 indexed auctionId,
        uint256 timestamp
    );

    event FundsTransferred(
        uint256 indexed auctionId,
        address indexed to,
        uint256 amount
    );

    constructor(address _treasuryWallet) 
        ERC721("CareConnect Auction Items", "CCAI") 
    {
        require(_treasuryWallet != address(0), "Invalid treasury wallet");
        
        treasuryWallet = _treasuryWallet;
        
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(AUCTIONEER_ROLE, msg.sender);
    }

    /**
     * @dev Create new auction with ERC-721 token
     */
    function createAuction(
        address _seller,
        uint256 _startingBid,
        uint256 _duration,
        string memory _itemName,
        string memory _itemDescription,
        string memory _itemImageUrl,
        string memory _tokenURI
    ) 
        external 
        onlyRole(AUCTIONEER_ROLE) 
        whenNotPaused 
        returns (uint256) 
    {
        require(_seller != address(0), "Invalid seller address");
        require(_startingBid > 0, "Starting bid must be greater than 0");
        require(_duration > 0, "Duration must be greater than 0");
        require(bytes(_itemName).length > 0, "Item name required");

        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter++;

        // Mint ERC-721 token
        _safeMint(address(this), tokenId);
        _setTokenURI(tokenId, _tokenURI);

        uint256 auctionId = totalAuctionsCount;
        totalAuctionsCount++;

        auctions[auctionId] = Auction({
            tokenId: tokenId,
            seller: _seller,
            startingBid: _startingBid,
            currentBid: 0,
            currentBidder: address(0),
            startTime: block.timestamp,
            endTime: block.timestamp + _duration,
            active: true,
            finalized: false,
            itemName: _itemName,
            itemDescription: _itemDescription,
            itemImageUrl: _itemImageUrl
        });

        userAuctions[_seller].push(auctionId);

        emit AuctionCreated(
            auctionId,
            tokenId,
            _seller,
            _startingBid,
            block.timestamp,
            block.timestamp + _duration,
            _itemName
        );

        return auctionId;
    }

    /**
     * @dev Place bid on auction
     */
    function placeBid(uint256 _auctionId) 
        external 
        payable 
        nonReentrant 
        whenNotPaused 
    {
        Auction storage auction = auctions[_auctionId];
        
        require(auction.active, "Auction not active");
        require(block.timestamp < auction.endTime, "Auction ended");
        require(msg.value > auction.currentBid, "Bid must be higher than current bid");
        require(
            msg.value >= auction.startingBid, 
            "Bid must be at least starting bid"
        );
        require(msg.sender != auction.seller, "Seller cannot bid");

        // Refund previous bidder
        if (auction.currentBidder != address(0)) {
            uint256 refundAmount = auction.currentBid;
            (bool success, ) = auction.currentBidder.call{value: refundAmount}("");
            require(success, "Refund failed");
        }

        // Update auction
        auction.currentBid = msg.value;
        auction.currentBidder = msg.sender;

        // Track bid
        bids[_auctionId][msg.sender] = msg.value;
        userBids[msg.sender].push(_auctionId);

        emit BidPlaced(_auctionId, msg.sender, msg.value, block.timestamp);
    }

    /**
     * @dev Finalize auction and transfer funds to treasury
     */
    function finalizeAuction(uint256 _auctionId) 
        external 
        nonReentrant 
        whenNotPaused 
    {
        Auction storage auction = auctions[_auctionId];
        
        require(auction.active, "Auction not active");
        require(block.timestamp >= auction.endTime, "Auction not ended yet");
        require(!auction.finalized, "Auction already finalized");

        auction.active = false;
        auction.finalized = true;

        if (auction.currentBidder != address(0)) {
            // Transfer NFT to winner
            _transfer(address(this), auction.currentBidder, auction.tokenId);

            // Transfer funds to treasury (100% to foundation)
            uint256 amount = auction.currentBid;
            (bool success, ) = treasuryWallet.call{value: amount}("");
            require(success, "Transfer to treasury failed");

            emit FundsTransferred(_auctionId, treasuryWallet, amount);
            emit AuctionFinalized(
                _auctionId,
                auction.currentBidder,
                auction.currentBid,
                block.timestamp
            );
        } else {
            // No bids - return NFT to seller (burn or transfer)
            _burn(auction.tokenId);
            
            emit AuctionFinalized(_auctionId, address(0), 0, block.timestamp);
        }
    }

    /**
     * @dev Cancel auction (admin only, before any bids)
     */
    function cancelAuction(uint256 _auctionId) 
        external 
        onlyRole(ADMIN_ROLE) 
    {
        Auction storage auction = auctions[_auctionId];
        
        require(auction.active, "Auction not active");
        require(auction.currentBidder == address(0), "Cannot cancel with bids");

        auction.active = false;
        auction.finalized = true;

        // Burn the NFT
        _burn(auction.tokenId);

        emit AuctionCancelled(_auctionId, block.timestamp);
    }

    /**
     * @dev Get auction details
     */
    function getAuction(uint256 _auctionId) 
        external 
        view 
        returns (
            uint256 tokenId,
            address seller,
            uint256 startingBid,
            uint256 currentBid,
            address currentBidder,
            uint256 startTime,
            uint256 endTime,
            bool active,
            bool finalized,
            string memory itemName,
            string memory itemDescription,
            string memory itemImageUrl
        ) 
    {
        Auction memory a = auctions[_auctionId];
        return (
            a.tokenId,
            a.seller,
            a.startingBid,
            a.currentBid,
            a.currentBidder,
            a.startTime,
            a.endTime,
            a.active,
            a.finalized,
            a.itemName,
            a.itemDescription,
            a.itemImageUrl
        );
    }

    /**
     * @dev Get user's auction history
     */
    function getUserAuctions(address _user) 
        external 
        view 
        returns (uint256[] memory) 
    {
        return userAuctions[_user];
    }

    /**
     * @dev Get user's bid history
     */
    function getUserBids(address _user) 
        external 
        view 
        returns (uint256[] memory) 
    {
        return userBids[_user];
    }

    /**
     * @dev Check if auction is active and not expired
     */
    function isAuctionActive(uint256 _auctionId) 
        external 
        view 
        returns (bool) 
    {
        Auction memory auction = auctions[_auctionId];
        return auction.active && block.timestamp < auction.endTime;
    }

    /**
     * @dev Update treasury wallet (admin only)
     */
    function updateTreasuryWallet(address _newTreasury) 
        external 
        onlyRole(ADMIN_ROLE) 
    {
        require(_newTreasury != address(0), "Invalid treasury wallet");
        treasuryWallet = _newTreasury;
    }

    /**
     * @dev Pause contract (admin only)
     */
    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /**
     * @dev Unpause contract (admin only)
     */
    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    // Required overrides
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _burn(uint256 tokenId) 
        internal 
        override(ERC721, ERC721URIStorage) 
    {
        super._burn(tokenId);
    }
}
