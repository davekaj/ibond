# IBond

`IBond` is a minimal Solidity interface for fixed-rate, principal-at-maturity
bonds on Ethereum. A bond implementing it is an ERC-20-compatible token: each
bond unit is a transferable claim on face principal, so wallets, indexers, and
DeFi protocols can hold and move bond positions with the ERC-20 tooling they
already have, while the interface adds the views and actions a debt instrument
actually needs — who the issuer is, what asset it pays in, when it was issued
and when it matures, how much principal is outstanding, and how a holder
redeems at maturity.

The interface is deliberately small and explicit. It models a bond's life as a
`Lifecycle` enum (Created, Live, Matured, Redeemable, Settled, Terminated) and
its payment performance as a `PaymentStatus` enum (Performing, Delayed,
Delinquent, Default), and it exposes plain accounting views — `principal()`,
`totalDue()`, `amountOutstanding()`, `holderClaimable(holder)` — instead of
hiding financial state behind metadata. Issuance is model-neutral: the same
interface works for single-shot issues, subscriptions, auctions, and
reopenings (the mechanism U.S. Treasuries use to grow a bill after its first
auction). Anything beyond the core — coupons, subscription windows, callable
or puttable or convertible features, compliance layers — lives in optional
extension interfaces rather than in the core.

This interface intends to become an Ethereum standard. It is being prepared as
an ERC-style EIP draft, informed by the shortcomings of earlier attempts
(ERC-3475's opaque metadata model, ERC-7092's overloaded core) and by
real-world reference material such as the ACTUS financial contract taxonomy
and actual TreasuryDirect auction data. The design goal is that a small,
legible core is what makes a bond standard adoptable: an auditor can read the
whole interface in one sitting, and an integrator needs no off-chain schema to
know what a bond owes and to whom.

The interface has been exercised against working reference implementations —
zero-coupon and coupon bonds, subscription and reopenable variants, and
mirrors of real U.S. Treasury bills seeded from official auction records — so
every function here is one that real implementations and dashboards actually
use.

Because the interface is chain-agnostic, implementations can run on Ethereum
L2s, where issuance, servicing, and redemption can be executed at low cost.
Holders may claim their own payments with `claim(receiver)`, or opt in to
automatic servicing by granting the issuer or a servicing agent an ERC-20
allowance. The servicer can then call `claimFrom(holder, holder)` on each due
date, using allowance in the same way as `transferFrom()` when bond units must
be burned. The payment is always sent to the holder, so this reproduces the
familiar real-world bond experience in which cash is automatically credited to
a brokerage account without giving the servicer custody of the proceeds.

Note: `IBond.sol` imports `IERC20Minimal.sol` (a minimal ERC-20 interface it
extends), so this file needs that sibling interface alongside it to compile.
