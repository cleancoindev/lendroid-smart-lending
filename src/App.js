import React, { Component } from 'react'
import POFPContract from '../build/contracts/POFP.json'
import Web3 from 'web3'

import './css/oswald.css'
import './css/open-sans.css'
import './css/pure-min.css'
import './App.css'

class App extends Component {
  constructor(props) {
    super(props)

    this.state = {
      pofp: null,
      pofpInstance: null,
      account: null,
      totalLoans: 0,
      loans: null,
      ERC20Tokens: {
        'GNT': '0xa74476443119A942dE498590Fe1f2454d7D4aC0d',
        'DGD': '0xe0b7927c4af23765cb51314a0e0521a9645f0e2a'
      }
    }
  }

  _refreshLoans = () => {
    var self = this
    self.state.pofpInstance.lastLoanId
      // .call(self.state.account, {from: self.state.account})
      .call()
      .then(function(resultBigNumber) {
        return resultBigNumber.toNumber()
      })
      .then(function(lastLoanId) {
        self.setState({
          totalLoans: lastLoanId
        })
      })
  }

  _displayMarket = () => {
    this._refreshLoans()
  }

  _setupMarket = (provider) => {
    var self = this
    const contract = require('truffle-contract')
    const POFP = contract(POFPContract)
    POFP.setProvider(provider)
    self.setState({
      pofp: POFP
    })
    self.state.pofp
      .deployed()
      .then(function(instance) {
        self.setState({
          pofpInstance: instance
        })
        self._displayMarket()
      })
  }

  componentWillMount() {
    var self = this

    // Setup the RPC provider.
    const provider = new Web3.providers.HttpProvider('http://localhost:8545')
    // Get Web3 so we can get our accounts.
    const web3RPC = new Web3(provider)

    // Get accounts.
    web3RPC.eth.getAccounts(function(error, accounts) {
      console.log('Accounts:')
      console.log(accounts)
      
      self.setState({
        account: accounts[0]
      })
      self._setupMarket(provider)
    })
  }

  _createLoan = () => {
    var self = this
    console.log(self.state);
    self.state.pofp
      .deployed()
      .then(function(instance) {
        self.setState({
          pofpInstance: instance
        })
        return instance
      })
      .then(function(result) {
        return self.state.pofpInstance
          .newLoan(
            10, 
            self.state.ERC20Tokens.GNT,
            5,
            self.state.ERC20Tokens.DGD,
            21,
            {from: self.state.account}
          )
      })
      .then(function(result) {
        console.log(result)
        self._refreshLoans()
      })
  }

  render() {
    return (
      <div className="App">
        <nav className="navbar pure-menu pure-menu-horizontal">
            <a href="#" className="pure-menu-heading pure-menu-link">Lendroid</a>
            {/*}<ul className="pure-menu-list">
                <li className="pure-menu-item"><a href="#" className="pure-menu-link">News</a></li>
                <li className="pure-menu-item"><a href="#" className="pure-menu-link">Sports</a></li>
                <li className="pure-menu-item"><a href="#" className="pure-menu-link">Finance</a></li>
            </ul>*/}
        </nav>

        <main className="container">
          <div className="pure-g">
            <div className="pure-u-1-1">
              <h1>Welcome!</h1>
              <p>Your account address is: {this.state.account}</p>
              <p>Our UI will be built in the coming days and we're excited to show you what we've got.</p>
              <p>Loans created so far: {this.state.totalLoans}</p>
              <input type="button" value="Create a new Loan" onClick={this._createLoan} />
            </div>
          </div>
        </main>
      </div>
    );
  }
}

export default App
