# MemeCourt Smart Contract API Documentation

## Contract Address (Testnet)

**MemeCore Testnet**: `0x...` (Deploy using `make deploy`)

## Contract ABI

```json
[
  {
    "type": "constructor",
    "inputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "castVote",
    "inputs": [
      {"name": "postId", "type": "string", "internalType": "string"},
      {"name": "isFunny", "type": "bool", "internalType": "bool"}
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function", 
    "name": "changeVote",
    "inputs": [
      {"name": "postId", "type": "string", "internalType": "string"},
      {"name": "newVote", "type": "bool", "internalType": "bool"}
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "getVote", 
    "inputs": [
      {"name": "voter", "type": "address", "internalType": "address"},
      {"name": "postId", "type": "string", "internalType": "string"}
    ],
    "outputs": [
      {"name": "isFunny", "type": "bool", "internalType": "bool"},
      {"name": "timestamp", "type": "uint256", "internalType": "uint256"},
      {"name": "hasVoted", "type": "bool", "internalType": "bool"}
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getPostStats",
    "inputs": [
      {"name": "postId", "type": "string", "internalType": "string"}
    ],
    "outputs": [
      {
        "name": "",
        "type": "tuple",
        "internalType": "struct IMemeCourtVoting.PostStats",
        "components": [
          {"name": "funnyVotes", "type": "uint256", "internalType": "uint256"},
          {"name": "notFunnyVotes", "type": "uint256", "internalType": "uint256"},
          {"name": "totalVotes", "type": "uint256", "internalType": "uint256"},
          {"name": "exists", "type": "bool", "internalType": "bool"}
        ]
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "hasVoted",
    "inputs": [
      {"name": "voter", "type": "address", "internalType": "address"}, 
      {"name": "postId", "type": "string", "internalType": "string"}
    ],
    "outputs": [
      {"name": "", "type": "bool", "internalType": "bool"}
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "registerPost",
    "inputs": [
      {"name": "postId", "type": "string", "internalType": "string"},
      {"name": "contentHash", "type": "string", "internalType": "string"}
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "event",
    "name": "VoteCast",
    "inputs": [
      {"name": "voter", "type": "address", "indexed": true, "internalType": "address"},
      {"name": "postId", "type": "string", "indexed": true, "internalType": "string"},
      {"name": "isFunny", "type": "bool", "indexed": false, "internalType": "bool"},
      {"name": "timestamp", "type": "uint256", "indexed": false, "internalType": "uint256"}
    ],
    "anonymous": false
  },
  {
    "type": "event", 
    "name": "PostRegistered",
    "inputs": [
      {"name": "postId", "type": "string", "indexed": true, "internalType": "string"},
      {"name": "creator", "type": "address", "indexed": true, "internalType": "address"}, 
      {"name": "contentHash", "type": "string", "indexed": false, "internalType": "string"},
      {"name": "timestamp", "type": "uint256", "indexed": false, "internalType": "uint256"}
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "VoteChanged", 
    "inputs": [
      {"name": "voter", "type": "address", "indexed": true, "internalType": "address"},
      {"name": "postId", "type": "string", "indexed": true, "internalType": "string"},
      {"name": "oldVote", "type": "bool", "indexed": false, "internalType": "bool"},
      {"name": "newVote", "type": "bool", "indexed": false, "internalType": "bool"},
      {"name": "timestamp", "type": "uint256", "indexed": false, "internalType": "uint256"}
    ],
    "anonymous": false
  }
]
```

## Functions

### Write Functions (Require Transaction)

#### `castVote(string postId, bool isFunny)`

Cast a vote on a meme post.

**Parameters:**
- `postId` (string): Unique identifier for the post
- `isFunny` (bool): `true` for like/funny, `false` for dislike/not funny

**Returns:** Transaction hash

**Events Emitted:** 
- `VoteCast(voter, postId, isFunny, timestamp)`
- `PostRegistered(postId, creator, contentHash, timestamp)` (if post not previously registered)

**Reverts:**
- `"MCV: Invalid post ID"` - Empty post ID
- `"MCV: Already voted"` - User has already voted on this post

**Gas Estimate:** ~50,000 gas

---

#### `changeVote(string postId, bool newVote)`

Change an existing vote on a post.

**Parameters:**
- `postId` (string): Post identifier
- `newVote` (bool): New vote value

**Returns:** Transaction hash

**Events Emitted:** `VoteChanged(voter, postId, oldVote, newVote, timestamp)`

**Reverts:**
- `"MCV: No existing vote"` - User hasn't voted on this post
- `"MCV: Same vote value"` - New vote is same as current vote

**Gas Estimate:** ~30,000 gas

---

#### `registerPost(string postId, string contentHash)`

Register a new post (optional - posts are auto-registered when first vote is cast).

**Parameters:**
- `postId` (string): Unique post identifier
- `contentHash` (string): IPFS hash or content identifier

**Returns:** Transaction hash

**Events Emitted:** `PostRegistered(postId, creator, contentHash, timestamp)`

**Reverts:**
- `"MCV: Post already registered"` - Post ID already exists

**Gas Estimate:** ~40,000 gas

---

### Read Functions (No Transaction Required)

#### `getVote(address voter, string postId)` 

Get vote information for a specific voter and post.

**Parameters:**
- `voter` (address): Voter's wallet address
- `postId` (string): Post identifier

**Returns:**
- `isFunny` (bool): Vote value (true = funny, false = not funny)
- `timestamp` (uint256): Unix timestamp when vote was cast
- `hasVoted` (bool): Whether the user has voted

**Example Response:**
```json
{
  "isFunny": true,
  "timestamp": 1703123456,
  "hasVoted": true
}
```

---

#### `getPostStats(string postId)`

Get aggregated statistics for a post.

**Parameters:**
- `postId` (string): Post identifier

**Returns:** `PostStats` struct:
- `funnyVotes` (uint256): Number of funny/like votes
- `notFunnyVotes` (uint256): Number of not funny/dislike votes  
- `totalVotes` (uint256): Total number of votes
- `exists` (bool): Whether the post exists

**Example Response:**
```json
{
  "funnyVotes": 42,
  "notFunnyVotes": 18, 
  "totalVotes": 60,
  "exists": true
}
```

---

#### `hasVoted(address voter, string postId)`

Check if a user has voted on a post.

**Parameters:**
- `voter` (address): Voter's wallet address
- `postId` (string): Post identifier

**Returns:** `bool` - Whether user has voted

---

#### `getUserVotedPosts(address user)`

Get list of all posts a user has voted on.

**Parameters:**
- `user` (address): User's wallet address

**Returns:** `string[]` - Array of post IDs

---

#### `getUserVoteCount(address user)`

Get total number of votes cast by a user.

**Parameters:**
- `user` (address): User's wallet address

**Returns:** `uint256` - Vote count

---

## Events

### `VoteCast`

Emitted when a new vote is cast.

```solidity
event VoteCast(
    address indexed voter,
    string indexed postId, 
    bool isFunny,
    uint256 timestamp
);
```

### `PostRegistered`

Emitted when a post is registered.

```solidity
event PostRegistered(
    string indexed postId,
    address indexed creator,
    string contentHash,
    uint256 timestamp
);
```

### `VoteChanged` 

Emitted when a vote is modified.

```solidity
event VoteChanged(
    address indexed voter,
    string indexed postId,
    bool oldVote,
    bool newVote, 
    uint256 timestamp
);
```

## JavaScript/TypeScript Integration

### Setup

```javascript
import { ethers } from 'ethers';

const provider = new ethers.JsonRpcProvider('https://rpc.insectarium.memecore.net');
const contract = new ethers.Contract(CONTRACT_ADDRESS, ABI, provider);

// For write operations, use a signer
const signer = new ethers.Wallet(PRIVATE_KEY, provider);
const contractWithSigner = contract.connect(signer);
```

### Read Examples

```javascript
// Get post statistics
const stats = await contract.getPostStats('post-123');
console.log(`Funny: ${stats.funnyVotes}, Not Funny: ${stats.notFunnyVotes}`);

// Check if user voted
const hasVoted = await contract.hasVoted('0x...', 'post-123');
console.log(`Has voted: ${hasVoted}`);

// Get user's vote details
const vote = await contract.getVote('0x...', 'post-123');
if (vote.hasVoted) {
    console.log(`Voted ${vote.isFunny ? 'funny' : 'not funny'} at ${new Date(vote.timestamp * 1000)}`);
}
```

### Write Examples

```javascript
// Cast a vote
try {
    const tx = await contractWithSigner.castVote('post-123', true);
    const receipt = await tx.wait();
    console.log(`Vote cast in block ${receipt.blockNumber}, tx: ${receipt.hash}`);
} catch (error) {
    console.error('Vote failed:', error.message);
}

// Change a vote  
try {
    const tx = await contractWithSigner.changeVote('post-123', false);
    await tx.wait();
    console.log('Vote changed successfully');
} catch (error) {
    console.error('Vote change failed:', error.message);
}

// Register a post
try {
    const tx = await contractWithSigner.registerPost('post-456', 'QmHash123');
    await tx.wait();
    console.log('Post registered');
} catch (error) {
    console.error('Registration failed:', error.message);
}
```

### Event Listening

```javascript
// Listen for new votes
contract.on('VoteCast', (voter, postId, isFunny, timestamp) => {
    console.log(`New vote: ${voter} voted ${isFunny ? 'funny' : 'not funny'} on ${postId}`);
});

// Listen for all events
contract.on('*', (event) => {
    console.log('Contract event:', event);
});

// Get past events
const filter = contract.filters.VoteCast('0x...'); // Votes from specific address
const events = await contract.queryFilter(filter, -1000); // Last 1000 blocks
```

## Error Handling

Common error patterns and handling:

```javascript
try {
    await contractWithSigner.castVote(postId, isFunny);
} catch (error) {
    if (error.message.includes('Already voted')) {
        // User has already voted
        console.error('You have already voted on this post');
    } else if (error.message.includes('Invalid post ID')) {
        // Invalid post ID
        console.error('Invalid post identifier');
    } else if (error.code === 'INSUFFICIENT_FUNDS') {
        // Not enough gas
        console.error('Insufficient balance for transaction');
    } else {
        // Other errors
        console.error('Transaction failed:', error.message);
    }
}
```

## Gas Optimization Tips

1. **Batch Operations**: Register posts in batches if creating multiple posts
2. **Vote Timing**: Consider gas prices during off-peak hours  
3. **Estimating Gas**: Use `estimateGas()` before transactions
4. **Error Prevention**: Check `hasVoted()` before calling `castVote()`

```javascript
// Gas estimation
const gasEstimate = await contract.estimateGas.castVote(postId, isFunny);
console.log(`Estimated gas: ${gasEstimate.toString()}`);

// Set gas limit with buffer
const tx = await contractWithSigner.castVote(postId, isFunny, {
    gasLimit: gasEstimate.mul(120).div(100) // 20% buffer
});
```