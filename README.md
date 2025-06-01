# 6909-to-20

ERC6909 to ERC20 converter

This smart contract allows you to wrap ERC6909 tokens into ERC20 tokens using minimal proxy clones for gas-efficient deployment.

Inspired by the [Gnosis 1155-to-20](https://github.com/gnosis/1155-to-20) converter, adapted for the ERC6909 multi-token standard.

## Requirements

- The ERC6909 token must implement `IERC6909Metadata` interface for automatic metadata wrapping

## Features

- **Gas Efficient**: Uses OpenZeppelin's Clones library
- **Deterministic Addresses**: Predictable wrapper addresses
- **Metadata Preservation**: Automatically wraps original token metadata

## Usage

```solidity
// Create wrapped token
Wrapped6909Factory factory = new Wrapped6909Factory();
address wrappedToken = factory.createWrapped6909(erc6909Address, tokenId);

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

## License

GPL-2.0-or-later
