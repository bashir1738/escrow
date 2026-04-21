
pragma solidity ^0.8.0;

import "./IEscrow.sol";

contract Escrow is IEscrow {
    address public buyer;
    address public seller;
    address public platform;
    uint256 public amount;
    uint256 public feePercentage; // e.g., 5 = 5%
    uint256 public collectedFees;
    bool public approved;
    bool public released;

    event Approved(address indexed buyer);
    event Refunded(address indexed seller);
    event Released(address indexed seller, uint256 amount);
    event Deposited(address indexed buyer, uint256 amount);
    event FeeWithdrawn(address indexed platform, uint256 amount);
    event FeePercentageUpdated(uint256 newFeePercentage);

    modifier onlyBuyer() {
        require(msg.sender == buyer, "Only buyer can call this");
        _;
    }

    modifier onlySeller() {
        require(msg.sender == seller, "Only seller can call this");
        _;
    }

    modifier notReleased() {
        require(!released, "Funds already released");
        _;
    }

    modifier onlyPlatform() {
        require(msg.sender == platform, "Only platform can call this");
        _;
    }

    constructor(address _seller, address _platform, uint256 _feePercentage) payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        require(_feePercentage <= 100, "Fee percentage cannot exceed 100");
        buyer = msg.sender;
        seller = _seller;
        platform = _platform;
        amount = msg.value;
        feePercentage = _feePercentage;
        approved = false;
        released = false;
        emit Deposited(buyer, amount);
    }

    function approve() external onlyBuyer notReleased {
        approved = true;
        released = true;
        uint256 fee = (amount * feePercentage) / 100;
        uint256 sellerAmount = amount - fee;
        collectedFees += fee;
        (bool success,) = payable(seller).call{value: sellerAmount}("");
        require(success, "Transfer failed");
        emit Approved(buyer);
        emit Released(seller, sellerAmount);
    }

    function refund() external onlySeller {
        require(!approved, "Cannot refund after approval");
        require(!released, "Funds already released");
        released = true;
        (bool success,) = payable(buyer).call{value: amount}("");
        require(success, "Refund failed");
        emit Refunded(seller);
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getBuyer() external view returns (address) {
        return buyer;
    }

    function getSeller() external view returns (address) {
        return seller;
    }

    function isApproved() external view returns (bool) {
        return approved;
    }

    function withdrawFees() external onlyPlatform {
        require(collectedFees > 0, "No fees to withdraw");
        uint256 feesToWithdraw = collectedFees;
        collectedFees = 0;
        (bool success,) = payable(platform).call{value: feesToWithdraw}("");
        require(success, "Fee withdrawal failed");
        emit FeeWithdrawn(platform, feesToWithdraw);
    }

    function setFeePercentage(uint256 _feePercentage) external onlyPlatform {
        require(_feePercentage <= 100, "Fee percentage cannot exceed 100");
        feePercentage = _feePercentage;
        emit FeePercentageUpdated(_feePercentage);
    }

    function getCollectedFees() external view returns (uint256) {
        return collectedFees;
    }
}
