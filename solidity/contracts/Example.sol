// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import {IVerifier} from "./Interface/IVerifier.sol"; 
import {IzkBridge} from "./Interface/IzkBridge.sol";
import {IMockToken} from "./Interface/IMockToken.sol";
import {Base58} from "./Dependency/storyicon/Base58.sol";

contract Example {
    IMockToken _token;
    IVerifier _verifier;
    IzkBridge _zkBridge;
    // TODO: change these values
    uint constant bytesBefore = 1;
    uint constant bytesBetween = 1;
    uint constant bytesAfter = 1;
    uint constant depth = 2;
    mapping(address => bool) internal _writePermission;
    mapping(address => mapping(uint256 => bytes)) internal _lockAddress;
    mapping(address => mapping(uint256 => uint64)) internal _lockValue;
    mapping(address => mapping(uint256 => bool)) internal _isValidLockAddress;
    mapping(address => uint256) internal _maxIndexLockAddress;

    constructor(
        IMockToken token,
        IVerifier verifier,
        IzkBridge zkBridge,
        address[] memory relayers
    ) {
        _token = token;
        _verifier = verifier;
        _zkBridge = zkBridge;
        for (uint i = 0; i < relayers.length; i++) {
            _writePermission[relayers[i]] = true;
        }
    }

    // lockAddress, user_address, index
    // whether or not the lockAddress is used
    function WriteLockAddress(address user, bytes calldata addr) external {
        require(_writePermission[msg.sender] == true);
        uint256 currentIndex = _maxIndexLockAddress[user];
        _isValidLockAddress[user][currentIndex] = true;
        _lockAddress[user][currentIndex] = addr;
        _maxIndexLockAddress[user] = currentIndex + 1;
    }

    function writePermission(address addr) external view returns (bool) {
        return _writePermission[addr];
    }

    function lockAddress(address user, uint256 index) external view returns (bytes memory) {
        return _lockAddress[user][index];
    }

    function bytesToUint64(bytes memory b) public pure returns (uint64) {
        require(b.length == 8, "Bytes array length must be 8");

        uint64 result;
        assembly {
            result := mload(add(b, 8))
        }
        return result;
    }


    function bitArrayToBytes(uint256[8][] memory bits) internal pure returns (bytes memory) {
        uint256 n = bits.length;
        bytes memory bytesArr = new bytes(n);
        for (uint256 index = 0; index < n; index++) {
            for (uint8 j = 0; j < 8; j++) {
                if (bits[index][j] == 1) {
                    bytesArr[index] |= bytes1(uint8(1) << j);
                }
            }
        }
        return bytesArr;
    }

    function bitcoinPubkeyhashAddressConsistent(
        bytes memory pubKeyHash,
        bytes memory _addr
    ) internal pure returns (bool) {
        bytes memory addr = Base58.decode(_addr);
        if (addr.length != 25) {
            return false;
        }
        if (pubKeyHash.length != 20) {
            return false;
        }
        // we allow only P2PKH address
        if (addr[0] != 0x00) {
            return false;
        }
        bytes memory bytesArr = new bytes(20);
        for (uint i = 0; i < 20; i++) {
            bytesArr[i] = addr[i+1];
        }
        if (keccak256(pubKeyHash) != keccak256(bytesArr)) {
            return false;
        }
        return true;
    }

    struct VerifierInput {
        uint256[4][8] CONSENSUS_BRANCH_ID;
        uint256[32][8] header_digest;
        uint256[32][8] prevouts_digest;
        uint256[32][8] sequence_digest;
        uint256[32][8] sapling_digest;
        uint256[32][8] orchard_digest;
        uint256[bytesBefore][8] bytes_before;
        uint256[8][8] value;
        uint256[bytesBetween][8] bytes_between;
        uint256[20][8] pubKeyHash;
        uint256[bytesAfter][8] bytes_after;
        // mtp signals
        uint256[256] root;
        uint256[depth - 1][256] merklePath;
        // neighbor of leaf in the last layer
        uint256[256] neighbor;
        // index[i] = 0 means hash / leaf is on the left; 1 otherwise
        uint256[depth] index;
    }

    struct VerifyAndMintInput {
        address onBehalfOf;
        uint256 index;
        uint256 blockNumber;
        uint[2] a;
        uint[2][2] b;
        uint[2] c;
        // uint[68] memory input;
        VerifierInput verifierInput;
    }

    function VerifyAndMint(
        VerifyAndMintInput memory input
    ) external returns (bool) {
        // 0. get value, pubKeyHash of lockAddress from txData
        address user = msg.sender;
        require(_isValidLockAddress[user][input.index] == true);
        require(_lockValue[user][input.index] == uint64(0));
        uint64 value;
        bytes memory pubKeyHashBytes;
        {
            uint256[8][] memory tmp_value = new uint256[8][](8);
            for (uint i = 0; i < 8; i++) {
                for (uint j = 0; j < 8; j++) {
                    tmp_value[i][j] = input.verifierInput.value[i][j];
                }
            }
            bytes memory valueBytes = bitArrayToBytes(tmp_value);
            value = bytesToUint64(valueBytes);
        }
        // convert pubKeyHash to tmp dynamic 2-d array
        {
            uint256[8][] memory tmp_pubKeyHash = new uint256[8][](20);
            for (uint i = 0; i < 20; i++) {
                for (uint j = 0; j < 8; j++) {
                    tmp_pubKeyHash[i][j] = input.verifierInput.pubKeyHash[i][j];
                }
            }
            pubKeyHashBytes = bitArrayToBytes(tmp_pubKeyHash);
            
        }
        // 1. verify pubKeyHash and lockAddress are consistent; value > 0
        {
            // bytes memory lockAddress = _lockAddress[user][input.index];
            require(value > 0);
            bool checkValue = bitcoinPubkeyhashAddressConsistent(pubKeyHashBytes, _lockAddress[user][input.index]);
            require(checkValue == true);
        }
        _lockValue[user][input.index] = value;

        // 2. TODO: convert txData to SNARK verifier input
        uint[480] memory tmp;
        bool verifyResult = _verifier.verifyProof(input.a, input.b, input.c, tmp);
        require(verifyResult == true);

        // 3. mint tokens if pass
        _token.mint(input.onBehalfOf, value);

        return verifyResult;
    }

    // (value, address, root)
    function Burn(address onBehalfOf, uint256 index) external {
        require(_isValidLockAddress[onBehalfOf][index] == true);
        uint256 value = _lockValue[onBehalfOf][index];
        require(value > 0);
        address user = msg.sender;
        _token.burn(user, value);
        // TODO: call zkBridge to unlock in ZCash chain
        _isValidLockAddress[onBehalfOf][index] = false;
    }
}