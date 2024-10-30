// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "../src/SyncSwapTools.sol";

interface IVault {
    function wETH() external view returns (address);

    function reserves(address token) external view returns (uint reserve);

    function balanceOf(address token, address owner) external view returns (uint balance);

    function deposit(address token, address to) external payable returns (uint amount);

    function depositETH(address to) external payable returns (uint amount);

    function transferAndDeposit(address token, address to, uint amount) external payable returns (uint);

    function transfer(address token, address to, uint amount) external;

    function withdraw(address token, address to, uint amount) external;

    function withdrawAlternative(address token, address to, uint amount, uint8 mode) external;

    function withdrawETH(address to, uint amount) external;
}

contract SyncSwapTest is Test {
    SyncSwapTools tools;
    IERC20 public weth;
    IERC20 public usdt;
    function setUp() public {
        tools = new SyncSwapTools();
        weth = IERC20(0xe5D7C2a44FfDDf6b295A15c148167daaAf5Cf34f);
        usdt = IERC20(0x176211869cA2b568f2A7D4EE941E073a821EE1ff);
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

    function testSwap() public {
        // 不使用native token，这样就不用deposit了，可以预先deposit
        address[] memory path = new address[](2);
        path[0] = address(weth);
        path[1] = address(usdt);
        
        // deposit weth
        uint bal = address(this).balance;
        uint amountIn = 1000000000000000000;
        require(bal >= amountIn, "Insufficient balance");
        bytes memory data = abi.encodeWithSignature("deposit()");
        (bool success,) = address(weth).call{value: amountIn}(data);
        console.log("Deposit: %d", amountIn);
        require(success, "Deposit failed");
        weth.transfer(address(tools), amountIn);

        console.log("tools weth balance: %d", weth.balanceOf(address(tools)));

        uint[] memory outs = tools.getAmountsOut(amountIn, path);
        console.log("AmountsOut: %d", outs[outs.length - 1]);
        IRouter.SwapPath memory swapPath = tools.getSwapParams(path, amountIn, address(tools));
        IRouter.SwapPath[] memory swapPaths = new IRouter.SwapPath[](1);        
        swapPaths[0] = swapPath;

        Ipool.TokenAmount memory xout = tools.swap(swapPaths, outs[outs.length - 1], block.timestamp + 1000);
        
        // weth.approve(address(0xC2a1947d2336b2AF74d5813dC9cA6E0c3b3E8a1E), amountIn);
        // Ipool.TokenAmount memory xout = IRouter(0xC2a1947d2336b2AF74d5813dC9cA6E0c3b3E8a1E).swap(swapPaths, outs[outs.length - 1], block.timestamp + 1000);
        console.log("Amount Out Token: %s", xout.token);
        console.log("Amount Out Value: %d", xout.amount);

        IVault vault = IVault(0x7160570BB153Edd0Ea1775EC2b2Ac9b65F1aB61B);
        uint256 b = vault.balanceOf(address(usdt), address(this));
        console.log("vault Balance of usdt: %d", b);

        console.log("tools usdt balance: %d", usdt.balanceOf(address(tools)));
        console.log("tools weth balance: %d", weth.balanceOf(address(tools)));
        console.log("this usdt balance: %d", usdt.balanceOf(address(this)));
        console.log("this weth balance: %d", weth.balanceOf(address(this)));

        console.log("tool address: %s", address(tools));
        console.log("this address: %s", address(this));

    }

}

// forge test --match-contract SyncSwapTest --fork-url http://192.168.1.4:17002 -vvv