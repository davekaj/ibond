// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20Minimal} from "./IERC20Minimal.sol";

/// @title IBond
/// @notice ERC-20-compatible principal-at-maturity bond interface.
/// @dev `IBond` is issuance-model neutral. Implementations may use single
/// issuance, subscriptions, auctions, reopenings, private placements, or
/// external settlement adapters as long as issued units represent the same
/// bond series terms. The interface does not require a standalone bond-unit
/// cap view; implementations can derive their maximum units deterministically
/// from `principalCap`, `denomination`, and the bond token's `decimals`.
interface IBond is IERC20Minimal {
    // -------------------------------------------------------------------------
    // Types
    // -------------------------------------------------------------------------

    /// @notice Bond lifecycle states.
    enum Lifecycle {
        /// @notice Terms exist and the bond has not started regular servicing.
        /// @dev This is the pre-issue-date state. A bond that never issues any bond units also remains `Created`
        /// after `issueDate` and maturity because it never becomes outstanding.
        Created,
        /// @notice The bond is outstanding and servicing before maturity.
        /// @dev Reopenable variants may still allow additional issuance while live.
        Live,
        /// @notice The bond has reached its maturity date.
        Matured,
        /// @notice Redemption is open and issuer funding covers it, but holder claims remain open.
        Redeemable,
        /// @notice All issued bond units have been redeemed, retired, or settled through an early-exit extension.
        Settled,
        /// @notice The bond or offering was terminated before final settlement.
        /// @dev Examples include issuer abort, minimum raise not met, regulatory stop, or extension-defined termination.
        Terminated
    }

    /// @notice Bond payment-performance states.
    enum PaymentStatus {
        /// @notice No due payment is currently late under the bond's payment-status rules.
        Performing,
        /// @notice A due payment is late but still inside the grace period.
        /// @dev A payment counts as late from its exact due timestamp: an unpaid payment reads
        /// `Delayed` when `block.timestamp` equals the due date, not one second after.
        Delayed,
        /// @notice A due payment remains unpaid after grace but before default.
        Delinquent,
        /// @notice The bond has defaulted under its payment-status rules.
        Default
    }

    // -------------------------------------------------------------------------
    // Events
    // -------------------------------------------------------------------------

    /// @notice Emitted when a bond is created.
    /// @param issuer Address that owes bond cashflows.
    /// @param asset ERC-20 token used for bond payments.
    /// @param principalCap Maximum face principal the bond can issue and owe at maturity.
    /// @param issueDate Timestamp when the bond first becomes outstanding or starts regular servicing.
    /// @param maturityDate Timestamp when the bond matures.
    event BondCreated(
        address indexed issuer, address indexed asset, uint256 principalCap, uint64 issueDate, uint64 maturityDate
    );

    /// @notice Emitted when bond units are issued.
    /// @param issuer Address that issued the bond units.
    /// @param receiver Address receiving bond units.
    /// @param principalAmount Face principal represented by the issued bond units.
    /// @param bondUnits Amount of bond token units issued.
    event BondUnitsIssued(address indexed issuer, address indexed receiver, uint256 principalAmount, uint256 bondUnits);

    /// @notice Emitted when maturity principal cash is funded for redemption.
    /// @param payer Address that funded principal.
    /// @param amount Amount of bond asset accepted for principal redemption.
    event MaturityPrincipalFunded(address indexed payer, uint256 amount);

    /// @notice Emitted when a payment funding executes, recording the payment status immediately before it.
    /// @dev `status()` is derived from current state and time, so it leaves no onchain history: a cured bond
    /// reads `Performing` with no trace it was ever late. This event preserves the pre-funding status in logs
    /// so indexers can reconstruct how late each payment was. A bond whose payments are never funded emits
    /// nothing and remains observable through `status()`.
    /// @param status Payment-performance status immediately before this funding executed.
    /// @param dueDate Due date of the payment being funded.
    event PaymentStatusAtFunding(PaymentStatus indexed status, uint64 indexed dueDate);

    /// @notice Emitted when bond units are redeemed and burned at maturity.
    /// @param holder Address whose bond units are redeemed.
    /// @param receiver Address receiving redemption proceeds.
    /// @param bondUnits Amount of bond token units redeemed.
    /// @param principalAmount Amount of principal paid for the redeemed bond units.
    event BondUnitsRedeemed(
        address indexed holder, address indexed receiver, uint256 bondUnits, uint256 principalAmount
    );

    // -------------------------------------------------------------------------
    // Core Terms
    // -------------------------------------------------------------------------

    /// @notice Returns the issuer that owes bond payments.
    /// @return Issuer address.
    function issuer() external view returns (address);

    /// @notice Returns the ERC-20 token used for bond payments.
    /// @return ERC-20 payment asset address.
    function asset() external view returns (address);

    /// @notice Returns the maximum face principal the bond can issue and owe at maturity.
    /// @return Principal cap denominated in the bond asset's units.
    function principalCap() external view returns (uint256);

    /// @notice Returns the timestamp when the bond first becomes outstanding or starts regular servicing.
    /// @dev This is not necessarily the final issuance date for reopenable or tap-issued bonds.
    /// @return Initial issue or servicing-start timestamp.
    function issueDate() external view returns (uint64);

    /// @notice Returns the timestamp when the bond matures.
    /// @return Maturity timestamp.
    function maturityDate() external view returns (uint64);

    // -------------------------------------------------------------------------
    // Lifecycle And Supply Views
    // -------------------------------------------------------------------------

    /// @notice Returns the current lifecycle state.
    /// @return Current bond lifecycle.
    function lifecycle() external view returns (Lifecycle);

    /// @notice Returns the current payment-performance status.
    /// @return Current bond payment status.
    function status() external view returns (PaymentStatus);

    /// @notice Returns the currently issued face principal owed by the issuer.
    /// @dev Single-issuance implementations may become fixed after `issueDate`; reopenable implementations may increase
    /// this value when additional fungible units of the same bond series are issued, while retirement and put
    /// extensions may decrease it when units are permanently cancelled or settled outside scheduled redemption.
    /// @return Principal amount denominated in the bond asset's units.
    function principal() external view returns (uint256);

    /// @notice Returns bond token units still issued after permanent early exits.
    /// @dev Cumulative for single-issuance bonds; retirement, conversion, and put extensions may reduce it when
    /// units are permanently cancelled, exchanged into equity, or settled through a separate put pool. Those
    /// exits are not counted as scheduled-redemption units.
    /// @return Issued bond token units.
    function issuedBondUnits() external view returns (uint256);

    /// @notice Returns cumulative bond token units redeemed and burned through scheduled redemption.
    /// @dev Extensions that burn units through retirement or holder puts exclude them and expose separate totals.
    /// @return Redeemed bond token units.
    function redeemedBondUnits() external view returns (uint256);

    /// @notice Returns the face principal represented by one whole displayed bond token.
    /// @dev One whole token means `10 ** decimals()` bond token units. This is the bond's face denomination,
    /// not a market price or subscription price.
    /// @return Face principal denomination in bond asset units.
    function denomination() external view returns (uint256);

    /// @notice Returns the principal amount represented by a holder's bond token balance.
    /// @param holder Address whose principal claim is queried.
    /// @return Principal amount represented by `holder`.
    function principalOf(address holder) external view returns (uint256);

    /// @notice Converts bond token units to represented principal.
    /// @param bondUnits Amount of bond token units.
    /// @return Principal amount represented by `bondUnits`.
    function bondUnitsToPrincipal(uint256 bondUnits) external view returns (uint256);

    /// @notice Converts principal amount to bond token units.
    /// @param principalAmount Principal amount denominated in the bond asset.
    /// @return Bond token units representing `principalAmount`.
    function principalToBondUnits(uint256 principalAmount) external view returns (uint256);

    // -------------------------------------------------------------------------
    // Payment Accounting Views
    // -------------------------------------------------------------------------

    /// @notice Returns whether maturity principal has been fully funded for redemption.
    /// @return True when the full maturity principal reserve has been funded.
    function maturityPrincipalFunded() external view returns (bool);

    /// @notice Returns the amount of bond asset already claimed by holders from the bond.
    /// @return Cumulative holder-claimed amount.
    function amountHoldersClaimed() external view returns (uint256);

    /// @notice Returns total principal due over the full life of the base bond.
    /// @dev Coupon extensions may override this to include scheduled coupon cashflows.
    /// @return Total due amount denominated in the bond asset's units.
    function totalDue() external view returns (uint256);

    /// @notice Returns the amount currently outstanding under the bond's accounting model.
    /// @dev For the base bond this is unfunded maturity principal. Coupon extensions may include accrued coupon amounts.
    /// @return Outstanding amount denominated in the bond asset's units.
    function amountOutstanding() external view returns (uint256);

    /// @notice Returns the bond asset currently claimable by a holder.
    /// @dev For the base bond this is maturity principal claimable by burning the holder's bond units.
    /// Coupon extensions may include coupon cash.
    /// @param holder Address whose claimable amount is queried.
    /// @return Claimable bond asset amount.
    function holderClaimable(address holder) external view returns (uint256);

    // -------------------------------------------------------------------------
    // Issuance Actions
    // -------------------------------------------------------------------------

    /// @notice Issues bond units under the implementation's issuance rules.
    /// @dev Single-issuance implementations may only allow this before `issueDate`; reopenable implementations may allow
    /// additional issuance after `issueDate`. Pricing, auctions, underwriting, DvP, and offchain allocation are outside
    /// the core interface unless provided by an extension.
    /// @param bondUnits Amount of bond token units to issue.
    /// @param receiver Address receiving bond units.
    /// @return principalIssued Face principal represented by `bondUnits`.
    function issue(uint256 bondUnits, address receiver) external returns (uint256 principalIssued);

    // -------------------------------------------------------------------------
    // Issuer Servicing Actions
    // -------------------------------------------------------------------------

    /// @notice Funds the exact remaining maturity principal cash for redemption.
    /// @return funded Amount funded for maturity principal redemption.
    function fundMaturityPrincipal() external returns (uint256 funded);

    // -------------------------------------------------------------------------
    // Holder Claim And Redemption Actions
    // -------------------------------------------------------------------------

    /// @notice Claims cash owed to the caller, routing to refund, extension claim, or maturity redemption.
    /// @param receiver Address receiving claimed bond asset.
    /// @return claimed Amount of bond asset transferred to `receiver`.
    function claim(address receiver) external returns (uint256 claimed);

    /// @notice Claims cash owed to a holder, routing to refund, extension claim, or maturity redemption.
    /// @dev When caller is not `holder`, ERC-20 allowance is required, token-burning claims spend allowance,
    /// and the claim must pay `holder`. This permits an issuer or servicing agent to automate holder payouts
    /// with `transferFrom`-style authorization, mirroring automatic payments into a brokerage account.
    /// @param holder Address whose claim is exercised.
    /// @param receiver Address receiving claimed bond asset.
    /// @return claimed Amount of bond asset transferred to `receiver`.
    function claimFrom(address holder, address receiver) external returns (uint256 claimed);
}
