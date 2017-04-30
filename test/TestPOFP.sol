pragma solidity ^0.4.2;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/markets/POFP.sol";

contract TestPOFP {

  POFP market;
  uint someValue;

  function beforeAll() {
    market = POFP(DeployedAddresses.POFP());
  }

  function beforeEach() {
    someValue = 5;
  }

  function beforeEachAgain() {
    someValue += 1;
  }

  function testSomeValueIsSix() {
    uint expected = 6;

    Assert.equal(someValue, expected, "someValue should have been 6");
  }

}
