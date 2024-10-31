// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../contracts/Diamond.sol";
import "../contracts/facets/LendingFacet.sol";
import "../contracts/facets/DiamondCutFacet.sol";
import "../contracts/facets/DiamondLoupeFacet.sol";

contract LendingTest is Test {
    LendingFacet public lendingFacet;
    MockNFT public mockNFT;
    address public borrower;
    address public lender;
    
    function setUp() public {
        // Deploy contracts
        lendingFacet = new LendingFacet();
        mockNFT = new MockNFT();
        
        // Setup test accounts
        borrower = address(1);
        lender = address(2);
        vm.deal(lender, 100 ether);
        
        // Mint NFT to borrower
        mockNFT.mint(borrower, 1);
    }
    
    function testCreateLoan() public {
        vm.startPrank(borrower);
        mockNFT.approve(address(lendingFacet), 1);
        
        uint256 loanAmount = 1 ether;
        uint256 interest = 1000; // 10%
        uint256 duration = 30 days;
        
        vm.deal(borrower, loanAmount);
        
        lendingFacet.createLoan{value: loanAmount}(
            address(mockNFT),
            1,
            loanAmount,
            interest,
            duration
        );
        
        // Verify loan details
        (
            uint256 storedLoanAmount,
            uint256 storedInterest,
            uint256 startTime,
            uint256 storedDuration,
            address storedLender,
            bool isActive,
            address nftContract
        ) = lendingFacet.getLoanDetails(borrower, 1);
        
        assertEq(storedLoanAmount, loanAmount);
        assertEq(storedInterest, interest);
        assertEq(storedDuration, duration);
        assertTrue(isActive);
        assertEq(nftContract, address(mockNFT));
        
        vm.stopPrank();
    }
    
    function testRepayLoan() public {
        // First create a loan
        testCreateLoan();
        
        vm.startPrank(borrower);
        uint256 repaymentAmount = 1.1 ether; // Principal + 10% interest
        vm.deal(borrower, repaymentAmount);
        
        lendingFacet.repayLoan{value: repaymentAmount}(address(mockNFT), 1);
        
        // Verify loan is closed
        (,,,,, bool isActive,) = lendingFacet.getLoanDetails(borrower, 1);
        assertFalse(isActive);
        
        // Verify NFT is returned
        assertEq(mockNFT.ownerOf(1), borrower);
        
        vm.stopPrank();
    }
    
    function testFailInsufficientRepayment() public {
        testCreateLoan();
        
        vm.startPrank(borrower);
        uint256 repaymentAmount = 0.5 ether; // Less than principal
        vm.deal(borrower, repaymentAmount);
        
        vm.expectRevert("Insufficient repayment amount");
        lendingFacet.repayLoan{value: repaymentAmount}(address(mockNFT), 1);
        
        vm.stopPrank();
    }
}