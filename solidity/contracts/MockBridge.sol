// SPDX-License-Identifier: GPL-3.0
pragma solidity >= 0.8.0;

import {IzkBridge} from "./Interface/IzkBridge.sol";

contract MockBridge is IzkBridge {
    function BlockHeader(
        uint256 blockNumber
    ) external view returns (bytes memory) {
        bytes memory res;
        return res;
    }
}