// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/interfaces/IERC20.sol";


interface IRouter {
    struct SwapStep {
        address pool;
        bytes data;
        address callback;
        bytes callbackData;
        bool useVault;
    }

    struct SwapPath {
        SwapStep[] steps;
        address tokenIn;
        uint amountIn;
    }

    struct SplitPermitParams {
        address token;
        uint approveAmount;
        uint deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct ArrayPermitParams {
        uint approveAmount;
        uint deadline;
        bytes signature;
    }
    function swap(
        SwapPath[] memory paths,
        uint amountOutMin,
        uint deadline
    ) external payable returns (Ipool.TokenAmount memory amountOut);
}

interface IPoolFactory {

    function pools(uint index) external view returns (address);

    function poolsLength() external view returns (uint);
}

interface Ipool {
    struct TokenAmount {
        address token;
        uint amount;
    }
    function token0() external view returns (address);
    function token1() external view returns (address);

    function reserve0() external view returns (uint);
    function reserve1() external view returns (uint);
    function invariantLast() external view returns (uint);

    function getReserves() external view returns (uint, uint);
    function getAmountOut(address tokenIn, uint amountIn, address sender) external view returns (uint amountOut);
    function getAmountIn(address tokenOut, uint amountOut, address sender) external view returns (uint amountIn);
}

contract SyncSwapTools {
    address public owner;
    address constant router = 0xC2a1947d2336b2AF74d5813dC9cA6E0c3b3E8a1E;
    IPoolFactory constant stableFactory = IPoolFactory(0xeE8790cE315c0871ec612f0A6EbB5471A955b3A0);
    constructor() {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    receive() external payable {}
    fallback() external payable {}
    
    function withdraw(address target) public onlyOwner {
        payable(target).transfer(address(this).balance);
    }

    function withdrawToken(address token, address target) public onlyOwner {
        IERC20(token).transfer(target, IERC20(token).balanceOf(address(this)));
    }

    function allPairsLength() public view returns (uint) {
        return stableFactory.poolsLength();
    }

    function allPairs(uint index) public view returns (address) {
        return stableFactory.pools(index);
    }

    function getPair(address tokenA, address tokenB) public view returns (address) {
        for(uint i = 0; i < stableFactory.poolsLength(); i++) {
            address pair = stableFactory.pools(i);
            Ipool pool = Ipool(pair);
            if((pool.token0() == tokenA && pool.token1() == tokenB) || (pool.token0() == tokenB && pool.token1() == tokenA)) {
                return pair;
            }
        }
        revert("Pair not found");
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        Ipool pool = Ipool(getPair(tokenA, tokenB));
        (uint reserve0, uint reserve1) = pool.getReserves();
        address token0 = pool.token0();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    function getAmountsOut(uint amountIn, address[] memory path) public view returns (uint[] memory amounts) {
        require(path.length >= 2, 'INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            Ipool pool = Ipool(getPair(path[i], path[i+1]));
            amounts[i + 1] = pool.getAmountOut(path[i], amounts[i], address(this));
        }
    }

    function getSwapParams(address[] memory path, uint amountIn) public view returns (IRouter.SwapPath memory) {
        IRouter.SwapPath memory swapPath;
        swapPath.tokenIn = path[0];
        swapPath.amountIn = amountIn;
        swapPath.steps = new IRouter.SwapStep[](path.length - 1);
        for (uint i; i < path.length - 1; i++) {
            address pair = getPair(path[i], path[i + 1]);
            Ipool pool = Ipool(pair);
            uint amountOut = pool.getAmountOut(path[i], amountIn, address(this));
            swapPath.steps[i] =  IRouter.SwapStep({
                pool: pair,
                // data是几个参数encode的，第一个参数为tokenIn,第二参数为tokenTo，第三个参数为mode
                // mode为0的话，就不会withdraw，mode为1的话，会withdraw
                data: abi.encode(path[i], address(this), 0),
                callback: address(0),
                callbackData: bytes(''),
                useVault: false
            });
            amountIn = amountOut;
        }
        return swapPath;
    }

    // 先调用getSwapParams生成参数，再调用这个函数去交换，资产放到合约里面
    function swap(
        IRouter.SwapPath[] memory paths,
        uint amountOutMin,
        uint deadline
    ) external payable onlyOwner returns (Ipool.TokenAmount memory amountOut) {
        IERC20 tokenIn = IERC20(paths[0].tokenIn);
        tokenIn.approve(router, paths[0].amountIn);
        amountOut = IRouter(router).swap(paths, amountOutMin, deadline);
    }

}