# Setup

1. create a `.env` file like below:

   ```
   INFURA_API_KEY =
   DEPLOYMENT_ACCOUNT_KEY =
   ```

   _\*ask for values to the team and pass them_

2. navigate to your repo directory and install the dependencies:

   ```
   npm install
   ```

# Deploy to a Local Ganache Instance That Mirrors the Mainnet

1. Install the [Ganache CLI](https://github.com/trufflesuite/ganache-cli)

   ```
   npm install -g ganache-cli
   ```

2. _Fork_ and mirror mainnet into your Ganache instance.
   You can fork mainnet and use each protocol's production contracts and production ERC20 tokens.
   Replace `INFURA_API_KEY` with the value in the following and run:

   ```
   ganache-cli --fork https://mainnet.infura.io/v3/INFURA_API_KEY -i 1
   ```

3. In a new terminal window in your repo directory, run:

   ```
   truffle console
   ```

4. Migrate your FlashLoan contract to your instance of Ganache with:

   ```
   migrate --reset
   ```

   \*After a few minutes, your contract will be deployed.

# Deploy to the Mainnet

1. Run:

   ```
   truffle console --network mainnet
   ```

2. You are now connected to the mainnet. Now, use the migrate command to deploy your contract:

   ```
   migrate --reset
   ```

   You might get the error below:

   ```
   /aave-flash-loans/node_modules/@trufflesuite/web3-provider-engine/index.js:219
      number:           ethUtil.toBuffer(jsonBlock.number),
                                                   ^
   TypeError: Cannot read property 'number' of null
   ```

# Interact With the Contract

Call your contract's flashLoan function within the truffle console, replacing `RESERVE_ADDRESS` with the [reserve address](https://docs.aave.com/developers/developing-on-aave/deployed-contract-instances#reserves-assets) found in the Aave documentation:

```
let f = await FlashLoan.deployed()
await f.flashLoan(RESERVE_ADDRESS)
```

If your implementation is correct, then the transaction will succeed. If it fails/reverts, a reason will be given.

\*Make sure that _this contract_ has enough of `_reserve` funds of a token you borrow to payback the `_fee`.

\*if the above operation takes an unreasonably long time or timesout, try `CTRL+C` to exit the Truffle console, run `truffle console` again, then try this step agin. You may need to wait a few blocks before your node can 'see' the deployed contract.

# EOA Address

We are using this EOA address `0xcc84e428b30ea976f932d77293df4ba8edd7307f`.

# Token Addresses

- [DAI](https://etherscan.io/address/0x6b175474e89094c44da98b954eedeac495271d0f)
- [USDC](https://etherscan.io/address/0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48)

# Known issues

## No access to archive state errors

If you are using Ganache to fork a network, then you may have issues with the blockchain archive state every 30 minutes. This is due to your node provider (i.e. Infura) only allowing free users access to 30 minutes of archive state. You can either 1) upgrade to a paid plan or 2) restart your ganache instance and redploy your contracts.

## Unable to debug executeOperation() with mainnet ganache fork

The Truffle debugger does not work too well with proxy / complex calls. You may find that the Truffle debugger returns an error such as:

```
TypeError: Cannot read property 'version' of undefined
at ...
```

- In this case you can try calling your `executeOperation()` function directly, instead of having Aave's `LendingPool` contract invoke the function. This will allow you to debug the function directly, however you will need to supply the relevant parameters (e.g. `_amount`, `_fee`, `_reserve`, etc).
- Alternatively, see the 'Troubleshooting' link.

# Versions

```bash
$ truffle --version
Truffle v5.1.51
$ ganache-cli --version
Ganache CLI v6.12.1 (ganache-core: 2.13.1)
```

# Troubleshooting

See our [Troubleshooting Errors](https://docs.aave.com/developers/tutorials/troubleshooting-errors) documentation.

# Examples

- Here is an [example transaction](https://ropsten.etherscan.io/tx/0x7877238373ffface4fb2b98ca4db1679c64bc2c84c7754432aaab994a9b51e17) that followed the above steps on `Ropsten` using **Dai**.

- Here is an [example transaction](https://ropsten.etherscan.io/tx/0x32eb3e03e00803dc19a7d2edd0a0a670756fbe210be81697be312518baeb16cc) that followed the above steps on `Ropsten` using **ETH**.
