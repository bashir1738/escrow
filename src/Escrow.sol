// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IEscrow.sol";

contract Escrow is IEscrow {
    address public buyer;
    address public seller;
    uint256 public amount;
    bool public approved;
    bool public released;

    event Approved(address indexed buyer);
    event Refunded(address indexed seller);
    event Released(address indexed seller, uint256 amount);
    event Deposited(address indexed buyer, uint256 amount);

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

    constructor(address _seller) payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        buyer = msg.sender;
        seller = _seller;
        amount = msg.value;
        approved = false;
        released = false;
        emit Deposited(buyer, amount);
    }

    function approve() external onlyBuyer notReleased {
        approved = true;
        released = true;
        (bool success,) = payable(seller).call{value: amount}("");
        require(success, "Transfer failed");
        emit Approved(buyer);
        emit Released(seller, amount);
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
}
