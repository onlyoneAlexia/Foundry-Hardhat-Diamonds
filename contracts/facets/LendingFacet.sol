// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../libraries/safeERC20.sol";
import "../libraries/LibDiamond.sol";

interface IERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract LendingFacet {
    using LibDiamond for LibDiamond.DiamondStorage;

    event LoanCreated(
        address indexed borrower,
        address indexed lender,
        uint256 tokenId,
        uint256 loanAmount,
        uint256 interest,
        uint256 duration
    );
    
    event LoanRepaid(
        address indexed borrower,
        address indexed lender,
        uint256 tokenId,
        uint256 amountRepaid
    );

    function createLoan(
        address nftContract,
        uint256 tokenId,
        uint256 loanAmount,
        uint256 interest,
        uint256 duration
    ) external payable {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();
        
        require(msg.value == loanAmount, "Incorrect loan amount sent");
        require(duration > 0, "Duration must be greater than 0");
        require(interest <= 10000, "Interest rate too high"); // Max 100%
        
        // Transfer NFT to contract
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
        
        // Create loan
        ds.loans[msg.sender][tokenId] = LibDiamondStorage.LoanDetails({
            loanAmount: loanAmount,
            interest: interest,
            startTime: block.timestamp,
            duration: duration,
            lender: msg.sender,
            isActive: true,
            nftContract: nftContract
        });
        
        ds.totalLoaned[msg.sender] += loanAmount;
        
        emit LoanCreated(
            msg.sender,
            msg.sender,
            tokenId,
            loanAmount,
            interest,
            duration
        );
    }
    
    function repayLoan(address nftContract, uint256 tokenId) external payable {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();
        LibDiamondStorage.LoanDetails storage loan = ds.loans[msg.sender][tokenId];
        
        require(loan.isActive, "Loan not active");
        
        uint256 interest = calculateInterest(loan);
        uint256 totalRepayment = loan.loanAmount + interest;
        require(msg.value >= totalRepayment, "Insufficient repayment amount");
        
        // Process repayment
        loan.isActive = false;
        ds.collectedInterest[loan.lender] += interest;
        
        // Return NFT
        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
        
        // Send payment to lender
        payable(loan.lender).transfer(totalRepayment);
        
        emit LoanRepaid(
            msg.sender,
            loan.lender,
            tokenId,
            totalRepayment
        );
    }
    
    function calculateInterest(LibDiamond.LoanDetails storage loan) internal view returns (uint256) {
        uint256 timeElapsed = block.timestamp - loan.startTime;
        uint256 yearInSeconds = 365 days;
        
        return (loan.loanAmount * loan.interest * timeElapsed) / (10000 * yearInSeconds);
    }

    // View functions
    function getLoanDetails(address borrower, uint256 tokenId) external view returns (
        uint256 loanAmount,
        uint256 interest,
        uint256 startTime,
        uint256 duration,
        address lender,
        bool isActive,
        address nftContract
    ) {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();
        LibDiamondStorage.LoanDetails storage loan = ds.loans[borrower][tokenId];
        
        return (
            loan.loanAmount,
            loan.interest,
            loan.startTime,
            loan.duration,
            loan.lender,
            loan.isActive,
            loan.nftContract
        );
    }
}