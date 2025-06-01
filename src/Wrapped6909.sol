// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import {IERC6909} from "@openzeppelin/contracts/interfaces/draft-IERC6909.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

import {IWrapped6909} from "./interfaces/IWrapped6909.sol";

contract Wrapped6909 is ERC20Upgradeable, IWrapped6909 {
    address public token;
    uint256 public tokenId;
    uint8 private _decimals;

    function initialize(address token_, uint256 tokenId_, string memory name_, string memory symbol_, uint8 decimals_)
        external
        initializer
    {
        __ERC20_init(name_, symbol_);
        token = token_;
        tokenId = tokenId_;
        _decimals = decimals_;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function depositFor(address account, uint256 amount) external {
        IERC6909(token).transferFrom(msg.sender, address(this), tokenId, amount);
        _mint(account, amount);
    }

    function withdrawTo(address account, uint256 amount) external {
        _burn(msg.sender, amount);
        IERC6909(token).transfer(account, tokenId, amount);
    }
}
