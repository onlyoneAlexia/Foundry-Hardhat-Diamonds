// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../libraries/safeERC20.sol";
import "../libraries/LibDiamond.sol";

interface IERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract LendingFacet {
    using SafeERC20 for IERC20;
    
    struct Loan {
        uint256 loanId;
        address borrower;
        address nftContract;
        uint256 tokenId;
        uint256 amount;
        uint256 interest;
        uint256 duration;
        uint256 startTime;
        bool active;
        bool repaid;
    }

    mapping(uint256 => Loan) public loans;
    uint256 public nextLoanId;
    
    event LoanCreated(uint256 indexed loanId, address indexed borrower, uint256 amount);
    event LoanRepaid(uint256 indexed loanId);
    event NFTLiquidated(uint256 indexed loanId);

    function createLoan(
        address _nftContract,
        uint256 _tokenId,
        uint256 _amount,
        uint256 _duration
    ) external {
        require(_amount > 0, "Amount must be greater than 0");
        require(_duration > 0, "Duration must be greater than 0");
        
        IERC721(_nftContract).transferFrom(msg.sender, address(this), _tokenId);
        
        uint256 interest = calculateInterest(_amount, _duration);
        
        loans[nextLoanId] = Loan({
            loanId: nextLoanId,
            borrower: msg.sender,
            nftContract: _nftContract,
            tokenId: _tokenId,
            amount: _amount,
            interest: interest,
            duration: _duration,
            startTime: block.timestamp,
            active: true,
            repaid: false
        });
        
        IERC20(LibDiamond.diamondStorage().lendingToken).safeTransfer(msg.sender, _amount);
        
        emit LoanCreated(nextLoanId, msg.sender, _amount);
        nextLoanId++;
    }

    function repayLoan(uint256 _loanId) external {
        Loan storage loan = loans[_loanId];
        require(loan.active, "Loan is not active");
        require(!loan.repaid, "Loan is already repaid");
        require(msg.sender == loan.borrower, "Not the borrower");
        
        uint256 totalAmount = loan.amount + loan.interest;
        IERC20(LibDiamond.diamondStorage().lendingToken).safeTransferFrom(
            msg.sender,
            address(this),
            totalAmount
        );
        
        IERC721(loan.nftContract).transferFrom(address(this), msg.sender, loan.tokenId);
        
        loan.active = false;
        loan.repaid = true;
        
        emit LoanRepaid(_loanId);
    }

    function liquidateLoan(uint256 _loanId) external {
        Loan storage loan = loans[_loanId];
        require(loan.active, "Loan is not active");
        require(!loan.repaid, "Loan is already repaid");
        require(
            block.timestamp > loan.startTime + loan.duration,
            "Loan duration not expired"
        );
        
        loan.active = false;
        IERC721(loan.nftContract).transferFrom(
            address(this),
            LibDiamond.diamondStorage().treasury,
            loan.tokenId
        );
        
        emit NFTLiquidated(_loanId);
    }

    function calculateInterest(uint256 _amount, uint256 _duration) internal pure returns (uint256) {
        // 10% APR
        return (_amount * _duration * 10) / (365 days * 100);
    }
}