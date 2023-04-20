// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

interface IzkBridge {
    // returns the merkle root
    function BlockHeader(uint256 blockNumber) external view returns (bytes memory);
}