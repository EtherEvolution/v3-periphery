# EtherEvolution V3 Periphery

[![Tests](https://github.com/EtherEvolution/etherevolution-v3-periphery/workflows/Tests/badge.svg)](https://github.com/EtherEvolution/etherevolution-v3-periphery/actions?query=workflow%3ATests)
[![Lint](https://github.com/EtherEvolution/etherevolution-v3-periphery/workflows/Lint/badge.svg)](https://github.com/EtherEvolution/etherevolution-v3-periphery/actions?query=workflow%3ALint)

This repository contains the periphery smart contracts for the EtherEvolution V3 Protocol.
For the lower level core contracts, see the [etherevolution-v3-core](https://github.com/EtherEvolution/etherevolution-v3-core)
repository.

## Bug bounty

This repository is subject to the EtherEvolution V3 bug bounty program,
per the terms defined [here](./bug-bounty.md).

## Local deployment

In order to deploy this code to a local testnet, you should install the npm package
`@etherevolution/v3-periphery`
and import bytecode imported from artifacts located at
`@etherevolution/v3-periphery/artifacts/contracts/*/*.json`.
For example:

```typescript
import {
  abi as SWAP_ROUTER_ABI,
  bytecode as SWAP_ROUTER_BYTECODE,
} from '@etherevolution/v3-periphery/artifacts/contracts/SwapRouter.sol/SwapRouter.json'

// deploy the bytecode
```

This will ensure that you are testing against the same bytecode that is deployed to
mainnet and public testnets, and all Uniswap code will correctly interoperate with
your local deployment.

## Using solidity interfaces

The EtherEvolution v3 periphery interfaces are available for import into solidity smart contracts
via the npm artifact `@etherevolution/v3-periphery`, e.g.:

```solidity
import '@etherevolution/v3-periphery/contracts/interfaces/ISwapRouter.sol';

contract MyContract {
  ISwapRouter router;

  function doSomethingWithSwapRouter() {
    // router.exactInput(...);
  }
}

```
