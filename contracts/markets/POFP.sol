pragma solidity ^0.4.2;

import '../dependencies/Owned.sol';
import '../dependencies/ERC20.sol';
import './Market.sol';

/// @title POFP - Proof of Future Payment, a two-party asset-lending market
/// @author Vii - Lendroid <vii@lendroid.com>
contract POFP is Market {
    
    // Fields

    enum State {
        INITIALIZED,
        COLLATERAL_DEPOSITED,
        LOAN_DEPOSITED,
        LOAN_TRANSFERRED,
        IN_PROCESS,
        LOAN_PAID,
        COLLATERAL_WITHDRAWN,
        LOAN_WITHDRAWN,
        EXPIRED
    }

    struct Loan {
        // Fields that would never change throughout the Agreement's longevity
        uint    durationDays;
        uint    startedOn;
        // Fields for Collateral Asset - the token that the borrower would keep as a collateral in exchange for the Loan Token
        ERC20   collateralAsset;
        uint    collateralAmount;
        address collateralOwner;
        // Fields for Loan Asset, aka, the token which the lender would provide in exchange for the Collateral Token 
        ERC20   loanAsset;
        uint    loanAmount;
        // Fields that could change through the Agreement's longevity
        State   state;
        uint    updatedOn;
        bool    closed;
        address owner;
        bool    active;
        uint64  timestamp;
    }

    mapping (uint => Loan) public loans;

    uint public lastLoanId;

    bool locked;

    function nextId() internal returns (uint) {
        lastLoanId++; return lastLoanId;
    }
    
    // CONSTANT METHODS
    function assert(bool x) internal {
        if (!x) throw;
    }

    function isAmountTransferable(uint _amount) constant returns (bool success) {
        success = uint128(_amount) == _amount && _amount > 0;
    }

    function isActive(uint id) constant returns (bool active) {
        return loans[id].active;
    }

    function isExpired(uint id) constant returns (bool) {
        return now <= loans[id].startedOn + (60 * 60 * 24 * loans[id].durationDays);
    }

    function getCollateralOwner(uint id) constant returns (address collateralOwner) {
        return loans[id].collateralOwner;
    }

    function getOwner(uint id) constant returns (address owner) {
        return loans[id].owner;
    }
    
    function getState(uint id) constant returns (State state) {
        return loans[id].state;
    }

    // MODIFIERS

    modifier synchronized {
        assert(!locked);
        locked = true;
        _;
        locked = false;
    }

    modifier open(uint id) {
        assert(isActive(id));
        _;
    }

    modifier onlyOwner(uint id) {
        assert(getOwner(id) == msg.sender);
        _;
    }

    modifier onlyCollateralOwner(uint id) {
        assert(getCollateralOwner(id) == msg.sender);
        _;
    }

    modifier inState(uint id, State _state) {
        assert(getState(id) == _state);
        _;
    }

    modifier notOverDue(uint id) {
        assert(!isExpired(id));
        _;
    }

    modifier loanPeriodExpired(uint id) {
        assert(isExpired(id));
        _;
    }

    modifier canCreate {
        _;
    }

    // NON-CONSTANT METHODS

    // Create a new loan. Takes funds from the caller into market escrow.
    function create(
            uint _cAmount, ERC20 _cAsset, uint _lAmount, ERC20 _lAsset, uint _period
        )
        canCreate
        synchronized
        returns (uint id)
    {
        // Assertion checks on inputs
        assert(uint128(_cAmount) == _cAmount);
        assert(uint128(_lAmount) == _lAmount);
        assert(_cAmount > 0);
        assert(_cAsset != ERC20(0x0));
        assert(_lAmount > 0);
        assert(_lAsset != ERC20(0x0));
        assert(_cAsset != _lAsset);

        Loan memory loan;
        // First check if collatreal owner has enough collateral amount to deposit
        var has_collateral_owner_paid = _cAsset.transferFrom(msg.sender, this, _cAmount);
        assert(has_collateral_owner_paid);
        // Set loan fields
        loan.state = State.COLLATERAL_DEPOSITED;
        loan.durationDays = _period;
        loan.startedOn = now;
        loan.collateralAmount = _cAmount;
        loan.collateralAsset = _cAsset;
        loan.collateralOwner = msg.sender;
        loan.loanAmount = _lAmount;
        loan.loanAsset = _lAsset;
        loan.owner = msg.sender;
        loan.active = true;
        loan.timestamp = uint64(now);
        id = nextId();
        loans[id] = loan;
        // Set the remaining terms to "unpaid" or 0
        loan.updatedOn = now;
        loan.closed = false;
        
        LoanUpdate(id);
        LogLoanCreate(
            bytes32(id),
            sha3(_cAsset, _lAsset),
            msg.sender,
            _cAsset,
            _lAsset,
            uint128(_cAmount),
            uint128(_lAmount),
            uint64(now)
        );
    }

    function newLoan(
        ERC20   collateralAsset,
        ERC20   loanAsset,
        uint128 collateralAmount,
        uint128 loanAmount,
        uint    _duration
    ) returns (bytes32 id) {
        return bytes32(create(collateralAmount, collateralAsset, loanAmount, loanAsset, _duration));
    }

    function transferOwnership(uint id, address _newOwnerAddress)
        open(id)
        onlyOwner(id)
        notOverDue(id)
        inState(id, State.COLLATERAL_DEPOSITED)
        synchronized
        returns (bool) 
    {
        assert(_newOwnerAddress != msg.sender);
        loans[id].state = State.LOAN_DEPOSITED;
        loans[id].owner = _newOwnerAddress;
        // Transfer loan amount from lender
        var valid_loan_deposit = loans[id].loanAsset.transferFrom(_newOwnerAddress, this, loans[id].loanAmount);
        assert(valid_loan_deposit);
        return true;
    }

    function transferLoan(uint id) 
        open (id)
        onlyOwner(id)
        notOverDue(id)
        inState(id, State.LOAN_DEPOSITED)
        synchronized 
        returns (bool) 
    {
        loans[id].state = State.LOAN_TRANSFERRED;
        var valid_transfer = loans[id].loanAsset.transfer(loans[id].collateralOwner, loans[id].loanAmount);
        assert(valid_transfer);
        return true;
    }

    function payLoan(uint id, uint _amount) 
        open(id) 
        onlyCollateralOwner(id)
        notOverDue(id)
        inState(id, State.LOAN_TRANSFERRED)
        synchronized 
        returns (bool) 
    {
        assert(uint128(_amount) == _amount);
        assert(_amount > 0);
        assert(_amount == loans[id].loanAmount);
        loans[id].state = State.LOAN_PAID;
        // The loan asset cannot be deposited in increments. It must be deposited in full.
        var valid_pay = loans[id].loanAsset.transferFrom(msg.sender, this, _amount);
        assert(valid_pay);
        return true;
    }

    function withdrawCollateral(uint id) 
        open(id)
        synchronized 
        returns (bool) 
    {
        if (getState(id) == State.LOAN_PAID) {
            // Validate borrower if loan has been paid in full
            if (getCollateralOwner(id) == msg.sender) {
                loans[id].state = State.COLLATERAL_WITHDRAWN;
                // Transfer collateralAssetFundsHeld to collateralOwner
                var collateral_owner_refunded = loans[id].collateralAsset.transfer(getCollateralOwner(id), loans[id].collateralAmount);
                assert(collateral_owner_refunded);
                return true;
            }
        }
        else {
            // Validate lender if loan has not been paid in full
            if ((isExpired(id)) && (getOwner(id) == msg.sender)) {
                loans[id].state = State.COLLATERAL_WITHDRAWN;
                // Transfer collateralAssetFundsHeld to collateralOwner
                var valid_collateral_withdrawal_lender = loans[id].collateralAsset.transfer(getOwner(id), loans[id].collateralAmount);
                assert(valid_collateral_withdrawal_lender);
                return true;
            }
        }
        return false;
    }

    function withdrawLoan(uint id) 
        synchronized 
        open(id)
        onlyOwner(id)
        loanPeriodExpired(id)
        inState(id, State.COLLATERAL_WITHDRAWN)
        returns (bool) 
    {
        // Called by lender - owed asset owner. In this case, the lender is the contract owner
        loans[id].state = State.LOAN_WITHDRAWN;
        // Transfer loanPaid to owner
        var valid_loan_withdrawal_lender = loans[id].loanAsset.transfer(getOwner(id), loans[id].loanAmount);
        assert(valid_loan_withdrawal_lender);
        return true;
    }

    // Close a loan.
    function closeLoan(uint id)
        open(id)
        onlyOwner(id)
        inState(id, State.LOAN_WITHDRAWN)
        synchronized
        returns (bool success)
    {
        // read-only loan. Modify an loan by directly accessing loans[id]
        Loan memory loan = loans[id];
        delete loans[id];

        LoanUpdate(id);
        LogLoanKill(
            bytes32(id),
            sha3(loan.collateralAsset, loan.loanAsset),
            loan.owner,
            loan.collateralAsset,
            loan.loanAsset,
            uint128(loan.collateralAmount),
            uint128(loan.loanAmount),
            uint64(now)
        );

        success = true;
    }

}