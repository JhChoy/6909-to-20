# 6909-to-20

[![Foundry](https://img.shields.io/badge/Built%20with-Foundry-FFDB1C.svg)](https://getfoundry.sh/)
[![License: GPL v2](https://img.shields.io/badge/License-GPL%20v2-blue.svg)](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
[![Solidity](https://img.shields.io/badge/Solidity-^0.8.0-363636.svg)](https://soliditylang.org/)

ERC6909 to ERC20 converter using ERC-7511 minimal proxy clones for gas-efficient token wrapping.

This smart contract allows you to wrap ERC6909 tokens into ERC20 tokens using [ERC-7511 minimal proxy](https://eips.ethereum.org/EIPS/eip-7511) clones for gas-efficient deployment.

Inspired by the [Gnosis 1155-to-20](https://github.com/gnosis/1155-to-20) converter, adapted for the ERC6909 multi-token standard.

## Requirements

- The ERC6909 token must implement `IERC6909Metadata` interface for automatic metadata wrapping

## Deployment

Uses [CreateX](https://github.com/pcaversaccio/createx) for deterministic cross-chain deployments.

### Environment Setup

```bash
# Copy environment template
cp .env.example .env
```

Fill in your `.env` file:
```bash
PRIVATE_KEY=your_private_key_here
RPC_URL=your_rpc_url_here
```

### Deploy

```bash
# Set your desired network RPC URL in .env and run:
./script/deploy.sh
```

The script will deploy the factory contract on the block explorer.

## Features

- **Gas Efficient**: Uses ERC-7511 minimal proxy with PUSH0 optimization (saves 200 gas at deployment, 5 gas at runtime)
- **Deterministic Addresses**: Predictable wrapper addresses
- **Metadata Preservation**: Automatically wraps original token metadata

## Usage

```solidity
// Wrap ERC6909 tokens (without initial deposit - just creates wrapper)
Wrapped6909Factory factory = new Wrapped6909Factory();
address wrappedToken = factory.wrap6909(erc6909Address, tokenId, 0);

// Wrap ERC6909 tokens with deposit
address wrappedTokenWithDeposit = factory.wrap6909(erc6909Address, tokenId, amount);

// Deposit ERC6909 → mint ERC20
IWrapped6909(wrappedToken).depositFor(recipient, amount);

// Withdraw ERC20 → burn and get ERC6909
IWrapped6909(wrappedToken).withdrawTo(recipient, amount);
```

## Development

```bash
git clone JhChoy/6909-to-20
cd 6909-to-20
forge test
```

## References

- [ERC-7511: Minimal Proxy Contract with PUSH0](https://eips.ethereum.org/EIPS/eip-7511)
- [Gnosis 1155-to-20](https://github.com/gnosis/1155-to-20)
- [CreateX](https://github.com/pcaversaccio/createx)

## License

GPL-2.0-or-later
