// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWrapped6909 is IERC20 {
    /// @notice The underlying ERC6909 token contract address
    function token() external view returns (address);

    /// @notice The token ID of the underlying ERC6909 token
    function tokenId() external view returns (uint256);

    /// @notice Deposit ERC6909 tokens and mint wrapped tokens to an account
    /// @param account The account to mint wrapped tokens to
    /// @param amount The amount of tokens to deposit and wrap
    function depositFor(address account, uint256 amount) external;

    /// @notice Burn wrapped tokens and withdraw ERC6909 tokens to an account
    /// @param account The account to burn wrapped tokens from
    /// @param amount The amount of wrapped tokens to burn
    function withdrawTo(address account, uint256 amount) external;
}
