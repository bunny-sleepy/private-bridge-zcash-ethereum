pragma solidity ^0.8.0;

contract Example {
    mapping(address => bool) permission;
    address lock_address;

    function WriteLockAddress(address addr) public {
        require(permission[msg.sender] == true);
        lock_address = addr;
    }
}