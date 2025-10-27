// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title DonationContract
 * @dev Manages transparent donations on Polygon blockchain for Cancer Warrior Foundation
 */
contract DonationContract is AccessControl, ReentrancyGuard, Pausable {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant RECORDER_ROLE = keccak256("RECORDER_ROLE");

    address public treasuryWallet;
    uint256 public totalDonationsCount;
    uint256 public totalDonationsAmount;

    struct Donation {
        address donor;
        uint256 amount;
        uint256 timestamp;
        string donationType; // "crypto" or "fiat"
        string currency; // "MATIC", "USDC", "PHP", etc.
        string externalTxId; // For fiat payments
        string patientId; // Optional: specific patient
        bool isAnonymous;
    }

    mapping(uint256 => Donation) public donations;
    mapping(address => uint256[]) public donorDonations;
    mapping(address => uint256) public donorTotalAmount;

    event DonationRecorded(
        uint256 indexed donationId,
        address indexed donor,
        uint256 amount,
        string donationType,
        string currency,
        uint256 timestamp
    );

    event DonationReceived(
        address indexed donor,
        uint256 amount,
        uint256 timestamp
    );

    event TreasuryWalletUpdated(
        address indexed oldWallet,
        address indexed newWallet
    );

    event FundsWithdrawn(
        address indexed to,
        uint256 amount,
        uint256 timestamp
    );

    constructor(address _treasuryWallet) {
        require(_treasuryWallet != address(0), "Invalid treasury wallet");
        
        treasuryWallet = _treasuryWallet;
        
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(RECORDER_ROLE, msg.sender);
    }

    /**
     * @dev Direct crypto donation (MATIC)
     */
    function donate(bool _isAnonymous, string memory _patientId) 
        external 
        payable 
        nonReentrant 
        whenNotPaused 
    {
        require(msg.value > 0, "Donation amount must be greater than 0");

        uint256 donationId = totalDonationsCount;
        
        donations[donationId] = Donation({
            donor: _isAnonymous ? address(0) : msg.sender,
            amount: msg.value,
            timestamp: block.timestamp,
            donationType: "crypto",
            currency: "MATIC",
            externalTxId: "",
            patientId: _patientId,
            isAnonymous: _isAnonymous
        });

        donorDonations[msg.sender].push(donationId);
        donorTotalAmount[msg.sender] += msg.value;
        
        totalDonationsCount++;
        totalDonationsAmount += msg.value;

        // Transfer to treasury
        (bool success, ) = treasuryWallet.call{value: msg.value}("");
        require(success, "Transfer to treasury failed");

        emit DonationReceived(msg.sender, msg.value, block.timestamp);
        emit DonationRecorded(
            donationId,
            _isAnonymous ? address(0) : msg.sender,
            msg.value,
            "crypto",
            "MATIC",
            block.timestamp
        );
    }

    /**
     * @dev Record fiat donation (PayMaya/GCash) - called by backend
     */
    function recordFiatDonation(
        address _donor,
        uint256 _amount,
        string memory _currency,
        string memory _externalTxId,
        string memory _patientId,
        bool _isAnonymous
    ) 
        external 
        onlyRole(RECORDER_ROLE) 
        whenNotPaused 
    {
        require(_donor != address(0), "Invalid donor address");
        require(_amount > 0, "Amount must be greater than 0");
        require(bytes(_externalTxId).length > 0, "External transaction ID required");

        uint256 donationId = totalDonationsCount;
        
        donations[donationId] = Donation({
            donor: _isAnonymous ? address(0) : _donor,
            amount: _amount,
            timestamp: block.timestamp,
            donationType: "fiat",
            currency: _currency,
            externalTxId: _externalTxId,
            patientId: _patientId,
            isAnonymous: _isAnonymous
        });

        donorDonations[_donor].push(donationId);
        donorTotalAmount[_donor] += _amount;
        
        totalDonationsCount++;
        totalDonationsAmount += _amount;

        emit DonationRecorded(
            donationId,
            _isAnonymous ? address(0) : _donor,
            _amount,
            "fiat",
            _currency,
            block.timestamp
        );
    }

    /**
     * @dev Get donor's donation history
     */
    function getDonorDonations(address _donor) 
        external 
        view 
        returns (uint256[] memory) 
    {
        return donorDonations[_donor];
    }

    /**
     * @dev Get donation details
     */
    function getDonation(uint256 _donationId) 
        external 
        view 
        returns (
            address donor,
            uint256 amount,
            uint256 timestamp,
            string memory donationType,
            string memory currency,
            string memory externalTxId,
            string memory patientId,
            bool isAnonymous
        ) 
    {
        Donation memory d = donations[_donationId];
        return (
            d.donor,
            d.amount,
            d.timestamp,
            d.donationType,
            d.currency,
            d.externalTxId,
            d.patientId,
            d.isAnonymous
        );
    }

    /**
     * @dev Get donor's total donation amount
     */
    function getDonorTotal(address _donor) 
        external 
        view 
        returns (uint256) 
    {
        return donorTotalAmount[_donor];
    }

    /**
     * @dev Update treasury wallet (admin only)
     */
    function updateTreasuryWallet(address _newTreasury) 
        external 
        onlyRole(ADMIN_ROLE) 
    {
        require(_newTreasury != address(0), "Invalid treasury wallet");
        
        address oldWallet = treasuryWallet;
        treasuryWallet = _newTreasury;
        
        emit TreasuryWalletUpdated(oldWallet, _newTreasury);
    }

    /**
     * @dev Emergency withdraw (admin only)
     */
    function emergencyWithdraw() 
        external 
        onlyRole(ADMIN_ROLE) 
        nonReentrant 
    {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");

        (bool success, ) = treasuryWallet.call{value: balance}("");
        require(success, "Withdrawal failed");

        emit FundsWithdrawn(treasuryWallet, balance, block.timestamp);
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

    /**
     * @dev Get contract statistics
     */
    function getStats() 
        external 
        view 
        returns (
            uint256 totalDonations,
            uint256 totalAmount,
            uint256 contractBalance
        ) 
    {
        return (
            totalDonationsCount,
            totalDonationsAmount,
            address(this).balance
        );
    }

    receive() external payable {
        revert("Use donate() function");
    }
}
