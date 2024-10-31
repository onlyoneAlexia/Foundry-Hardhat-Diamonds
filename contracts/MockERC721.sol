pragma solidity ^0.8.19;

import "../contracts/interfaces/IERC721.sol";

contract MockERC721 is IERC721 {
    mapping(address => uint256) public balances;
    mapping(uint256 => address) public owners;

    constructor() {}

    function _mint(address to, uint256 tokenId) internal {
        balances[to] += 1;
        owners[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
    }

    function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }

    function balanceOf(address owner) public view override returns (uint256) {
        return balances[owner];
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        return owners[tokenId];
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        require(from == owners[tokenId], "Not the owner");
        balances[from] -= 1;
        balances[to] += 1;
        owners[tokenId] = to;
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        require(from == owners[tokenId], "Not the owner");
        balances[from] -= 1;
        balances[to] += 1;
        owners[tokenId] = to;
    }

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
}
