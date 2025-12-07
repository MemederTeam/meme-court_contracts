# MemeCourt Smart Contract Integration Guide

## Overview

This guide explains how to integrate the MemeCourt voting smart contract with your existing frontend (Next.js) and backend (NestJS) applications.

## Architecture Integration

```
Frontend (Next.js) → Backend (NestJS) → Smart Contract (MemeCore)
                  ↘                  ↗
                   Database (PostgreSQL)
```

## Smart Contract Interface

### Key Functions

```solidity
// Cast a vote on a post
function castVote(string calldata postId, bool isFunny) external;

// Change an existing vote
function changeVote(string calldata postId, bool newVote) external;

// Get vote information
function getVote(address voter, string calldata postId) 
    external view returns (bool isFunny, uint256 timestamp, bool hasVoted);

// Get post statistics
function getPostStats(string calldata postId) 
    external view returns (PostStats memory);
```

### Events

```solidity
event VoteCast(address indexed voter, string indexed postId, bool isFunny, uint256 timestamp);
event PostRegistered(string indexed postId, address indexed creator, string contentHash, uint256 timestamp);
event VoteChanged(address indexed voter, string indexed postId, bool oldVote, bool newVote, uint256 timestamp);
```

## Backend Integration (NestJS)

### 1. Add Blockchain Service

```typescript
// src/blockchain/blockchain.service.ts
import { Injectable } from '@nestjs/common';
import { ethers } from 'ethers';

@Injectable()
export class BlockchainService {
  private provider: ethers.JsonRpcProvider;
  private contract: ethers.Contract;
  private signer: ethers.Wallet;

  constructor() {
    this.provider = new ethers.JsonRpcProvider(
      'https://rpc.insectarium.memecore.net'
    );
    this.signer = new ethers.Wallet(
      process.env.BLOCKCHAIN_PRIVATE_KEY,
      this.provider
    );
    this.contract = new ethers.Contract(
      process.env.VOTING_CONTRACT_ADDRESS,
      VOTING_ABI,
      this.signer
    );
  }

  async castVote(postId: string, userId: string, isFunny: boolean, userWallet: string) {
    try {
      // Check if user has already voted on-chain
      const hasVoted = await this.contract.hasVoted(userWallet, postId);
      if (hasVoted) {
        throw new Error('User has already voted on this post');
      }

      // Cast vote on blockchain
      const tx = await this.contract.castVote(postId, isFunny);
      const receipt = await tx.wait();

      return {
        success: true,
        transactionHash: receipt.hash,
        blockNumber: receipt.blockNumber
      };
    } catch (error) {
      throw new Error(`Blockchain vote failed: ${error.message}`);
    }
  }

  async getOnChainStats(postId: string) {
    const stats = await this.contract.getPostStats(postId);
    return {
      funnyVotes: Number(stats.funnyVotes),
      notFunnyVotes: Number(stats.notFunnyVotes),
      totalVotes: Number(stats.totalVotes),
      exists: stats.exists
    };
  }

  async getUserVote(userWallet: string, postId: string) {
    const vote = await this.contract.getVote(userWallet, postId);
    return {
      hasVoted: vote.hasVoted,
      isFunny: vote.isFunny,
      timestamp: Number(vote.timestamp)
    };
  }
}
```

### 2. Update Vote Entity

```typescript
// src/entities/vote.entity.ts
@Entity('votes')
export class Vote {
  // ... existing fields

  @Column({ nullable: true })
  blockchain_tx_hash: string; // Store blockchain transaction hash

  @Column({ nullable: true })
  blockchain_block_number: number; // Store block number

  @Column({ default: false })
  on_chain_confirmed: boolean; // Confirmation status

  @Column({ nullable: true })
  user_wallet_address: string; // User's wallet address
}
```

### 3. Enhanced Votes Service

```typescript
// src/modules/votes/votes.service.ts
@Injectable()
export class VotesService {
  constructor(
    @InjectRepository(Vote) private voteRepository: Repository<Vote>,
    private blockchainService: BlockchainService,
  ) {}

  async createVote(createVoteDto: CreateVoteDto & { userWalletAddress: string }) {
    // 1. Check existing vote in database
    const existingVote = await this.voteRepository.findOne({
      where: { user_id: createVoteDto.user_id, post_id: createVoteDto.post_id }
    });

    if (existingVote) {
      throw new ConflictException('이미 투표한 게시글입니다');
    }

    // 2. Cast vote on blockchain first
    const blockchainResult = await this.blockchainService.castVote(
      createVoteDto.post_id,
      createVoteDto.user_id,
      createVoteDto.is_funny,
      createVoteDto.userWalletAddress
    );

    // 3. Save to database with blockchain confirmation
    const vote = this.voteRepository.create({
      ...createVoteDto,
      user_wallet_address: createVoteDto.userWalletAddress,
      blockchain_tx_hash: blockchainResult.transactionHash,
      blockchain_block_number: blockchainResult.blockNumber,
      on_chain_confirmed: true
    });

    await this.voteRepository.save(vote);

    return {
      id: vote.id,
      message: '투표가 완료되었습니다',
      blockchainTx: blockchainResult.transactionHash
    };
  }

  async syncWithBlockchain(postId: string) {
    // Sync database with on-chain data
    const onChainStats = await this.blockchainService.getOnChainStats(postId);
    
    // Compare with database and flag discrepancies
    const dbVotes = await this.voteRepository.count({
      where: { post_id: postId }
    });

    if (dbVotes !== onChainStats.totalVotes) {
      console.warn(`Vote count mismatch for post ${postId}: DB=${dbVotes}, Chain=${onChainStats.totalVotes}`);
    }

    return onChainStats;
  }
}
```

### 4. Updated Vote Controller

```typescript
// src/modules/votes/votes.controller.ts
@Controller('votes')
export class VotesController {
  constructor(private readonly votesService: VotesService) {}

  @Post()
  async createVote(@Body() createVoteDto: CreateVoteDto & { userWalletAddress: string }) {
    return this.votesService.createVote(createVoteDto);
  }

  @Get('sync/:postId')
  async syncPostVotes(@Param('postId') postId: string) {
    return this.votesService.syncWithBlockchain(postId);
  }

  @Get('on-chain/:postId')
  async getOnChainStats(@Param('postId') postId: string) {
    return this.blockchainService.getOnChainStats(postId);
  }
}
```

## Frontend Integration (Next.js)

### 1. Blockchain Hook

```typescript
// src/hooks/useBlockchain.ts
import { useState, useCallback } from 'react';
import { ethers } from 'ethers';

export function useBlockchain() {
  const [isConnecting, setIsConnecting] = useState(false);
  const [walletAddress, setWalletAddress] = useState<string>('');

  const connectWallet = useCallback(async () => {
    if (typeof window.ethereum !== 'undefined') {
      try {
        setIsConnecting(true);
        await window.ethereum.request({ method: 'eth_requestAccounts' });
        const provider = new ethers.BrowserProvider(window.ethereum);
        const signer = await provider.getSigner();
        const address = await signer.getAddress();
        setWalletAddress(address);
        
        // Switch to MemeCore testnet if needed
        await switchToMemeCore();
        
        return address;
      } catch (error) {
        console.error('Failed to connect wallet:', error);
        throw error;
      } finally {
        setIsConnecting(false);
      }
    } else {
      throw new Error('MetaMask not installed');
    }
  }, []);

  const switchToMemeCore = async () => {
    try {
      await window.ethereum.request({
        method: 'wallet_switchEthereumChain',
        params: [{ chainId: '0x539' }], // 1337 in hex
      });
    } catch (switchError: any) {
      // Add network if not exists
      if (switchError.code === 4902) {
        await window.ethereum.request({
          method: 'wallet_addEthereumChain',
          params: [{
            chainId: '0x539',
            chainName: 'MemeCore Testnet',
            nativeCurrency: { name: 'M Token', symbol: 'M', decimals: 18 },
            rpcUrls: ['https://rpc.insectarium.memecore.net'],
            blockExplorerUrls: ['https://insectarium.memecorescan.io/']
          }]
        });
      }
    }
  };

  return {
    connectWallet,
    walletAddress,
    isConnecting
  };
}
```

### 2. Enhanced PostInteractions Component

```typescript
// src/components/ui/PostInteractions.tsx
"use client";

import { useState } from 'react';
import { useFeedStore } from "@/store/feedStore";
import { useBlockchain } from "@/hooks/useBlockchain";

interface PostInteractionsProps {
  // ... existing props
  postId: string;
  onVoteSuccess?: (txHash: string) => void;
}

export default function PostInteractions({ 
  likes, 
  comments, 
  shares, 
  views,
  postId,
  onLike,
  onComment,
  onShare,
  onVoteSuccess
}: PostInteractionsProps) {
  const { postInteractions, toggleLike } = useFeedStore();
  const { connectWallet, walletAddress } = useBlockchain();
  const [isVoting, setIsVoting] = useState(false);
  
  const interaction = postInteractions[postId];
  const isLiked = interaction?.isLiked || false;
  const likeCount = interaction?.likes || likes;

  const handleLike = async () => {
    try {
      setIsVoting(true);

      // Connect wallet if not connected
      let wallet = walletAddress;
      if (!wallet) {
        wallet = await connectWallet();
      }

      // Call backend API with wallet address
      const response = await fetch('/api/votes', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          post_id: postId,
          user_id: 'current-user-id', // Get from auth context
          is_funny: true,
          userWalletAddress: wallet
        })
      });

      const result = await response.json();
      
      if (result.success) {
        toggleLike(postId, likes);
        onVoteSuccess?.(result.blockchainTx);
        
        // Show success message with blockchain confirmation
        console.log(`Vote recorded on blockchain: ${result.blockchainTx}`);
      }
      
      if (onLike) onLike();
    } catch (error) {
      console.error('Vote failed:', error);
      // Show error message to user
    } finally {
      setIsVoting(false);
    }
  };

  return (
    <div className="flex items-center justify-between px-4 py-3 bg-black/20 backdrop-blur-sm">
      <div className="flex items-center space-x-6">
        <button 
          onClick={handleLike}
          disabled={isVoting}
          className={`flex items-center space-x-1 text-white transition-colors ${
            isVoting ? 'opacity-50 cursor-not-allowed' : 'hover:text-red-400'
          }`}
        >
          {isVoting ? (
            <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin" />
          ) : (
            <svg className="w-5 h-5" fill={isLiked ? "currentColor" : "none"} stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z" />
            </svg>
          )}
          <span className="text-sm">{likeCount}</span>
        </button>
        {/* ... other buttons ... */}
      </div>
    </div>
  );
}
```

## Environment Configuration

### Backend (.env)

```bash
# Blockchain Configuration
BLOCKCHAIN_PRIVATE_KEY=your_private_key_here
VOTING_CONTRACT_ADDRESS=0x_deployed_contract_address
MEMECORE_RPC_URL=https://rpc.insectarium.memecore.net
```

### Frontend (.env.local)

```bash
# Blockchain Configuration
NEXT_PUBLIC_VOTING_CONTRACT_ADDRESS=0x_deployed_contract_address
NEXT_PUBLIC_MEMECORE_RPC=https://rpc.insectarium.memecore.net
NEXT_PUBLIC_CHAIN_ID=1337
```

## Deployment Checklist

1. **Deploy Smart Contract**
   ```bash
   cd memecourt_contracts
   make setup
   # Edit .env with your private key
   make deploy
   ```

2. **Update Backend**
   - Add blockchain service
   - Update vote entity with blockchain fields
   - Modify votes service for dual recording
   - Update API endpoints

3. **Update Frontend**
   - Add wallet connection
   - Integrate blockchain hooks
   - Update voting components
   - Add transaction confirmation UI

4. **Test Integration**
   - Test wallet connection
   - Verify vote recording on both database and blockchain
   - Check synchronization between systems
   - Monitor gas costs and transaction times

## Monitoring and Maintenance

- Monitor blockchain transaction failures
- Implement retry mechanisms for failed votes
- Periodic synchronization between database and blockchain
- Gas cost optimization
- Event listening for real-time updates

## Security Considerations

- Never expose private keys in frontend
- Validate all user inputs before blockchain transactions
- Implement rate limiting for vote submissions
- Monitor for suspicious voting patterns
- Regular security audits of smart contracts