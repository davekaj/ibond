// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.24;

/// @title IERC20Minimal
/// @notice Minimal ERC-20 surface used by the bond examples.
interface IERC20Minimal {
    /// @notice Emitted when `value` tokens move from `from` to `to`.
    /// @param from Address whose balance decreased, or the zero address for minting.
    /// @param to Address whose balance increased, or the zero address for burning.
    /// @param value Amount of tokens transferred.
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @notice Emitted when `owner` sets `spender`'s allowance to `value`.
    /// @param owner Address that owns the approved tokens.
    /// @param spender Address allowed to spend tokens from `owner`.
    /// @param value New allowance amount.
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice Returns the token name.
    /// @return Token name.
    function name() external view returns (string memory);

    /// @notice Returns the token symbol.
    /// @return Token symbol.
    function symbol() external view returns (string memory);

    /// @notice Returns the number of display decimals used by the token.
    /// @return Token decimals.
    function decimals() external view returns (uint8);

    /// @notice Returns the total token supply.
    /// @return Total issued token amount.
    function totalSupply() external view returns (uint256);

    /// @notice Returns the token balance of an account.
    /// @param account Address whose balance is queried.
    /// @return Account token balance.
    function balanceOf(address account) external view returns (uint256);

    /// @notice Returns the remaining amount `spender` can spend from `owner`.
    /// @param owner Address that owns the approved tokens.
    /// @param spender Address allowed to spend tokens from `owner`.
    /// @return Remaining allowance amount.
    function allowance(address owner, address spender) external view returns (uint256);

    /// @notice Sets `spender`'s allowance over the caller's tokens.
    /// @param spender Address allowed to spend tokens from the caller.
    /// @param value New allowance amount.
    /// @return True if the approval succeeded.
    function approve(address spender, uint256 value) external returns (bool);

    /// @notice Transfers tokens from the caller to `to`.
    /// @param to Address receiving the tokens.
    /// @param value Amount of tokens to transfer.
    /// @return True if the transfer succeeded.
    function transfer(address to, uint256 value) external returns (bool);

    /// @notice Transfers tokens from `from` to `to` using the caller's allowance.
    /// @param from Address whose tokens are transferred.
    /// @param to Address receiving the tokens.
    /// @param value Amount of tokens to transfer.
    /// @return True if the transfer succeeded.
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}
