// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/Escrow.sol";

contract DeployEscrow is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address sellerAddress = vm.envAddress("SELLER_ADDRESS");
        address platformAddress = vm.envAddress("PLATFORM_ADDRESS");
        uint256 depositAmount = vm.envUint("DEPOSIT_AMOUNT");
        uint256 feePercentage = vm.envUint("FEE_PERCENTAGE");

        vm.startBroadcast(deployerPrivateKey);

        Escrow escrow = new Escrow{value: depositAmount}(sellerAddress, platformAddress, feePercentage);

        vm.stopBroadcast();

        console.log("Escrow deployed at:", address(escrow));
        console.log("Buyer:", escrow.getBuyer());
        console.log("Seller:", escrow.getSeller());
        console.log("Platform:", escrow.platform());
        console.log("Amount:", escrow.getBalance());
        console.log("Fee Percentage:", escrow.feePercentage());
    }
}
