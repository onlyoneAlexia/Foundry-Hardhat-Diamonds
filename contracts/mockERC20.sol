pragma solidity ^0.8.28;

import "../contracts/interfaces/IERC721.sol";

contract MockERC721 is IERC721 {
    mapping(address => uint256) public balances;
    mapping(uint256 => address) public owners;

    function mint(address to, uint256 tokenId) public {
        balances[to] += 1;
        owners[tokenId] = to;
    }

    function balanceOf(address owner) public view override returns (uint256) {
        return balances[owner];
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        return owners[tokenId];
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        require(from == owners[tokenId], "Not the owner");
        balances[from] -= 1;
        balances[to] += 1;
        owners[tokenId] = to;
    }
}