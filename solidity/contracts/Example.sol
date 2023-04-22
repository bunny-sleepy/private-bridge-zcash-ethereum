// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import {IVerifier} from "./Interface/IVerifier.sol"; 
import {IzkBridge} from "./Interface/IzkBridge.sol";
import {IMockToken} from "./Interface/IMockToken.sol";

contract Example {
    IMockToken _token;
    IVerifier _verifier;
    IzkBridge _zkBridge;
    mapping(address => bool) internal _writePermission;
    mapping(address => mapping(uint256 => bytes)) internal _lockAddress;
    mapping(address => mapping(uint256 => uint256)) internal _lockValue;
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

    function VerifyAndMint(
        address onBehalfOf,
        uint256 index,
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[68] memory input,
        uint256 blockNumber
    ) external returns (bool) {
        // 0. TODO: get value, pubKeyHash of lockAddress from txData
        address user = msg.sender;
        require(_isValidLockAddress[user][index] == true);
        uint256 value = 0;
        bytes memory pubKeyHash;
        bytes memory lockAddress = _lockAddress[user][index];
        // 1. TODO: verify pubKeyHash and lockAddress are consistent; value > 0
        require(value > 0);
        require(keccak256(pubKeyHash) == keccak256(lockAddress));
        _lockValue[user][index] = value;

        // 2. TODO: convert txData to SNARK verifier input
        bool verifyResult = _verifier.verifyProof(a, b, c, input);
        require(verifyResult == true);

        // 3. mint tokens if pass
        _token.mint(onBehalfOf, value);
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