require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      blockGasLimit: 100000000000
    },
    localhost: {
      url: "http://0.0.0.0:8545",
      blockGasLimit: 100000000000
    }
  },
  solidity: "0.6.11",
};
