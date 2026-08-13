// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.24;

import {IERC20Minimal} from "./IERC20Minimal.sol";

/// @title IBond
/// @notice ERC-20-compatible principal-at-maturity bond interface.
/// @dev Issued units are fungible claims on one set of bond terms. The maximum
/// number of units is determined by `principalCap()`, `denomination()`, and the
/// bond token's `decimals()`.
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
        Live,
        /// @notice The bond has reached its maturity date.
        Matured,
        /// @notice Redemption is open and issuer funding covers it, but holder claims remain open.
        Redeemable,
        /// @notice No bond units remain outstanding and settlement is complete.
        Settled,
        /// @notice The bond or offering was terminated before final settlement.
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
    /// @dev This value changes when the amount of issued bond units changes.
    /// @return Principal amount denominated in the bond asset's units.
    function principal() external view returns (uint256);

    /// @notice Returns bond token units currently counted as issued.
    /// @dev Units redeemed through scheduled redemption remain part of this issuance total and are tracked
    /// separately by `redeemedBondUnits()`.
    /// @return Issued bond token units.
    function issuedBondUnits() external view returns (uint256);

    /// @notice Returns cumulative bond token units redeemed and burned through scheduled redemption.
    /// @return Redeemed bond token units.
    function redeemedBondUnits() external view returns (uint256);

    /// @notice Returns the face principal represented by one whole displayed bond token.
    /// @dev One whole token means `10 ** decimals()` bond token units. This is the bond's face denomination,
    /// not its market price or acquisition price.
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

    /// @notice Returns the total bond-asset amount due over the bond's full life.
    /// @return Total due amount denominated in the bond asset's units.
    function totalDue() external view returns (uint256);

    /// @notice Returns the bond-asset payment obligation that remains outstanding.
    /// @return Outstanding amount denominated in the bond asset's units.
    function amountOutstanding() external view returns (uint256);

    /// @notice Returns the bond asset currently claimable by a holder.
    /// @param holder Address whose claimable amount is queried.
    /// @return Claimable bond asset amount.
    function holderClaimable(address holder) external view returns (uint256);

    // -------------------------------------------------------------------------
    // Issuance Actions
    // -------------------------------------------------------------------------

    /// @notice Issues bond units under the implementation's issuance rules.
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

    /// @notice Claims bond asset currently owed to the caller.
    /// @param receiver Address receiving claimed bond asset.
    /// @return claimed Amount of bond asset transferred to `receiver`.
    function claim(address receiver) external returns (uint256 claimed);

    /// @notice Claims bond asset currently owed to a holder.
    /// @dev The caller must satisfy the bond's delegated-claim authorization rules.
    /// @param holder Address whose claim is exercised.
    /// @param receiver Address receiving claimed bond asset.
    /// @return claimed Amount of bond asset transferred to `receiver`.
    function claimFrom(address holder, address receiver) external returns (uint256 claimed);
}
