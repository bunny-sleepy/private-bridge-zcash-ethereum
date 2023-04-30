// SPDX-License-Identifier: GPL-3.0
pragma solidity >= 0.8.0;

import {IzkBridge} from "./Interface/IzkBridge.sol";

contract MockBridge is IzkBridge {
    function BlockHeader(
        uint256 blockNumber
    ) external view returns (bytes memory) {
        bytes memory res = hex"097bd439c7968f3e3ee0fee6066a5bcf0a69c1b8df26f9a44a155982537b594c";
        return res;
    }
}