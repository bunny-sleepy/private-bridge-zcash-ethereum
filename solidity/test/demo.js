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
        return { example, deployer, verifier };
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
            console.log(valueBytesLE);
            expect(valueBytesLE).to.equal("0x204e000000000000");
        });
    });

    describe("Demo", function () {
        it("Correctly mint and verify token when transfer from ZCash", async function () {
            const { example, deployer } = await loadFixture(deployFixture);
            const transparentAddress = "1AKDDsfTh8uY4X3ppy1m7jw1fVMBSMkzjP";

            // grant an address
            await example.WriteLockAddress(deployer.address, transparentAddress);

            const a = [
                "0x06f5010d30d8a51fc7ab9b0e5dd28a439370b3387cec90fc1dddef86dc20d2ae",
                "0x12e999d9630eab6b1384b2447f9e316092d186a6ff34878a117c9902235c3ace"
            ];
            const b = [
                ["0x240af1e3e92f5fa309972a9ee09292b2c0eb18e8eccff1df9af250e1ed1893e3", "0x0efc04f9bc3d1208ecb9eea139e2697966f1c11d6f0b134d12dbfe0477ef6bea"],
                ["0x04eb8ce190019c5c8e00c2f67c636b07078d9c1e8d5f9f465631322db7576131", "0x2894c90b1e8d849cb8905c57c7148c883efa9f1eebfe9e50e37c40b295020912"]
            ];
            const c = [
                "0x1b27c51b822c09ac06721ad51f698704c2ab42077e7b55224208561318a1e0b7",
                "0x1368d0d43441687f7b5a156ca89a9b5c9555873672a8fd1f56f8a278ef2e6e36"
            ];
            const proof = [a, b, c];
            const input = [
                deployer.address,
                "0",
                "0",
                "20000",
                proof
            ];

            // verify bridge input
            let result = await example.VerifyAndMint(input);
            result = await example.getResult();
            expect(result).to.equal(true);
        });

        it("Correctly burn token when transfer back to ZCash", async function () {
            const { example, deployer } = await loadFixture(deployFixture);
            const transparentAddress = "1AKDDsfTh8uY4X3ppy1m7jw1fVMBSMkzjP";

            // grant an address
            await example.WriteLockAddress(deployer.address, transparentAddress);
            const a = ["0x06f5010d30d8a51fc7ab9b0e5dd28a439370b3387cec90fc1dddef86dc20d2ae", "0x12e999d9630eab6b1384b2447f9e316092d186a6ff34878a117c9902235c3ace"];
            const b = [["0x240af1e3e92f5fa309972a9ee09292b2c0eb18e8eccff1df9af250e1ed1893e3", "0x0efc04f9bc3d1208ecb9eea139e2697966f1c11d6f0b134d12dbfe0477ef6bea"],["0x04eb8ce190019c5c8e00c2f67c636b07078d9c1e8d5f9f465631322db7576131", "0x2894c90b1e8d849cb8905c57c7148c883efa9f1eebfe9e50e37c40b295020912"]];
            const c = ["0x1b27c51b822c09ac06721ad51f698704c2ab42077e7b55224208561318a1e0b7", "0x1368d0d43441687f7b5a156ca89a9b5c9555873672a8fd1f56f8a278ef2e6e36"];
            const valueBytes = "0x204e000000000000";
            const pubKeyHashBytes = "0x662ad25db00e7bb38bc04831ae48b4b446d12698";
            const rootBytes = "0x097bd439c7968f3e3ee0fee6066a5bcf0a69c1b8df26f9a44a155982537b594c";
            const proof = [a, b, c];
            const input = [
                deployer.address,
                "0",
                "0",
                "20000",
                proof
            ];

            // verify bridge input
            const resultVerify = await example.VerifyAndMint(input, { gasLimit: 1000000000 });
            let result = await example.Burn(deployer.address, 0);
            result = await example.getResult();
            expect(result).to.equal(true);
        });
    });

});


// let lockAddress = "00662ad25db00e7bb38bc04831ae48b4b446d1269817d515b6";
// let publicKeyHash = [["0", "1", "1", "0", "0", "1", "1", "0"], ["0", "0", "1", "0", "1", "0", "1", "0"], ["1", "1", "0", "1", "0", "0", "1", "0"], ["0", "1", "0", "1", "1", "1", "0", "1"], ["1", "0", "1", "1", "0", "0", "0", "0"], ["0", "0", "0", "0", "1", "1", "1", "0"], ["0", "1", "1", "1", "1", "0", "1", "1"], ["1", "0", "1", "1", "0", "0", "1", "1"], ["1", "0", "0", "0", "1", "0", "1", "1"], ["1", "1", "0", "0", "0", "0", "0", "0"], ["0", "1", "0", "0", "1", "0", "0", "0"], ["0", "0", "1", "1", "0", "0", "0", "1"], ["1", "0", "1", "0", "1", "1", "1", "0"], ["0", "1", "0", "0", "1", "0", "0", "0"], ["1", "0", "1", "1", "0", "1", "0", "0"], ["1", "0", "1", "1", "0", "1", "0", "0"], ["0", "1", "0", "0", "0", "1", "1", "0"], ["1", "1", "0", "1", "0", "0", "0", "1"], ["0", "0", "1", "0", "0", "1", "1", "0"], ["1", "0", "0", "1", "1", "0", "0", "0"]];
