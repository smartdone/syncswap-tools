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
        // for (uint i = 0; i < length; i++) {
            // address pair = tools.allPairs(i);
            // console.log("Pair %d: %s", i, pair);
            // Ipool pool = Ipool(pair);
            // console.log("\tToken0: %s", pool.token0());
            // console.log("\tToken1: %s", pool.token1());
        // }

        address f1 = tools.getPair(address(0x176211869cA2b568f2A7D4EE941E073a821EE1ff), address(0x894134a25a5faC1c2C26F1d8fBf05111a3CB9487));
        address f2 = tools.getPair(address(0x894134a25a5faC1c2C26F1d8fBf05111a3CB9487), address(0x176211869cA2b568f2A7D4EE941E073a821EE1ff));
        require(f1 == f2 && f1 != address(0), "Pair not found");
        console.log("Pair found: %s", f1);
    }

    function testGetAmountsOut() public view {
        address[] memory path = new address[](2);
        path[0] = address(0x176211869cA2b568f2A7D4EE941E073a821EE1ff);
        path[1] = address(0x894134a25a5faC1c2C26F1d8fBf05111a3CB9487);
        uint[] memory amountOuts = tools.getAmountsOut(1000000000000000000000, path);
        for(uint i = 0; i < amountOuts.length; i++) {
            console.log("AmountOut[%d]: %d", i, amountOuts[i]);
        }
        address f1 = tools.getPair(path[0], path[1]);
        Ipool pool = Ipool(f1);
        uint aout1 = pool.getAmountOut(path[0], 1000000000000000000000, address(this));
        console.log("AmountOut1: %d", aout1);
        uint aout2 = pool.getAmountOut(path[1], 1000000000000000000000, address(this));
        console.log("AmountOut2: %d", aout2);

        address[] memory path2 = new address[](2);
        path2[0] = address(0x894134a25a5faC1c2C26F1d8fBf05111a3CB9487);
        path2[1] = address(0x176211869cA2b568f2A7D4EE941E073a821EE1ff);

        uint[] memory amountOuts2 = tools.getAmountsOut(1000000000000000000000, path2);
        for(uint i = 0; i < amountOuts2.length; i++) {
            console.log("AmountOut[%d]: %d", i, amountOuts2[i]);
        }
    }
    
}

// forge test --match-contract SyncSwapTest --fork-url http://192.168.1.4:17002 -vvv