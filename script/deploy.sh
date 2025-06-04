#!/bin/bash

source .env

forge script ./script/Deploy.s.sol:DeployScript --sig "deploy()" --rpc-url ${RPC_URL} --private-key ${PRIVATE_KEY} --broadcast
