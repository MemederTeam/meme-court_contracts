// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/MemeCourtVoting.sol";
import "../src/interfaces/IMemeCourtVoting.sol";

contract MemeCourtVotingTest is Test {
    MemeCourtVoting public voting;
    address public owner = address(0x123);
    address public user1 = address(0x456);
    address public user2 = address(0x789);
    
    string constant POST_ID_1 = "post-uuid-123";
    string constant POST_ID_2 = "post-uuid-456";
    string constant CONTENT_HASH = "QmTestHash123";

    event VoteCast(
        address indexed voter,
        string indexed postId,
        bool isFunny,
        uint256 timestamp
    );

    event PostRegistered(
        string indexed postId,
        address indexed creator,
        string contentHash,
        uint256 timestamp
    );

    event VoteChanged(
        address indexed voter,
        string indexed postId,
        bool oldVote,
        bool newVote,
        uint256 timestamp
    );

    function setUp() public {
        vm.prank(owner);
        voting = new MemeCourtVoting();
    }

    function test_Constructor() public {
        assertEq(voting.owner(), owner);
        assertEq(voting.totalVotes(), 0);
        assertEq(voting.totalPosts(), 0);
    }

    function test_RegisterPost() public {
        vm.expectEmit(true, true, false, true);
        emit PostRegistered(POST_ID_1, user1, CONTENT_HASH, block.timestamp);
        
        vm.prank(user1);
        voting.registerPost(POST_ID_1, CONTENT_HASH);
        
        IMemeCourtVoting.PostStats memory stats = voting.getPostStats(POST_ID_1);
        assertTrue(stats.exists);
        assertEq(stats.totalVotes, 0);
        assertEq(stats.funnyVotes, 0);
        assertEq(stats.notFunnyVotes, 0);
        assertEq(voting.totalPosts(), 1);
    }

    function test_RegisterPost_RevertIfAlreadyRegistered() public {
        vm.prank(user1);
        voting.registerPost(POST_ID_1, CONTENT_HASH);
        
        vm.expectRevert("MCV: Post already registered");
        vm.prank(user2);
        voting.registerPost(POST_ID_1, CONTENT_HASH);
    }

    function test_RegisterPost_RevertIfEmptyPostId() public {
        vm.expectRevert("MCV: Invalid post ID");
        vm.prank(user1);
        voting.registerPost("", CONTENT_HASH);
    }

    function test_CastVote_FunnyVote() public {
        vm.expectEmit(true, true, false, true);
        emit VoteCast(user1, POST_ID_1, true, block.timestamp);
        
        vm.prank(user1);
        voting.castVote(POST_ID_1, true);
        
        // Check vote was recorded
        (bool isFunny, uint256 timestamp, bool hasVoted) = voting.getVote(user1, POST_ID_1);
        assertTrue(hasVoted);
        assertTrue(isFunny);
        assertEq(timestamp, block.timestamp);
        
        // Check stats updated
        IMemeCourtVoting.PostStats memory stats = voting.getPostStats(POST_ID_1);
        assertEq(stats.funnyVotes, 1);
        assertEq(stats.notFunnyVotes, 0);
        assertEq(stats.totalVotes, 1);
        
        // Check global stats
        assertEq(voting.totalVotes(), 1);
        assertEq(voting.getUserVoteCount(user1), 1);
    }

    function test_CastVote_NotFunnyVote() public {
        vm.prank(user1);
        voting.castVote(POST_ID_1, false);
        
        (bool isFunny, , bool hasVoted) = voting.getVote(user1, POST_ID_1);
        assertTrue(hasVoted);
        assertFalse(isFunny);
        
        IMemeCourtVoting.PostStats memory stats = voting.getPostStats(POST_ID_1);
        assertEq(stats.funnyVotes, 0);
        assertEq(stats.notFunnyVotes, 1);
        assertEq(stats.totalVotes, 1);
    }

    function test_CastVote_AutoRegisterPost() public {
        // Post not registered initially
        IMemeCourtVoting.PostStats memory statsBefore = voting.getPostStats(POST_ID_1);
        assertFalse(statsBefore.exists);
        
        vm.expectEmit(true, true, false, true);
        emit PostRegistered(POST_ID_1, user1, "", block.timestamp);
        
        vm.prank(user1);
        voting.castVote(POST_ID_1, true);
        
        // Post should be auto-registered
        IMemeCourtVoting.PostStats memory statsAfter = voting.getPostStats(POST_ID_1);
        assertTrue(statsAfter.exists);
        assertEq(voting.totalPosts(), 1);
    }

    function test_CastVote_RevertIfAlreadyVoted() public {
        vm.prank(user1);
        voting.castVote(POST_ID_1, true);
        
        vm.expectRevert("MCV: Already voted");
        vm.prank(user1);
        voting.castVote(POST_ID_1, false);
    }

    function test_MultipleUsersVoting() public {
        // User1 votes funny
        vm.prank(user1);
        voting.castVote(POST_ID_1, true);
        
        // User2 votes not funny
        vm.prank(user2);
        voting.castVote(POST_ID_1, false);
        
        IMemeCourtVoting.PostStats memory stats = voting.getPostStats(POST_ID_1);
        assertEq(stats.funnyVotes, 1);
        assertEq(stats.notFunnyVotes, 1);
        assertEq(stats.totalVotes, 2);
        assertEq(voting.totalVotes(), 2);
    }

    function test_ChangeVote() public {
        // Initial vote
        vm.prank(user1);
        voting.castVote(POST_ID_1, true);
        
        vm.expectEmit(true, true, false, true);
        emit VoteChanged(user1, POST_ID_1, true, false, block.timestamp);
        
        // Change vote
        vm.prank(user1);
        voting.changeVote(POST_ID_1, false);
        
        // Check updated vote
        (bool isFunny, , bool hasVoted) = voting.getVote(user1, POST_ID_1);
        assertTrue(hasVoted);
        assertFalse(isFunny);
        
        // Check updated stats
        IMemeCourtVoting.PostStats memory stats = voting.getPostStats(POST_ID_1);
        assertEq(stats.funnyVotes, 0);
        assertEq(stats.notFunnyVotes, 1);
        assertEq(stats.totalVotes, 1); // Total votes shouldn't change
    }

    function test_ChangeVote_RevertIfNoExistingVote() public {
        vm.expectRevert("MCV: No existing vote");
        vm.prank(user1);
        voting.changeVote(POST_ID_1, true);
    }

    function test_ChangeVote_RevertIfSameValue() public {
        vm.prank(user1);
        voting.castVote(POST_ID_1, true);
        
        vm.expectRevert("MCV: Same vote value");
        vm.prank(user1);
        voting.changeVote(POST_ID_1, true);
    }

    function test_HasVoted() public {
        assertFalse(voting.hasVoted(user1, POST_ID_1));
        
        vm.prank(user1);
        voting.castVote(POST_ID_1, true);
        
        assertTrue(voting.hasVoted(user1, POST_ID_1));
        assertFalse(voting.hasVoted(user2, POST_ID_1));
    }

    function test_GetUserVotedPosts() public {
        vm.prank(user1);
        voting.castVote(POST_ID_1, true);
        
        vm.prank(user1);
        voting.castVote(POST_ID_2, false);
        
        string[] memory votedPosts = voting.getUserVotedPosts(user1);
        assertEq(votedPosts.length, 2);
        assertEq(votedPosts[0], POST_ID_1);
        assertEq(votedPosts[1], POST_ID_2);
    }

    function test_GetVote_NoVote() public {
        (bool isFunny, uint256 timestamp, bool hasVoted) = voting.getVote(user1, POST_ID_1);
        assertFalse(hasVoted);
        assertFalse(isFunny);
        assertEq(timestamp, 0);
    }

    function test_GetPostStats_NonExistentPost() public {
        IMemeCourtVoting.PostStats memory stats = voting.getPostStats("non-existent");
        assertFalse(stats.exists);
        assertEq(stats.totalVotes, 0);
        assertEq(stats.funnyVotes, 0);
        assertEq(stats.notFunnyVotes, 0);
    }

    function testFuzz_CastVote(address voter, bool isFunny) public {
        vm.assume(voter != address(0));
        
        vm.prank(voter);
        voting.castVote(POST_ID_1, isFunny);
        
        (bool recordedVote, , bool hasVoted) = voting.getVote(voter, POST_ID_1);
        assertTrue(hasVoted);
        assertEq(recordedVote, isFunny);
    }
}