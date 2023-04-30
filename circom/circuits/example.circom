pragma circom 2.0.0;

include "./merkle_tree.circom";
include "./zcash_tx.circom";

template open(depth, bytesBefore, bytesBetween, bytesAfter) {
    // tx signals
    signal input CONSENSUS_BRANCH_ID[4][8];
    signal input header_digest[32][8];
    signal input prevouts_digest[32][8];
    signal input sequence_digest[32][8];
    signal input sapling_digest[32][8];
    signal input orchard_digest[32][8];
    signal input bytes_before[bytesBefore][8];
    signal input value[8][8];
    signal input bytes_between[bytesBetween][8];
    signal input pubKeyHash[20][8];
    signal input bytes_after[bytesAfter][8];

    // mtp signals
    signal input root[256];
    signal input merklePath[depth - 1][256];
    // neighbor of leaf in the last layer
    signal input neighbor[256];
    // index[i] = 0 means hash / leaf is on the left; 1 otherwise
    signal input index[depth];

    var i;
    var j;

    component tx = zcash_tx_check(bytesBefore, bytesBetween, bytesAfter);
    component mtp = MerkleTree(depth, 256, 256);
    // tx
    // inputs
    for (i = 0; i < 4; i++) {
        for (j = 0; j < 8; j++) {
            tx.CONSENSUS_BRANCH_ID[i][j] <== CONSENSUS_BRANCH_ID[i][j];
        }
    }
    for (i = 0; i < 32; i++) {
        for (j = 0; j < 8; j++) {
            tx.header_digest[i][j] <== header_digest[i][j];
        }
    }
    for (i = 0; i < 32; i++) {
        for (j = 0; j < 8; j++) {
            tx.prevouts_digest[i][j] <== prevouts_digest[i][j];
        }
    }
    for (i = 0; i < 32; i++) {
        for (j = 0; j < 8; j++) {
            tx.sequence_digest[i][j] <== sequence_digest[i][j];
        }
    }
    for (i = 0; i < 32; i++) {
        for (j = 0; j < 8; j++) {
            tx.sapling_digest[i][j] <== sapling_digest[i][j];
        }
    }
    for (i = 0; i < 32; i++) {
        for (j = 0; j < 8; j++) {
            tx.orchard_digest[i][j] <== orchard_digest[i][j];
        }
    }
    for (i = 0; i < 8; i++) {
        for (j = 0; j < 8; j++) {
            tx.value[i][j] <== value[i][j];
        }
    }
    for (i = 0; i < 20; i++) {
        for (j = 0; j < 8; j++) {
            tx.pubKeyHash[i][j] <== pubKeyHash[i][j];
        }
    }
    for (i = 0; i < bytesBefore; i++) {
        for (j = 0; j < 8; j++) {
            tx.bytes_before[i][j] <== bytes_before[i][j];
        }
    }
    for (i = 0; i < bytesBetween; i++) {
        for (j = 0; j < 8; j++) {
            tx.bytes_between[i][j] <== bytes_between[i][j];
        }
    }
    for (i = 0; i < bytesAfter; i++) {
        for (j = 0; j < 8; j++) {
            tx.bytes_after[i][j] <== bytes_after[i][j];
        }
    }

    // outputs
    for (i = 0; i < 32; i++) {
        for (j = 0; j < 8; j++) {
            mtp.leaf[i*8+j] <== tx.txid_digest[i][j];
        }
    }

    // mtp
    
    // inputs
    for (i = 0; i < 256; i++) {
        mtp.root[i] <== root[i];
        mtp.neighbor[i] <== neighbor[i];
    }
    for (i = 0; i < depth; i++) {
        mtp.index[i] <== index[i];
    }
    for (i = 0; i < depth - 1; i++) {
        for (j = 0; j < 256; j++) {
            mtp.merklePath[i][j] <== merklePath[i][j];
        }
    }
    // NOTE: debugging
    // for (i = 0; i < 256; i++) {
    //     root[i] <== mtp.root[i];
    // }
}


// experimental setup
// value = 20000, consensus_branch_id = 0, all blake2b256 digest inputs are digest("abc"), and all intermediate bytes are 1 byte 0x00
// publicKeyHash (hex) = 662ad25db00e7bb38bc04831ae48b4b446d12698, corresponding to address (base58) 1AKDDsfTh8uY4X3ppy1m7jw1fVMBSMkzjP
// depth=2, neighbor: blake2b("abc") and path: sha256d("abc")
component main {public [root, value, pubKeyHash]} = open(2, 1, 1, 1);
// component main = open(2, 1, 1, 1);