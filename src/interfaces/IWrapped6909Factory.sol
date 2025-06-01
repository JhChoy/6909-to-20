// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

interface IWrapped6909Factory {
    event Wrapped6909Created(address indexed token, uint256 indexed tokenId, address indexed wrapped6909);

    function getWrapped6909Address(address token, uint256 tokenId) external view returns (address);
    function createWrapped6909(address token, uint256 tokenId) external returns (address);
}
