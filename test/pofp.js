var POFP = artifacts.require("./POFP.sol");

contract('POFP', function(accounts) {
  it("should contain no loans in the beginning", function() {
    return POFP.deployed().then(function(instance) {
      return instance.lastLoanId.call();
    }).then(function(lastLoanId) {
      assert.equal(lastLoanId.toNumber(), 0, "0 wasn't the lastLoanId");
    });
  });
  // it("should call a function that depends on a linked library", function() {
  //   var meta;
  //   var metaCoinBalance;
  //   var metaCoinEthBalance;

  //   return MetaCoin.deployed().then(function(instance) {
  //     meta = instance;
  //     return meta.getBalance.call(accounts[0]);
  //   }).then(function(outCoinBalance) {
  //     metaCoinBalance = outCoinBalance.toNumber();
  //     return meta.getBalanceInEth.call(accounts[0]);
  //   }).then(function(outCoinBalanceEth) {
  //     metaCoinEthBalance = outCoinBalanceEth.toNumber();
  //   }).then(function() {
  //     assert.equal(metaCoinEthBalance, 2 * metaCoinBalance, "Library function returned unexpeced function, linkage may be broken");
  //   });
  // });
  it("should send create a new loan correctly", function() {
    var pofp;

    // Get initial balances of first and second account.
    var borrower = accounts[0];
    var lender = accounts[1];

    var GNT = '0xa74476443119A942dE498590Fe1f2454d7D4aC0d';
    var DGD = '0xe0b7927c4af23765cb51314a0e0521a9645f0e2a';
    
    var collateralAmount = 10;
    var loanAmount = 10;
    var durationDays = 21;

    return POFP.deployed().then(function(instance) {
      pofp = instance;
      return pofp.newLoan(collateralAmount, GNT, loanAmount, DGD, durationDays, {from: borrower});
    }).then(function() {
      return pofp.lastLoanId.call();
    }).then(function(lastLoanId) {
      assert.equal(lastLoanId.toNumber(), 1, "1 Loan created");
    });
  });
});
