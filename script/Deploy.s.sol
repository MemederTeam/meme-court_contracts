// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/MemeCourtVoting.sol";

/**
 * @title DeployMemeCourt
 * @dev Deployment script for MemeCore testnet
 */
contract DeployMemeCourt is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);

        // Deploy MemeCourtVoting contract
        MemeCourtVoting voting = new MemeCourtVoting();

        console.log("=== MemeCourt Deployment Complete ===");
        console.log("MemeCourtVoting deployed at:", address(voting));
        console.log("Owner:", voting.owner());
        console.log("Network: MemeCore Testnet (Formicarium)");
        console.log("");
        console.log("Verify contract with:");
        console.log("forge verify-contract", address(voting), "src/MemeCourtVoting.sol:MemeCourtVoting --chain-id 1337");

        vm.stopBroadcast();
    }
}