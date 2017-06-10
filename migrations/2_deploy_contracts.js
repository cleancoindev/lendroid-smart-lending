var SimpleStorage = artifacts.require("./SimpleStorage.sol");
var ConvertLib = artifacts.require("./ConvertLib.sol");
var POFP = artifacts.require("./POFP.sol");

module.exports = function(deployer) {
  deployer.deploy(SimpleStorage);
  deployer.deploy(ConvertLib);
  deployer.link(ConvertLib, POFP);
  deployer.deploy(POFP);
};
