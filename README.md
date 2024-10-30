## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```

### SyncSwap工具

这个工具仅用于linea链，如果要在其他链上用，请修改factory和router的值
1. 将router修改为SyncSwap Router V2的地址
2. 将stableFactory修改为SyncSwap Pool Master的地址

SyncSwap在uniswap v2上面做了魔改，为了能够*不去修改已有代码🌚*实现了这个wrapper，仅仅包括自用的一些函数

1. factory的allPairsLength和allPairs函数
2. getPair通过两个token去获取地址
3. getAmountsOut，通过amountIn以及paths去获取amountOut，用来询价