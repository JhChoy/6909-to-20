// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import {IERC6909Metadata} from "@openzeppelin/contracts/interfaces/draft-IERC6909.sol";

import {Wrapped6909} from "./Wrapped6909.sol";
import {IWrapped6909Factory} from "./interfaces/IWrapped6909Factory.sol";

contract Wrapped6909Factory is IWrapped6909Factory {
    address internal immutable _implementation;

    constructor() {
        _implementation = address(new Wrapped6909());
    }

    function getImplementation() external view returns (address) {
        return _implementation;
    }

    function getWrapped6909Address(address token, uint256 tokenId) external view returns (address) {
        bytes32 salt = keccak256(abi.encode(token, tokenId));
        return _predictDeterministicAddress(_implementation, salt);
    }

    function createWrapped6909(address token, uint256 tokenId) external returns (address) {
        // Generate deterministic salt from token address and ID
        bytes32 salt = keccak256(abi.encode(token, tokenId));

        // Deploy ERC-7511 minimal proxy clone using CREATE2 for deterministic address
        address wrapped6909 = _clone0(_implementation, salt);

        // Fetch metadata from the original ERC6909 token
        string memory name = IERC6909Metadata(token).name(tokenId);
        name = string.concat("Wrapped ", name);
        string memory symbol = IERC6909Metadata(token).symbol(tokenId);
        symbol = string.concat("w", symbol);
        uint8 decimals = IERC6909Metadata(token).decimals(tokenId);

        // Initialize the cloned contract with metadata and token info
        Wrapped6909(wrapped6909).initialize(token, tokenId, name, symbol, decimals);

        emit Wrapped6909Created(token, tokenId, wrapped6909);
        return wrapped6909;
    }

    /// @notice Deploy ERC-7511 minimal proxy clone with PUSH0 optimization
    /// @dev Uses optimized bytecode that saves 200 gas at deployment and 5 gas at runtime
    function _clone0(address implementation, bytes32 salt) internal returns (address instance) {
        assembly ("memory-safe") {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x602c8060095f395ff3365f5f375f5f365f73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d5f5f3e5f3d91602a57fd5bf3))
            instance := create2(0, 0x0b, 0x35, salt)
        }
        if (instance == address(0)) {
            revert FailedCreateClone();
        }
    }

    /// @notice Predict the address of an ERC-7511 clone before deployment
    function _predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        assembly ("memory-safe") {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), address())
            mstore(add(ptr, 0x24), 0x5af43d5f5f3e5f3d91602a57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x602c8060095f395ff3365f5f375f5f365f73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0e), 0x35))
            predicted := and(keccak256(add(ptr, 0x43), 0x55), 0xffffffffffffffffffffffffffffffffffffffff)
        }
    }
}
