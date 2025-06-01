// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";

import {Wrapped6909Factory} from "../src/Wrapped6909Factory.sol";

contract Wrapped6909Test is Test {
    Wrapped6909Factory public wrapped6909Factory;

    function setUp() public {
        wrapped6909Factory = new Wrapped6909Factory();
    }
}
