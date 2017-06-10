# Lendroid Smart Lending

This project is built on top of the barebones truffle-box-react project.

## Installation

1. Install truffle and an ethereum client. For local development, try EthereumJS TestRPC.
    ```javascript
    npm install -g truffle // Version 3.0.5+ required.
    npm install -g ethereumjs-testrpc
    ```

2. Clone or download the truffle box of your choice.
    ```javascript
    git clone [repo]
    ```

3. Install the node dependencies.
    ```javascript
    npm install
    ```

4. Compile and migrate the contracts.
    ```javascript
    truffle compile
    truffle migrate
    ```

5. Run the webpack server for front-end hot reloading. For now, smart contract changes must be manually recompiled and migrated.
    ```javascript
    npm run start
    ```

6. Jest is included for testing React components and Truffle's own suite is incldued for smart contracts. Be sure you've compile your contracts before running jest, or you'll receive some file not found errors.
    ```javascript
    // Runs Jest for component tests.
    npm run test

    // Runs Truffle's test suite for smart contract tests.
    truffle test
    ```

7. To build the application for production, use the build command. A production build will be in the build_webpack folder.
    ```javascript
    npm run build
    ```

## FAQ

* __Why use the Truffle-box-react barebones project?__

    We have been very keen on using React on our Front-end. Seeing that Truffle-box-react met our initial requirements, we decided to build our project on top of it. Furthermore, while developing the UI, it becomes essential to have hot-reloading to accelerate the process. We found truffle-box-react as the least path of resistance to configure our development environment for this purpose.

* __Will this project be inspired by other truffle-react repos?__

    If the situation demands, then yes. After the initial version is stabilized, we are looking to integrate truffle-box-auth or truffle-box-uport into this project.
