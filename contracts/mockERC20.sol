// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;

import "../contracts/interfaces/IERC20.sol";


// Mock ERC20 Contract
// Mock ERC20 Contract
contract MockERC20 is IERC20 {
    mapping(address => uint256) public balances;

    constructor() {}

    function _mint(address to, uint256 amount) internal {
        balances[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function totalSupply() external view returns (uint256) {
        // implement totalSupply logic here
        return 0;
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        // implement transfer logic here
        return true;
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        // implement allowance logic here
        return 0;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        // implement approve logic here
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        // implement transferFrom logic here
        return true;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
}