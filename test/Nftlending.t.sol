// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../contracts/Diamond.sol";
import "../contracts/facets/LendingFacet.sol";
import "../contracts/facets/DiamondCutFacet.sol";
import "../contracts/facets/DiamondLoupeFacet.sol";
//import "../contracts/mockERC20.sol";
//import "../contracts/interfaces/IERC721.sol";
//import "../contracts/interfaces/IERC20.sol";


// Mock NFT Contract
contract MockERC721 is IERC721 {
    constructor() IERC721("MockNFT", "MNFT") {}

    function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }
}

// Mock ERC20 Contract
contract MockERC20 is IERC20 {
    constructor() ERC20("MockToken", "MTK") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract NFTLendingTest is Test {
    Diamond diamond;
    DiamondCutFacet diamondCutFacet;
    DiamondLoupeFacet diamondLoupeFacet;
    LendingFacet lendingFacet;
    MockERC721 mockNFT;
    MockERC20 mockERC20;
    
    address user1;
    address user2;
    address treasury;

    function setUp() public {
        // Deploy mock contracts
        mockNFT = new MockERC721();
        mockERC20 = new MockERC20();
        
        // Create users and treasury
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        treasury = makeAddr("treasury");
        
        // Deploy diamond and facets
        diamondCutFacet = new DiamondCutFacet();
        diamond = new Diamond(address(this), address(diamondCutFacet));
        
        diamondLoupeFacet = new DiamondLoupeFacet();
        lendingFacet = new LendingFacet();

        // Create FacetCut array
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](2);
        
        // Add DiamondLoupeFacet
        bytes4[] memory loupeSelectors = new bytes4[](5);
        loupeSelectors[0] = DiamondLoupeFacet.facets.selector;
        loupeSelectors[1] = DiamondLoupeFacet.facetFunctionSelectors.selector;
        loupeSelectors[2] = DiamondLoupeFacet.facetAddresses.selector;
        loupeSelectors[3] = DiamondLoupeFacet.facetAddress.selector;
        loupeSelectors[4] = DiamondLoupeFacet.supportsInterface.selector;

        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(diamondLoupeFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: loupeSelectors
        });

        // Add LendingFacet
        bytes4[] memory lendingSelectors = new bytes4[](3);
        lendingSelectors[0] = LendingFacet.createLoan.selector;
        lendingSelectors[1] = LendingFacet.repayLoan.selector;
        lendingSelectors[2] = LendingFacet.liquidateLoan.selector;

        cut[1] = IDiamondCut.FacetCut({
            facetAddress: address(lendingFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: lendingSelectors
        });

        // Add facets to diamond
        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");

        // Set up diamond storage
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.treasury = treasury;
        ds.lendingToken = address(mockERC20);
    }

    function testCreateLoan() public {
        // Mint NFT to user1
        vm.startPrank(user1);
        mockNFT.mint(user1, 1);
        mockNFT.approve(address(diamond), 1);
        
        // Create loan
        LendingFacet(address(diamond)).createLoan(
            address(mockNFT),
            1,
            1 ether,
            7 days
        );
        
        // Verify loan created
        (
            uint256 loanId,
            address borrower,
            address nftContract,
            uint256 tokenId,
            uint256 amount,
            ,
            uint256 duration,
            ,
            bool active,
            bool repaid
        ) = LendingFacet(address(diamond)).loans(0);
        
        assertEq(loanId, 0);
        assertEq(borrower, user1);
        assertEq(nftContract, address(mockNFT));
        assertEq(tokenId, 1);
        assertEq(amount, 1 ether);
        assertEq(duration, 7 days);
        assertTrue(active);
        assertFalse(repaid);
        vm.stopPrank();
    }

    function testRepayLoan() public {
        // First create a loan
        testCreateLoan();
        
        // Repay loan
        vm.startPrank(user1);
        mockERC20.mint(user1, 1.1 ether); // Principal + 10% interest
        mockERC20.approve(address(diamond), 1.1 ether);
        
        LendingFacet(address(diamond)).repayLoan(0);
        
        // Verify loan status
        (,,,,,,, bool active, bool repaid) = LendingFacet(address(diamond)).loans(0);
        assertFalse(active);
        assertTrue(repaid);
        
        // Verify NFT returned
        assertEq(mockNFT.ownerOf(1), user1);
        vm.stopPrank();
    }

    function testLiquidateLoan() public {
        // First create a loan
        testCreateLoan();
        
        // Move time forward past duration
        vm.warp(block.timestamp + 8 days);
        
        // Liquidate loan
        LendingFacet(address(diamond)).liquidateLoan(0);
        
        // Verify loan status
        (,,,,,,, bool active,) = LendingFacet(address(diamond)).loans(0);
        assertFalse(active);
        
        // Verify NFT transferred to treasury
        assertEq(mockNFT.ownerOf(1), treasury);
    }
}