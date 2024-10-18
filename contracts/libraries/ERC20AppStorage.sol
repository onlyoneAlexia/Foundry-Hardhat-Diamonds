// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.20;

struct  Erc20AppStorage {

mapping(address => uint256) _balances;

mapping(address => mapping(address => uint256)) _allowances;

uint256 _totalsupply;

string _name;

string _symbol;


uint8 _decimal;

//this contains all the state variable i need and i importeed it in my faucet contract to be used by the daimonds


}