// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IEscrow {
    function approve() external;
    function refund() external;
    function getBalance() external view returns (uint256);
    function getBuyer() external view returns (address);
    function getSeller() external view returns (address);
    function isApproved() external view returns (bool);
    function withdrawFees() external;
    function setFeePercentage(uint256 _feePercentage) external;
    function getCollectedFees() external view returns (uint256);
}
