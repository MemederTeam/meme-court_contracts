// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./interfaces/IMemeCourtVoting.sol";

/**
 * @title MemeCourtVoting
 * @dev Core voting contract for MemeCourt platform
 * @notice Records like/dislike votes on meme posts immutably on MemeCore blockchain
 */
contract MemeCourtVoting is IMemeCourtVoting {
    // State variables
    mapping(bytes32 => Vote) private _votes; // keccak256(voter, postId) => Vote
    mapping(string => PostStats) private _postStats;
    mapping(string => bool) private _registeredPosts;
    mapping(address => string[]) private _userVotes; // Track user's voted posts
    
    address public owner;
    uint256 public totalVotes;
    uint256 public totalPosts;

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "MCV: Only owner");
        _;
    }

    modifier validPostId(string calldata postId) {
        require(bytes(postId).length > 0, "MCV: Invalid post ID");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Register a new post (can be called by anyone)
     * @param postId Unique identifier for the post
     * @param contentHash IPFS or content hash for verification
     */
    function registerPost(
        string calldata postId, 
        string calldata contentHash
    ) 
        external 
        validPostId(postId) 
    {
        require(!_registeredPosts[postId], "MCV: Post already registered");
        
        _registeredPosts[postId] = true;
        _postStats[postId] = PostStats({
            funnyVotes: 0,
            notFunnyVotes: 0,
            totalVotes: 0,
            exists: true
        });
        
        totalPosts++;
        
        emit PostRegistered(postId, msg.sender, contentHash, block.timestamp);
    }

    /**
     * @dev Cast a vote on a post (like/dislike)
     * @param postId ID of the post to vote on
     * @param isFunny true for like, false for dislike
     */
    function castVote(
        string calldata postId, 
        bool isFunny
    ) 
        external 
        validPostId(postId) 
    {
        bytes32 voteKey = _getVoteKey(msg.sender, postId);
        require(_votes[voteKey].voter == address(0), "MCV: Already voted");

        // Auto-register post if not exists
        if (!_registeredPosts[postId]) {
            _registeredPosts[postId] = true;
            _postStats[postId] = PostStats({
                funnyVotes: 0,
                notFunnyVotes: 0,
                totalVotes: 0,
                exists: true
            });
            totalPosts++;
            emit PostRegistered(postId, msg.sender, "", block.timestamp);
        }

        // Record vote
        _votes[voteKey] = Vote({
            voter: msg.sender,
            postId: postId,
            isFunny: isFunny,
            timestamp: block.timestamp
        });

        // Update statistics
        PostStats storage stats = _postStats[postId];
        if (isFunny) {
            stats.funnyVotes++;
        } else {
            stats.notFunnyVotes++;
        }
        stats.totalVotes++;
        
        // Track user votes
        _userVotes[msg.sender].push(postId);
        
        totalVotes++;

        emit VoteCast(msg.sender, postId, isFunny, block.timestamp);
    }

    /**
     * @dev Change an existing vote
     * @param postId ID of the post
     * @param newVote New vote value
     */
    function changeVote(
        string calldata postId, 
        bool newVote
    ) 
        external 
        validPostId(postId) 
    {
        bytes32 voteKey = _getVoteKey(msg.sender, postId);
        Vote storage vote = _votes[voteKey];
        
        require(vote.voter != address(0), "MCV: No existing vote");
        require(vote.isFunny != newVote, "MCV: Same vote value");

        bool oldVote = vote.isFunny;
        
        // Update vote
        vote.isFunny = newVote;
        vote.timestamp = block.timestamp;

        // Update statistics
        PostStats storage stats = _postStats[postId];
        if (oldVote) {
            stats.funnyVotes--;
            stats.notFunnyVotes++;
        } else {
            stats.notFunnyVotes--;
            stats.funnyVotes++;
        }

        emit VoteChanged(msg.sender, postId, oldVote, newVote, block.timestamp);
    }

    /**
     * @dev Get vote information for a user and post
     */
    function getVote(
        address voter, 
        string calldata postId
    ) 
        external 
        view 
        returns (bool isFunny, uint256 timestamp, bool hasVoted) 
    {
        bytes32 voteKey = _getVoteKey(voter, postId);
        Vote memory vote = _votes[voteKey];
        
        if (vote.voter != address(0)) {
            return (vote.isFunny, vote.timestamp, true);
        }
        return (false, 0, false);
    }

    /**
     * @dev Get statistics for a post
     */
    function getPostStats(string calldata postId) 
        external 
        view 
        returns (PostStats memory) 
    {
        return _postStats[postId];
    }

    /**
     * @dev Check if user has voted on a post
     */
    function hasVoted(address voter, string calldata postId) 
        external 
        view 
        returns (bool) 
    {
        bytes32 voteKey = _getVoteKey(voter, postId);
        return _votes[voteKey].voter != address(0);
    }

    /**
     * @dev Get all posts a user has voted on
     */
    function getUserVotedPosts(address user) 
        external 
        view 
        returns (string[] memory) 
    {
        return _userVotes[user];
    }

    /**
     * @dev Get user vote count
     */
    function getUserVoteCount(address user) 
        external 
        view 
        returns (uint256) 
    {
        return _userVotes[user].length;
    }

    /**
     * @dev Emergency pause (only owner)
     */
    function pause() external onlyOwner {
        // Implementation for emergency pause if needed
        revert("MCV: Not implemented");
    }

    /**
     * @dev Generate unique key for vote mapping
     */
    function _getVoteKey(address voter, string calldata postId) 
        private 
        pure 
        returns (bytes32) 
    {
        return keccak256(abi.encodePacked(voter, postId));
    }
}