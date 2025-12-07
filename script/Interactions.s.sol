// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/MemeCourtVoting.sol";
import "../src/interfaces/IMemeCourtVoting.sol";

/**
 * @title MemeCourtInteractions
 * @dev Script for interacting with deployed MemeCourtVoting contract
 */
contract MemeCourtInteractions is Script {
    MemeCourtVoting public voting;

    function setUp() public {
        address votingAddress = vm.envAddress("VOTING_CONTRACT_ADDRESS");
        voting = MemeCourtVoting(votingAddress);
    }

    function run() external {
        uint256 userPrivateKey = vm.envUint("USER_PRIVATE_KEY");
        
        vm.startBroadcast(userPrivateKey);

        // Example interactions
        demoVotingFlow();

        vm.stopBroadcast();
    }

    function demoVotingFlow() internal {
        string memory postId = "demo-post-123";
        string memory contentHash = "QmDemoContentHash";
        
        console.log("=== MemeCourt Demo Voting Flow ===");
        
        // Register a post
        console.log("1. Registering post:", postId);
        voting.registerPost(postId, contentHash);
        
        // Cast a vote
        console.log("2. Casting vote (funny: true)");
        voting.castVote(postId, true);
        
        // Check vote status
        (bool isFunny, uint256 timestamp, bool hasVoted) = voting.getVote(msg.sender, postId);
        console.log("Vote status - HasVoted:", hasVoted, "IsFunny:", isFunny, "Timestamp:", timestamp);
        
        // Get post statistics
        IMemeCourtVoting.PostStats memory stats = voting.getPostStats(postId);
        console.log("Post stats - Funny:", stats.funnyVotes, "NotFunny:", stats.notFunnyVotes, "Total:", stats.totalVotes);
        
        console.log("=== Demo Complete ===");
    }

    // Utility functions for specific operations
    function registerPost(string memory postId, string memory contentHash) external {
        uint256 userPrivateKey = vm.envUint("USER_PRIVATE_KEY");
        
        vm.startBroadcast(userPrivateKey);
        voting.registerPost(postId, contentHash);
        vm.stopBroadcast();
        
        console.log("Post registered:", postId);
    }

    function castVote(string memory postId, bool isFunny) external {
        uint256 userPrivateKey = vm.envUint("USER_PRIVATE_KEY");
        
        vm.startBroadcast(userPrivateKey);
        voting.castVote(postId, isFunny);
        vm.stopBroadcast();
        
        console.log("Vote cast for post:", postId, "IsFunny:", isFunny);
    }

    function getPostStats(string memory postId) external view {
        IMemeCourtVoting.PostStats memory stats = voting.getPostStats(postId);
        console.log("=== Post Statistics ===");
        console.log("Post ID:", postId);
        console.log("Funny votes:", stats.funnyVotes);
        console.log("Not funny votes:", stats.notFunnyVotes);
        console.log("Total votes:", stats.totalVotes);
        console.log("Post exists:", stats.exists);
    }

    function getUserVotes(address user) external view {
        string[] memory votedPosts = voting.getUserVotedPosts(user);
        uint256 voteCount = voting.getUserVoteCount(user);
        
        console.log("=== User Vote History ===");
        console.log("User:", user);
        console.log("Total votes:", voteCount);
        
        for (uint i = 0; i < votedPosts.length && i < 10; i++) {
            console.log("Voted post:", votedPosts[i]);
        }
    }
}