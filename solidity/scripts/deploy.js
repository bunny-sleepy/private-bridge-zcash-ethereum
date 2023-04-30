// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { parseUnits, concat } = require("ethers/lib/utils");
const hre = require("hardhat");
const { ethers } = require("hardhat");

async function main() {
    // 1. Get deployer
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deployer address: ", deployer.address);

    // 2. Deploy libraries
    const Base58 = await hre.ethers.getContractFactory("Base58");
    let base58 = await Base58.deploy();
    await base58.deployed();

    // 3. Deploy the mock ZEC
    const MockToken = await hre.ethers.getContractFactory("MockToken");
    let ZEC = await MockToken.deploy("ZEC", "ZEC", 18);
    await ZEC.deployed();
    console.log("ZEC Address: ", ZEC.address);

    // 4. Deploy the verifier
    const Verifier = await hre.ethers.getContractFactory("Verifier");
    let verifier = await Verifier.deploy();
    await verifier.deployed();
    console.log("Verifier Address: ", verifier.address);

    // 5. Deploy the zkBridge
    const MockBridge = await hre.ethers.getContractFactory("MockBridge");
    let bridge = await MockBridge.deploy();
    await bridge.deployed();
    console.log("Bridge Address: ", bridge.address);

    // 6. Deploy the main contract
    const Example = await hre.ethers.getContractFactory("Example", {libraries: {Base58: base58.address}});
    let example = await Example.deploy(ZEC.address, verifier.address, bridge.address, [deployer.address]);
    await example.deployed();
    console.log("Example Address: ", example.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });