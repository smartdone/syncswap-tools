// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "../src/SyncSwapTools.sol";

contract SyncSwapTest is Test {
    SyncSwapTools tools;
    function setUp() public {
        tools = new SyncSwapTools();
    }

    function testPairs() public view {
        uint length = tools.allPairsLength();
        assertTrue(length > 0, "No pairs found");
        for (uint i = 0; i < length; i++) {
            address pair = tools.allPairs(i);
            console.log("Pair %d: %s", i, pair);
            Ipool pool = Ipool(pair);
            console.log("\tToken0: %s", pool.token0());
            console.log("\tToken1: %s", pool.token1());
        }

        address f1 = tools.getPair(address(0x176211869cA2b568f2A7D4EE941E073a821EE1ff), address(0x894134a25a5faC1c2C26F1d8fBf05111a3CB9487));
        address f2 = tools.getPair(address(0x894134a25a5faC1c2C26F1d8fBf05111a3CB9487), address(0x176211869cA2b568f2A7D4EE941E073a821EE1ff));
        require(f1 == f2 && f1 != address(0), "Pair not found");
        console.log("Pair found: %s", f1);
    }
}

// forge test --match-contract SyncSwapTest --fork-url http://192.168.1.4:17002 -vvv