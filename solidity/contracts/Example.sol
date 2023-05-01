// SPDX-License-Identifier: MIT
// pragma solidity >= 0.8.0;
pragma solidity ^0.6.11;
pragma experimental ABIEncoderV2;

import {IVerifier} from "./Interface/IVerifier.sol"; 
import {IzkBridge} from "./Interface/IzkBridge.sol";
import {IMockToken} from "./Interface/IMockToken.sol";
import {Base58} from "./Dependency/storyicon/Base58.sol";

contract Example {
    IMockToken _token;
    IVerifier _verifier;
    IzkBridge _zkBridge;
    bool _result;

    mapping(address => bool) internal _writePermission;
    mapping(address => mapping(uint256 => string)) internal _lockAddress;
    mapping(address => mapping(uint256 => uint64)) internal _lockValue;
    mapping(address => mapping(uint256 => bool)) internal _isValidLockAddress;
    mapping(address => uint256) internal _maxIndexLockAddress;

    constructor(
        IMockToken token,
        IVerifier verifier,
        IzkBridge zkBridge,
        address[] memory relayers
    ) public {
        _token = token;
        _verifier = verifier;
        _zkBridge = zkBridge;
        _result = false;
        for (uint i = 0; i < relayers.length; i++) {
            _writePermission[relayers[i]] = true;
        }
    }

    // lockAddress, user_address, index
    // whether or not the lockAddress is used
    function WriteLockAddress(address user, string calldata addr) external {
        require(_writePermission[msg.sender] == true);
        uint256 currentIndex = _maxIndexLockAddress[user];
        _isValidLockAddress[user][currentIndex] = true;
        _lockAddress[user][currentIndex] = addr;
        _maxIndexLockAddress[user] = currentIndex + 1;
    }

    function writePermission(address addr) external view returns (bool) {
        return _writePermission[addr];
    }

    function lockAddress(address user, uint256 index) external view returns (string memory) {
        return _lockAddress[user][index];
    }

    function getResult() external view returns (bool) {
        return _result;
    }

    function bytes_to_uint64_le(bytes memory b) public pure returns (uint64) {
        require(b.length == 8, "Bytes array length must be 8");

        uint64 result;
        for (uint i = 0; i < 8; i++) {
            result += (uint64(uint8(b[i])) << uint64(i * 8));
        }
        return result;
    }

    function uint64_to_bytes_le(uint64 x) public pure returns (bytes memory) {
        bytes memory result = new bytes(8);
        for (uint i = 0; i < 8; i++) {
            result[i] = bytes1(uint8((x >> (i * 8)) % (1 << 8)));
        }
        return result;
    }

    // function bit_array_to_bytes(uint256[8][] memory bits) public pure returns (bytes memory) {
    //     uint256 n = bits.length;
    //     bytes memory bytesArr = new bytes(n);
    //     for (uint256 index = 0; index < n; index++) {
    //         for (uint8 j = 0; j < 8; j++) {
    //             if (bits[index][j] == 1) {
    //                 bytesArr[index] |= bytes1(uint8(1) << j);
    //             }
    //         }
    //     }
    //     return bytesArr;
    // }

    function bitcoin_address_to_pubkeyhash(
        string memory _addr
    ) public pure returns (bytes memory pubKeyHash) {
        bytes memory addr = Base58.decodeFromString(_addr);
        require(addr.length == 25);
        // we allow only P2PKH address
        require(addr[0] == 0x00);
        pubKeyHash = new bytes(20);
        for (uint i = 0; i < 20; i++) {
            pubKeyHash[i] = addr[i+1];
        }
    }

    struct Proof {
        uint[2] a;
        uint[2][2] b;
        uint[2] c;
    }

    struct VerifyAndMintInput {
        address onBehalfOf;
        uint256 index;
        uint256 blockNumber;
        uint64 value;
        // proof
        Proof proof;
        // other public inputs are aquired from storage
    }

    function VerifyAndMint(
        VerifyAndMintInput memory input
    ) external returns (bool) {
        require(input.value > 0);
        // 0. get blockheader and pubKeyHash of lockAddress
        address user = msg.sender;
        require(_isValidLockAddress[user][input.index] == true);
        require(_lockValue[user][input.index] == uint64(0));
        uint64 value = input.value;
        bytes memory pubKeyHashBytes;
        pubKeyHashBytes = bitcoin_address_to_pubkeyhash(_lockAddress[user][input.index]);
        bytes memory blockHeader;
        blockHeader = _zkBridge.BlockHeader(input.blockNumber);

        // 1. get valueBytes
        bytes memory valueBytes;
        valueBytes = uint64_to_bytes_le(input.value);
        _lockValue[user][input.index] = value;

        // 2. call zkSNARK verifier
        bool verifyResult = true;
        verifyResult = _verifier.verifyProofAlt(input.proof.a, input.proof.b, input.proof.c, valueBytes, pubKeyHashBytes, blockHeader);

        // 3. mint tokens if pass
        if (verifyResult == true) {
            _token.mint(input.onBehalfOf, value);
        }
        _result = verifyResult;

        return verifyResult;
    }

    function Burn(address onBehalfOf, uint256 index) external returns (bool res) {
        if (_isValidLockAddress[onBehalfOf][index] != true) {
            res = false;
        }
        uint64 value = _lockValue[onBehalfOf][index];
        if (value == 0) {
            res = false;
        }
        address user = msg.sender;
        _token.burn(user, value);
        _isValidLockAddress[onBehalfOf][index] = false;
        // TODO: call zkBridge to unlock in ZCash chain

        res = true;
        _result = res;
    }
}