// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {IERC6909Metadata} from "@openzeppelin/contracts/interfaces/draft-IERC6909.sol";

import {Wrapped6909} from "./Wrapped6909.sol";
import {IWrapped6909Factory} from "./interfaces/IWrapped6909Factory.sol";

contract Wrapped6909Factory is IWrapped6909Factory {
    address public immutable implementation;

    constructor() {
        implementation = address(new Wrapped6909());
    }

    function getWrapped6909Address(address token, uint256 tokenId) external view returns (address) {
        bytes32 salt = keccak256(abi.encode(token, tokenId));
        return Clones.predictDeterministicAddress(implementation, salt);
    }

    function createWrapped6909(address token, uint256 tokenId) external returns (address) {
        // Generate deterministic salt from token address and ID
        bytes32 salt = keccak256(abi.encode(token, tokenId));
        
        // Deploy minimal proxy clone using CREATE2 for deterministic address
        address wrapped6909 = Clones.cloneDeterministic(implementation, salt);

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
}
