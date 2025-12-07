# MemeCourt Smart Contracts

A decentralized voting system for meme posts on MemeCore testnet.

## Overview

MemeCourt enables users to vote on meme posts with like/dislike functionality, recording all votes immutably on-chain while maintaining compatibility with existing backend systems.

## Architecture

- **MemeCourtVoting.sol**: Core voting contract
- **PostRegistry.sol**: Post metadata management
- **VoteToken.sol**: Optional governance token (future use)

## Key Features

- ✅ Immutable vote recording
- ✅ One vote per user per post
- ✅ Gas-optimized operations
- ✅ Event-driven architecture for off-chain indexing
- ✅ Backend integration compatibility

## Network: MemeCore Testnet (Formicarium)

- **RPC**: `https://rpc.formicarium.memecore.net`
- **Explorer**: `https://formicarium.memecorescan.io/`
- **Chain ID**: `1337`
- **Gas Token**: MEME Token

## Quick Start

```bash
# Install dependencies
forge install

# Compile contracts
forge build

# Run tests
forge test

# Deploy to testnet (Foundry)
forge script script/Deploy.s.sol --rpc-url $MEMECORE_RPC --broadcast

# Deploy with ethers.js (alternative)
npm install ethers
npm run deploy:js
```

## Deployed Contract

- **Contract Address**: `0x1075f4BdAd2667041911E2Bd4b986b7a1163A470`
- **Network**: MemeCore Testnet (Formicarium)
- **Block Explorer**: [View Contract](https://formicarium.memecorescan.io/address/0x1075f4BdAd2667041911E2Bd4b986b7a1163A470)

## Integration

### Frontend (React + ethers.js)

```javascript
import { ethers } from 'ethers';

const CONTRACT_ADDRESS = '0x1075f4BdAd2667041911E2Bd4b986b7a1163A470';
const provider = new ethers.BrowserProvider(window.ethereum);
const contract = new ethers.Contract(CONTRACT_ADDRESS, ABI, signer);

// Cast vote
await contract.castVote(postId, isFunny);
```

### Backend (Node.js + ethers.js)

```javascript
const { ethers } = require('ethers');

const provider = new ethers.JsonRpcProvider('https://rpc.formicarium.memecore.net');
const contract = new ethers.Contract(CONTRACT_ADDRESS, ABI, provider);

// Read vote stats
const stats = await contract.getPostStats(postId);
```