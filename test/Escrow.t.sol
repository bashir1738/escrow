// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Escrow.sol";

contract EscrowTest is Test {
    Escrow public escrow;
    address public buyer;
    address public seller;
    address public platform;
    uint256 public constant AMOUNT = 1 ether;
    uint256 public constant FEE_PERCENTAGE = 5; // 5%

    event Approved(address indexed buyer);
    event Refunded(address indexed seller);
    event Released(address indexed seller, uint256 amount);
    event Deposited(address indexed buyer, uint256 amount);

    function setUp() public {
        buyer = address(1);
        seller = address(2);
        platform = address(3);

        vm.deal(buyer, 10 ether);
        vm.deal(seller, 10 ether);
        vm.prank(buyer);
        escrow = new Escrow{value: AMOUNT}(seller, platform, FEE_PERCENTAGE);
    }

    // test 1: contract creation and initial state
    function test_ContractCreation() public {
        assertEq(escrow.getBuyer(), buyer);
        assertEq(escrow.getSeller(), seller);
        assertEq(escrow.getBalance(), AMOUNT);
        assertFalse(escrow.isApproved());
    }

    // test 2: deposit amount must be greater than 0
    function test_RejectZeroDeposit() public {
        address addr3 = address(4);
        vm.deal(addr3, 1 ether);
        vm.prank(addr3);
        vm.expectRevert("Deposit amount must be greater than 0");
        new Escrow{value: 0}(seller, platform, FEE_PERCENTAGE);
    }

    // test 3: only buyer can approve
    function test_OnlyBuyerCanApprove() public {
        vm.prank(seller);
        vm.expectRevert("Only buyer can call this");
        escrow.approve();
    }

    // test 4: buyer approves and funds are released (minus platform fees)
    function test_BuyerApprovesFunds() public {
        uint256 sellerBalanceBefore = seller.balance;
        uint256 expectedAmount = AMOUNT - (AMOUNT * FEE_PERCENTAGE / 100);

        vm.prank(buyer);
        vm.expectEmit(true, false, false, false);
        emit Approved(buyer);
        escrow.approve();

        assertTrue(escrow.isApproved());
        assertEq(seller.balance, sellerBalanceBefore + expectedAmount);
    }

    // test 5: Only seller can refund
    function test_OnlySellerCanRefund() public {
        vm.prank(buyer);
        vm.expectRevert("Only seller can call this");
        escrow.refund();
    }

    // test 6: seller can refund if not approved
    function test_SellerRefundsFunds() public {
        uint256 buyerBalanceBefore = buyer.balance;

        vm.prank(seller);
        escrow.refund();

        assertEq(buyer.balance, buyerBalanceBefore + AMOUNT);
    }

    // test 7: cannot approve after already approved
    function test_CannotApproveAfterApproved() public {
        vm.prank(buyer);
        escrow.approve();

        vm.prank(buyer);
        vm.expectRevert("Funds already released");
        escrow.approve();
    }

    // test 8: cannot refund after already refunded
    function test_CannotRefundAfterRefunded() public {
        vm.prank(seller);
        escrow.refund();

        vm.prank(seller);
        vm.expectRevert("Funds already released");
        escrow.refund();
    }

    // test 9: cannot refund after approval
    function test_CannotRefundAfterApproval() public {
        vm.prank(buyer);
        escrow.approve();

        vm.prank(seller);
        vm.expectRevert("Cannot refund after approval");
        escrow.refund();
    }

    // test 10: contract balance after release (should hold platform fees)
    function test_BalanceAfterRelease() public {
        uint256 expectedFee = (AMOUNT * FEE_PERCENTAGE) / 100;
        assertEq(escrow.getBalance(), AMOUNT);

        vm.prank(buyer);
        escrow.approve();

        assertEq(escrow.getBalance(), expectedFee);
        assertEq(escrow.getCollectedFees(), expectedFee);
    }

    // test 11: platform can withdraw collected fees
    function test_PlatformWithdrawFees() public {
        vm.prank(buyer);
        escrow.approve();

        uint256 platformBalanceBefore = platform.balance;
        uint256 expectedFee = (AMOUNT * FEE_PERCENTAGE) / 100;

        vm.prank(platform);
        escrow.withdrawFees();

        assertEq(platform.balance, platformBalanceBefore + expectedFee);
        assertEq(escrow.getCollectedFees(), 0);
    }

    // test 12: only platform can withdraw fees
    function test_OnlyPlatformCanWithdraw() public {
        vm.prank(buyer);
        escrow.approve();

        vm.prank(seller);
        vm.expectRevert("Only platform can call this");
        escrow.withdrawFees();
    }

    // test 13: cannot withdraw when no fees collected
    function test_CannotWithdrawNoFees() public {
        vm.prank(platform);
        vm.expectRevert("No fees to withdraw");
        escrow.withdrawFees();
    }

    // test 14: platform can change fee percentage
    function test_PlatformChangeFeePercentage() public {
        uint256 newFeePercentage = 10;

        vm.prank(platform);
        escrow.setFeePercentage(newFeePercentage);

        assertEq(escrow.feePercentage(), newFeePercentage);
    }

    // test 15: only platform can change fee percentage
    function test_OnlyPlatformCanChangeFee() public {
        vm.prank(seller);
        vm.expectRevert("Only platform can call this");
        escrow.setFeePercentage(10);
    }

    // test 16: fee percentage cannot exceed 100%
    function test_FeePercentageCannotExceed100() public {
        vm.prank(platform);
        vm.expectRevert("Fee percentage cannot exceed 100");
        escrow.setFeePercentage(101);
    }

    // test 17: zero fee percentage (no fees charged)
    function test_ZeroFeePercentage() public {
        address buyer2 = address(5);
        address seller2 = address(6);
        vm.deal(buyer2, 10 ether);

        vm.prank(buyer2);
        Escrow escrow2 = new Escrow{value: AMOUNT}(seller2, platform, 0);

        uint256 sellerBalanceBefore = seller2.balance;
        vm.prank(buyer2);
        escrow2.approve();

        assertEq(seller2.balance, sellerBalanceBefore + AMOUNT);
        assertEq(escrow2.getCollectedFees(), 0);
    }

    // test 18: fee calculation with different amounts
    function test_FeeCalculationDifferentAmounts() public {
        address buyer2 = address(7);
        address seller2 = address(8);
        uint256 amount2 = 10 ether;
        vm.deal(buyer2, 20 ether);

        vm.prank(buyer2);
        Escrow escrow2 = new Escrow{value: amount2}(seller2, platform, FEE_PERCENTAGE);

        uint256 expectedFee = (amount2 * FEE_PERCENTAGE) / 100;
        uint256 sellerBalanceBefore = seller2.balance;

        vm.prank(buyer2);
        escrow2.approve();

        assertEq(seller2.balance, sellerBalanceBefore + (amount2 - expectedFee));
        assertEq(escrow2.getCollectedFees(), expectedFee);
    }

    // test 19: verify collected fees after multiple transactions
    function test_MultipleTransactionsCollectFees() public {
        vm.prank(buyer);
        escrow.approve();

        uint256 expectedFee = (AMOUNT * FEE_PERCENTAGE) / 100;
        assertEq(escrow.getCollectedFees(), expectedFee);
    }

    // test 20: buyer cannot call platform functions
    function test_BuyerCannotCallPlatformFunctions() public {
        vm.prank(buyer);
        vm.expectRevert("Only platform can call this");
        escrow.withdrawFees();

        vm.prank(buyer);
        vm.expectRevert("Only platform can call this");
        escrow.setFeePercentage(10);
    }
}
