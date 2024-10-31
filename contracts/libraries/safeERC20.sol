// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// src/libraries/SafeERC20.sol
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}

library SafeERC20 {
    error SafeERC20FailedOperation();

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        bool success = token.transfer(to, value);
        if (!success) revert SafeERC20FailedOperation();
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        bool success = token.transferFrom(from, to, value);
        if (!success) revert SafeERC20FailedOperation();
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        bool success = token.approve(spender, value);
        if (!success) revert SafeERC20FailedOperation();
    }
}