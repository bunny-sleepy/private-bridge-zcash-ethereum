// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { parseUnits, concat } = require("ethers/lib/utils");
const hre = require("hardhat");
const { ethers } = require("hardhat");
const { expect } = require("chai");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");


describe("Example Contract", function () {
    async function deployFixture() {
        // 1. Get deployer
        const [deployer] = await hre.ethers.getSigners();

        // 2. Deploy libraries
        const Base58 = await hre.ethers.getContractFactory("Base58");
        let base58 = await Base58.deploy();
        await base58.deployed();

        // 3. Deploy the mock ZEC
        const MockToken = await hre.ethers.getContractFactory("MockToken");
        let ZEC = await MockToken.deploy("ZEC", "ZEC", 18);
        await ZEC.deployed();

        // 4. Deploy the verifier
        const Verifier = await hre.ethers.getContractFactory("Verifier");
        let verifier = await Verifier.deploy();
        await verifier.deployed();

        // 5. Deploy the zkBridge
        const MockBridge = await hre.ethers.getContractFactory("MockBridge");
        let bridge = await MockBridge.deploy();
        await bridge.deployed();

        // 6. Deploy the main contract
        const Example = await hre.ethers.getContractFactory("Example", {libraries: {Base58: base58.address}});
        let example = await Example.deploy(ZEC.address, verifier.address, bridge.address, [deployer.address]);
        await example.deployed();

        // return
        return { example, deployer };
    }

    describe("Byte Conversions", function () {
        it("Correctly convert ZCash transparent address to public key hash", async function () {
            const { example, deployer } = await loadFixture(deployFixture);
            const pubKeyHash = await example.bitcoin_address_to_pubkeyhash("1AKDDsfTh8uY4X3ppy1m7jw1fVMBSMkzjP");
            expect(pubKeyHash).to.equal("0x662ad25db00e7bb38bc04831ae48b4b446d12698");
        });

        it("Correctly convert uint64 to little-endian bytes", async function () {
            const { example, deployer } = await loadFixture(deployFixture);
            const valueBytesLE = await example.uint64_to_bytes_le(20000);
            expect(valueBytesLE).to.equal("0x204e000000000000");
        });
    });

    describe("Demo", function () {
        it("Correctly mint and verify token when transfer from ZCash", async function () {
            const { example, deployer } = await loadFixture(deployFixture);
        });

        it("Correctly burn token when transfer back to ZCash", async function () {
            const { example, deployer } = await loadFixture(deployFixture);
        });
    });

});


// let lockAddress = "00662ad25db00e7bb38bc04831ae48b4b446d1269817d515b6";
// let publicKeyHash = [["0", "1", "1", "0", "0", "1", "1", "0"], ["0", "0", "1", "0", "1", "0", "1", "0"], ["1", "1", "0", "1", "0", "0", "1", "0"], ["0", "1", "0", "1", "1", "1", "0", "1"], ["1", "0", "1", "1", "0", "0", "0", "0"], ["0", "0", "0", "0", "1", "1", "1", "0"], ["0", "1", "1", "1", "1", "0", "1", "1"], ["1", "0", "1", "1", "0", "0", "1", "1"], ["1", "0", "0", "0", "1", "0", "1", "1"], ["1", "1", "0", "0", "0", "0", "0", "0"], ["0", "1", "0", "0", "1", "0", "0", "0"], ["0", "0", "1", "1", "0", "0", "0", "1"], ["1", "0", "1", "0", "1", "1", "1", "0"], ["0", "1", "0", "0", "1", "0", "0", "0"], ["1", "0", "1", "1", "0", "1", "0", "0"], ["1", "0", "1", "1", "0", "1", "0", "0"], ["0", "1", "0", "0", "0", "1", "1", "0"], ["1", "1", "0", "1", "0", "0", "0", "1"], ["0", "0", "1", "0", "0", "1", "1", "0"], ["1", "0", "0", "1", "1", "0", "0", "0"]];
