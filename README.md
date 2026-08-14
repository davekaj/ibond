# IBond.sol

`IBond` is an interface for fixed-rate bonds on EVM chains. The bonds are ERC-20 tokens that entitle the holder to principal and coupon payments. It functions just like a bond would in a brokerage account.

The interface was designed to be easy to read in traditional financial terminology. Issuers can issue units and fund principal; holders can inspect and claim what they are owed.

Advanced functionality is added through extensions. Coupons, calls, puts, conversions, reopenings, and transfer restrictions can be added without changing the interface.

The result is an interface that works for the entire fixed-rate U.S. Treasury market. To demonstrate this, the [Mirrored U.S. Treasuries](https://evmbonds.com/bills/) page contains fake versions of every active U.S. Treasury bill. It also works with corporate bonds; we have deployed examples mirroring a few [well-known crypto corporate bonds](https://evmbonds.com/playground-data/).

Issuers can claim coupons for holders with ERC-20-style approval, allowing for automatic coupon payments and redemption, just like a brokerage account.

Our [current model](https://evmbonds.com/costs/) estimates that servicing a 10-year Treasury note would cost about $230 on Base for the entire decade. Obviously the US Government would not run their treasuries on Base. But the point is - a multi-trillion dollar bond system can be run on a blockchain today.

**IBond is the first legitimate interface for bringing traditional bonds to Ethereum. You can participate in the conversation on Ethereum Magicians. Link TODO. You can launch a bond on Base Sepolia using the button below.**

[Deploy a Bond on the Playground](https://evmbonds.com/playground/)
