# MemeCourt Smart Contract Makefile

-include .env

.PHONY: help install build test deploy verify clean

help: ## Show available commands
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

install: ## Install dependencies
	@forge install foundry-rs/forge-std

build: ## Compile contracts
	@forge build

test: ## Run tests
	@forge test -vvv

test-gas: ## Run tests with gas reports
	@forge test --gas-report

test-coverage: ## Run test coverage
	@forge coverage

clean: ## Clean build artifacts
	@forge clean

# Deployment
deploy: ## Deploy to MemeCore testnet
	@forge script script/Deploy.s.sol:DeployMemeCourt --rpc-url $(MEMECORE_RPC) --broadcast --verify -vvvv

deploy-local: ## Deploy to local test network
	@forge script script/Deploy.s.sol:DeployMemeCourt --rpc-url http://localhost:8545 --broadcast -vvvv

# Verification
verify: ## Verify contract on MemeCoreScan
	@forge verify-contract $(VOTING_CONTRACT_ADDRESS) src/MemeCourtVoting.sol:MemeCourtVoting --chain-id $(CHAIN_ID) --etherscan-api-key $(MEMECORE_API_KEY)

# Interactions
demo: ## Run demo interactions
	@forge script script/Interactions.s.sol:MemeCourtInteractions --rpc-url $(MEMECORE_RPC) --broadcast -vvvv

register-post: ## Register a new post (set POST_ID and CONTENT_HASH)
	@forge script script/Interactions.s.sol:MemeCourtInteractions --sig "registerPost(string,string)" "$(POST_ID)" "$(CONTENT_HASH)" --rpc-url $(MEMECORE_RPC) --broadcast

cast-vote: ## Cast a vote (set POST_ID and IS_FUNNY)
	@forge script script/Interactions.s.sol:MemeCourtInteractions --sig "castVote(string,bool)" "$(POST_ID)" "$(IS_FUNNY)" --rpc-url $(MEMECORE_RPC) --broadcast

get-stats: ## Get post statistics (set POST_ID)
	@forge script script/Interactions.s.sol:MemeCourtInteractions --sig "getPostStats(string)" "$(POST_ID)" --rpc-url $(MEMECORE_RPC)

get-user-votes: ## Get user vote history (set USER_ADDRESS)
	@forge script script/Interactions.s.sol:MemeCourtInteractions --sig "getUserVotes(address)" "$(USER_ADDRESS)" --rpc-url $(MEMECORE_RPC)

# Development
format: ## Format code
	@forge fmt

lint: ## Lint code
	@forge fmt --check

security: ## Run security analysis (requires slither)
	@slither .

# Setup
setup: ## Initial project setup
	@echo "Setting up MemeCourt Smart Contracts..."
	@cp .env.example .env
	@echo "1. Edit .env with your configuration"
	@echo "2. Run 'make install' to install dependencies"
	@echo "3. Run 'make test' to verify everything works"
	@echo "4. Run 'make deploy' to deploy to MemeCore testnet"

# Quick commands
all: clean install build test ## Clean, install, build and test

quick-deploy: build deploy ## Build and deploy in one command