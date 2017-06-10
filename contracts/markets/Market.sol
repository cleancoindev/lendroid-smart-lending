pragma solidity ^0.4.8;

import '../dependencies/ERC20.sol';
import './MarketProtocol.sol';

/// @title Base Market
/// @author Vii - Lendroid <vii@lendroid.com>
contract Market is MarketProtocol {

    // FIELDS

    // EVENTS
    event LoanUpdate( uint id );

    event LogLoanCreate(
        bytes32  indexed  id,
        bytes32  indexed  pair,
        address  indexed  creator,
        ERC20             collateralToken,
        ERC20             loanToken,
        uint128           collateralAmount,
        uint128           loanAmount,
        uint64            timestamp
    );

    event LogLoanKill(
        bytes32  indexed  id,
        bytes32  indexed  pair,
        address  indexed  creator,
        ERC20             collateralToken,
        ERC20             loanToken,
        uint128           collateralAmount,
        uint128           loanAmount,
        uint64            timestamp
    );

    // MODIFIERS

    // CONSTANT METHODS

    // NON-CONSTANT METHODS

    function Market() {}

}