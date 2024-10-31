// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ILending {
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

    event LoanCreated(uint256 indexed loanId, address indexed borrower, uint256 amount);
    event LoanRepaid(uint256 indexed loanId);
    event NFTLiquidated(uint256 indexed loanId);

    function createLoan(
        address _nftContract,
        uint256 _tokenId,
        uint256 _amount,
        uint256 _duration
    ) external;

    function repayLoan(uint256 _loanId) external;
    function liquidateLoan(uint256 _loanId) external;
}