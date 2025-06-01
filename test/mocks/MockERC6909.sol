// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC6909Metadata} from "@openzeppelin/contracts/interfaces/draft-IERC6909.sol";
import {ERC6909} from "@openzeppelin/contracts/token/ERC6909/draft-ERC6909.sol";

contract MockERC6909 is ERC6909, IERC6909Metadata {
    mapping(uint256 => string) private _names;
    mapping(uint256 => string) private _symbols;
    mapping(uint256 => uint8) private _decimals;

    function mint(address to, uint256 id, uint256 amount) external {
        _mint(to, id, amount);
    }

    function setMetadata(uint256 id, string memory name_, string memory symbol_, uint8 decimals_) external {
        _names[id] = name_;
        _symbols[id] = symbol_;
        _decimals[id] = decimals_;
    }

    function name(uint256 id) external view returns (string memory) {
        return _names[id];
    }

    function symbol(uint256 id) external view returns (string memory) {
        return _symbols[id];
    }

    function decimals(uint256 id) external view returns (uint8) {
        return _decimals[id];
    }
}
