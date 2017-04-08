pragma solidity ^0.4.8;

import "./Assertive.sol";

/// @title Overflow aware uint math functions.
/// @author Vii - Lendroid <vii@lendroid.io>
contract SafeMath is Assertive {

    function safeMul(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeSub(uint a, uint b) internal returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        assert(c>=a && c>=b);
        return c;
    }

}