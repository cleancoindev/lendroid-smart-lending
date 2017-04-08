pragma solidity ^0.4.2;

import '../dependencies/Owned.sol';
import '../dependencies/ERC20.sol';
import './Agreement.sol';

/// @title POFP - Proof of Future Payment, a two-party asset-lending agreement
/// @author Vii - Lendroid <vii@lendroid.io>
contract POFP is Agreement, Owned {
    
    // Fields

    // Fields that would never change throughout the Agreement's longevity
    uint public loanPeriodDays;
    uint public startedOn;
    // Fields for Collateral Asset - the token that the borrower would keep as a collateral in exchange for the Loan Token
    ERC20 public collateralToken;
    uint public collateralAmount;
    address public collateralOwner;
    // Fields for Loan Asset, aka, the token which the lender would provide in exchange for the Collateral Token 
    ERC20 public loanToken;
    uint public loanAmount;
    // Fields that could change through the Agreement's longevity
    uint public collateralDeposited;
    uint public loanPaid;
    uint public updatedOn;
    bool public closed;
    bool public isLoanDeposited; // Used to keep state. TODO: Move this logic to a state
    bool public isCollateralDeposited; // Used to keep state. TODO: Move this logic to a state
    bool public isLoanTransferred; // Used to keep state. TODO: Move this logic to a state
    bool public isCollateralWithdrawn; // Used to keep state. TODO: Move this logic to a state
    bool public isFundsWithdrawn; // Used to keep state. TODO: Move this logic to a state

    bool locked;

    // CONSTANT METHODS
    function assert(bool x) internal {
        if (!x) throw;
    }


    // MODIFIERS

    modifier synchronized {
        assert(!locked);
        locked = true;
        _;
        locked = false;
    }

    modifier onlyCollateralOwner {
        if (msg.sender != collateralOwner) throw;
        _;
    }

    modifier notOverDue {
        if (now > startedOn + (60 * 60 * 24 * loanPeriodDays)) throw;
        _;
    }

    modifier loanPeriodExpired {
        if (now <= startedOn + (60 * 60 * 24 * loanPeriodDays)) throw;
        _;
    }

    modifier open {
        if (closed) throw;
        _;
    }

    // NON-CONSTANT METHODS

    function POFP(ERC20 _cToken, uint _cAmount, ERC20 _lToken, uint _lAmount, uint _period) {

        assert(uint128(collateralAmount) == collateralAmount);
        assert(uint128(loanAmount) == loanAmount);
        assert(collateralToken != ERC20(0x0));
        assert(collateralAmount > 0);
        assert(loanToken != ERC20(0x0));
        assert(loanAmount > 0);
        assert(collateralToken != loanToken);

        loanPeriodDays = _period;
        startedOn = now;
        // Set the terms of collateral asset
        collateralToken = _cToken;
        collateralAmount = _cAmount;
        collateralOwner = msg.sender;
        // Set the terms of owed asset
        loanToken = _lToken;
        loanAmount = _lAmount;
        // Set the remaining terms to "unpaid" or 0
        updatedOn = now;
        collateralDeposited = 0;
        loanPaid = 0;
        closed = false;
        isLoanDeposited = false;
        isCollateralDeposited = false;
        isLoanTransferred = false;
        isCollateralWithdrawn = false;
        isFundsWithdrawn = false;
    }

    function transferOwnership(address _newOwnerAddress) synchronized open onlyOwner notOverDue returns (bool) {
        assert(!isLoanDeposited);
        isLoanDeposited = true;
        owner = _newOwnerAddress;
        // Transfer loan amount from lender
        var valid_loan_deposit = loanToken.transferFrom(owner, this, loanAmount);
        assert(valid_loan_deposit);
        return true;
    }

    function depositCollateral(uint _amount) synchronized open onlyCollateralOwner notOverDue returns (bool) {
        assert((!isCollateralDeposited) && (!isLoanTransferred));
        isCollateralDeposited = true;
        isLoanTransferred = true;
        assert((collateralDeposited != 0) && (_amount == collateralAmount));
        collateralDeposited = _amount;
        var valid_deposit = collateralToken.transferFrom(msg.sender, this, _amount);
        assert(valid_deposit);
        var valid_transfer = loanToken.transfer(collateralOwner, loanPaid);
        assert(valid_transfer);
        return true;
    }

    function payLoan(uint _amount) synchronized open onlyCollateralOwner notOverDue returns (bool) {
        // The loan asset cannot be deposited in increments. It must be deposited in full.
        assert((loanPaid == 0) && (_amount == loanAmount));
        loanPaid = _amount;
        var valid_pay = loanToken.transferFrom(msg.sender, this, _amount);
        assert(valid_pay);
        return true;
    }

    function withdrawCollateral() synchronized open returns (bool) {
        // TODO: Include states to tidy up logic
        // Validate borrower if loan has been paid in full
        if ((!isCollateralWithdrawn) && (msg.sender == collateralOwner) && (loanPaid == loanAmount)) {
            // Transfer collateralAssetFundsHeld to collateralOwner
            isCollateralWithdrawn = true;
            var valid_collateral_withdrawal_borrower = collateralToken.transfer(collateralOwner, collateralAmount);
            assert(valid_collateral_withdrawal_borrower);
            return true;
        }
        // Validate lender if loan has not been paid in full
        if ((!isCollateralWithdrawn) && (msg.sender == owner) && (loanPaid != loanAmount)) {
            assert(now <= startedOn + (60 * 60 * 24 * loanPeriodDays));
            // Transfer collateralAssetFundsHeld to collateralOwner
            isCollateralWithdrawn = true;
            var valid_collateral_withdrawal_lender = collateralToken.transfer(owner, collateralAmount);
            assert(valid_collateral_withdrawal_lender);
            return true;
        }
        return false;
    }

    function withdrawFunds() synchronized open onlyOwner loanPeriodExpired returns (bool) {
        // Called by lender - owed asset owner. In this case, the lender is the contract owner
        assert(!isFundsWithdrawn);
        isFundsWithdrawn = true;
        // Transfer loanPaid to owner
        var valid_loan_withdrawal_lender = loanToken.transfer(owner, loanPaid);
        assert(valid_loan_withdrawal_lender);
        return true;
    }

    function closeAgreement() synchronized open onlyOwner loanPeriodExpired returns (bool) {
        closed = true;
        // kill?
        return true;
    }

}