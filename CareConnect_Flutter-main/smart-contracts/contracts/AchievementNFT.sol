// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title AchievementNFT
 * @dev Non-transferable achievement badges for donor loyalty program
 */
contract AchievementNFT is ERC721, ERC721URIStorage, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    
    uint256 private _tokenIdCounter;

    struct Achievement {
        string achievementType;
        uint256 timestamp;
        string tier;
        uint256 value;
    }

    mapping(uint256 => Achievement) public achievements;
    mapping(address => uint256[]) public userAchievements;

    event AchievementMinted(
        uint256 indexed tokenId,
        address indexed recipient,
        string achievementType,
        string tier,
        uint256 timestamp
    );

    constructor() ERC721("CareConnect Achievements", "CCA") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    /**
     * @dev Mint achievement badge
     */
    function mintAchievement(
        address _recipient,
        string memory _achievementType,
        string memory _tier,
        uint256 _value,
        string memory _tokenURI
    ) 
        external 
        onlyRole(MINTER_ROLE) 
        returns (uint256) 
    {
        require(_recipient != address(0), "Invalid recipient");

        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter++;

        _safeMint(_recipient, tokenId);
        _setTokenURI(tokenId, _tokenURI);

        achievements[tokenId] = Achievement({
            achievementType: _achievementType,
            timestamp: block.timestamp,
            tier: _tier,
            value: _value
        });

        userAchievements[_recipient].push(tokenId);

        emit AchievementMinted(
            tokenId,
            _recipient,
            _achievementType,
            _tier,
            block.timestamp
        );

        return tokenId;
    }

    /**
     * @dev Get user's achievements
     */
    function getUserAchievements(address _user) 
        external 
        view 
        returns (uint256[] memory) 
    {
        return userAchievements[_user];
    }

    /**
     * @dev Get achievement details
     */
    function getAchievement(uint256 _tokenId) 
        external 
        view 
        returns (
            string memory achievementType,
            uint256 timestamp,
            string memory tier,
            uint256 value
        ) 
    {
        Achievement memory a = achievements[_tokenId];
        return (a.achievementType, a.timestamp, a.tier, a.value);
    }

    /**
     * @dev Override transfer to make badges non-transferable (soulbound)
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal virtual override {
        require(
            from == address(0) || to == address(0),
            "Achievement badges are non-transferable"
        );
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
