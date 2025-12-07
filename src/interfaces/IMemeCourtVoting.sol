// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title IMemeCourtVoting
 * @dev Interface for MemeCourt voting system
 */
interface IMemeCourtVoting {
    // Structs
    struct Vote {
        address voter;
        string postId;
        bool isFunny;
        uint256 timestamp;
    }

    struct PostStats {
        uint256 funnyVotes;
        uint256 notFunnyVotes;
        uint256 totalVotes;
        bool exists;
    }

    // Events
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

    // Functions
    function castVote(string calldata postId, bool isFunny) external;
    function changeVote(string calldata postId, bool newVote) external;
    function getVote(address voter, string calldata postId) external view returns (bool isFunny, uint256 timestamp, bool hasVoted);
    function getPostStats(string calldata postId) external view returns (PostStats memory);
    function hasVoted(address voter, string calldata postId) external view returns (bool);
    function registerPost(string calldata postId, string calldata contentHash) external;
}