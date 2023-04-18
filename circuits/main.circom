pragma circom 2.0.0;

include "./merkle_tree.circom";

component main {public [root, merklePath, leaf, neighbor, index]} = MerkleTree(10, 10000, 10000);