pragma solidity ^0.4.8;

/// @title Assertive contract
/// @author Vii - Lendroid <vii@lendroid.io>
contract Assertive {

  function assert(bool assertion) internal {
      if (!assertion) throw;
  }

}