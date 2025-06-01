// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Wrapped6909Factory} from "../src/Wrapped6909Factory.sol";

contract DeployScript is Script {
    Wrapped6909Factory public wrapped6909Factory;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        wrapped6909Factory = new Wrapped6909Factory();

        vm.stopBroadcast();
    }
}
