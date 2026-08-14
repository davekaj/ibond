# IBond.sol

`IBond` is an interface for fixed-rate bonds on EVM chains. The bonds are ERC-20 tokens that entitle the holder to principal and coupon payments. It functions just like a bond would in a brokerage account.

This repository contains the standalone [`IBond.sol`](IBond.sol) interface and its [draft EIP specification](EIP.md), so implementers, auditors, and standards reviewers can work with the core standard independently of its demos.

The interface was designed to be easy to read in traditional financial terminology. Issuers can issue units and fund principal; holders can inspect and claim what they are owed.

Advanced functionality is added through extensions. Coupons, calls, puts, conversions, reopenings, and transfer restrictions can be added without changing the interface.

The result is an interface that works for the entire fixed-rate U.S. Treasury market. It also works with corporate bonds.

Issuers can claim coupons for holders with ERC-20-style approval, allowing for automatic coupon payments and redemption, just like a brokerage account.

## Explore IBond on EVM Bonds

[evmbonds.com](https://evmbonds.com/) is the companion site for this interface. It hosts the interactive demos, example deployments, and cost model built around `IBond`.

There you can:

- [Deploy a bond on the Base Sepolia playground](https://evmbonds.com/playground/).
- [Explore deployed examples modeled on well-known crypto corporate bonds](https://evmbonds.com/playground-data/).
- [Browse fake versions of every active U.S. Treasury bill](https://evmbonds.com/bills/), generated to demonstrate the interface across the fixed-rate Treasury market.
- [Estimate the cost of issuing and servicing bonds on an EVM chain](https://evmbonds.com/costs/). The current model estimates that servicing a 10-year Treasury note would cost about $230 on Base for the entire decade.

The U.S. government would not run Treasuries on Base; the point of the model is to show that a multi-trillion-dollar bond system can be run on a blockchain today.
