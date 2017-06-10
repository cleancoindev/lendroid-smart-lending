pragma solidity ^0.4.10;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";

import '../contracts/dependencies/ERC20.sol';
import "../contracts/markets/POFP.sol";

// import "ds-test/test.sol";
// import "ds-token/base.sol";

contract TestPOFP is DSTest{

  function testInitialLoanCount() {
    POFP pofp = POFP(DeployedAddresses.POFP());

    uint expected = 0;

    Assert.equal(pofp.lastLoanId(), expected, "lastLoanId should be 0 initially");
  }

  function testFirstLoanCreation() {
    POFP pofp = POFP(DeployedAddresses.POFP());

    uint collateralAmount = 10;
    ERC20 GNT = new ERC20(10 ** 9);
    uint loanAmount = 20;
    ERC20 DGD = new ERC20(10 ** 6);
    uint durationDays = 21;

    Assert.equal(pofp.newLoan(collateralAmount, GNT, loanAmount, DGD, durationDays), 1, "First loan created.");
  }

}
