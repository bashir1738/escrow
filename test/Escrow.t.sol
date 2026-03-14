// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Escrow.sol";

contract EscrowTest is Test {
    Escrow public escrow;
    address public buyer;
    address public seller;
    uint256 public constant AMOUNT = 1 ether;

    event Approved(address indexed buyer);
    event Refunded(address indexed seller);
    event Released(address indexed seller, uint256 amount);
    event Deposited(address indexed buyer, uint256 amount);

    function setUp() public {
        buyer = address(1);
        seller = address(2);

        vm.deal(buyer, 10 ether);
        vm.deal(seller, 10 ether);
        vm.prank(buyer);
        escrow = new Escrow{value: AMOUNT}(seller);
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
        address addr3 = address(3);
        vm.deal(addr3, 1 ether);
        vm.prank(addr3);
        vm.expectRevert("Deposit amount must be greater than 0");
        new Escrow{value: 0}(seller);
    }

    // test 3: only buyer can approve
    function test_OnlyBuyerCanApprove() public {
        vm.prank(seller);
        vm.expectRevert("Only buyer can call this");
        escrow.approve();
    }

    // test 4: buyer approves and funds are released
    function test_BuyerApprovesFunds() public {
        uint256 sellerBalanceBefore = seller.balance;

        vm.prank(buyer);
        vm.expectEmit(true, false, false, false);
        emit Approved(buyer);
        escrow.approve();

        assertTrue(escrow.isApproved());
        assertEq(seller.balance, sellerBalanceBefore + AMOUNT);
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

    // test 10: contract balance after release
    function test_BalanceAfterRelease() public {
        assertEq(escrow.getBalance(), AMOUNT);

        vm.prank(buyer);
        escrow.approve();

        assertEq(escrow.getBalance(), 0);
    }
}
