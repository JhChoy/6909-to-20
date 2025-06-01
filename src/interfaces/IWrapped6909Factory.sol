// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

/// @title IWrapped6909Factory
/// @author JChoy
/// @notice Interface for factory contract that creates wrapped ERC6909 tokens
interface IWrapped6909Factory {
    /// @notice Emitted when the clone fails
    error FailedCreateClone();

    /// @notice Emitted when a new wrapped ERC6909 token is created
    /// @param token The address of the underlying ERC6909 token
    /// @param tokenId The token ID that was wrapped
    /// @param wrapped6909 The address of the created wrapped token
    event Wrapped6909Created(address indexed token, uint256 indexed tokenId, address indexed wrapped6909);

    /// @notice The implementation contract address used for cloning
    function getImplementation() external view returns (address);

    /// @notice Predict the address of a wrapped token before creation
    /// @param token The address of the ERC6909 token to wrap
    /// @param tokenId The token ID to wrap
    /// @return The predicted address of the wrapped token
    function getWrapped6909Address(address token, uint256 tokenId) external view returns (address);

    /// @notice Create a new wrapped ERC6909 token
    /// @param token The address of the ERC6909 token to wrap
    /// @param tokenId The token ID to wrap
    /// @return The address of the created wrapped token
    function createWrapped6909(address token, uint256 tokenId) external returns (address);
}
