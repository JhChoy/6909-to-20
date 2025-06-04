// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Wrapped6909Factory} from "../src/Wrapped6909Factory.sol";

interface ICreateX {
    function deployCreate2(bytes32 salt, bytes memory initCode) external payable returns (address newContract);
}

contract DeployScript is Script {
    address constant CREATEX_ADDRESS = 0xba5Ed099633D3B313e4D5F7bdc1305d3c28ba5Ed;

    function setUp() public {}

    modifier broadcast() {
        vm.startBroadcast();
        _;
        vm.stopBroadcast();
    }

    function _encodeRedeployableSalt(address msgSender, bytes11 salt) internal pure returns (bytes32 encodedSalt) {
        assembly {
            encodedSalt := or(shl(96, msgSender), shr(168, shl(168, salt)))
        }
    }

    function deploy() public broadcast {
        bytes32 salt = _encodeRedeployableSalt(msg.sender, bytes11(0));
        address deployed = ICreateX(CREATEX_ADDRESS).deployCreate2(salt, type(Wrapped6909Factory).creationCode);
        console.log("Deployed to", deployed);
    }
}
