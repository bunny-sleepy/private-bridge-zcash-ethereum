pragma circom 2.0.0;

include "./sha256d.circom";

// nBits: leaf node bit number
template MerkleTree(depth, nBitsLeaf, nBitsNeighbor) {
    signal input root[256];
    signal input merklePath[depth - 1][256];
    // leaf we what to commit to
    signal input leaf[nBitsLeaf];
    // neighbor of leaf in the last layer
    signal input neighbor[nBitsNeighbor];
    // index[i] = 0 means hash / leaf is on the left; 1 otherwise
    signal input index[depth];

    signal hash[depth][256];
    signal tmp[depth - 1][1024];
    signal tmp0[2][256];

    component hasher[depth - 1];
    component hasher0[2];
    
    var i;
    var j;
    var k;
    var idx;
    // bottom-up
    for (i = 0; i < depth; i++) {
        // dual selector
        idx = 0;
        index[i] * (1 - index[i]) === 0;
        // leaf inputs
        if (i == 0) {
            for (k = 0; k < 2; k++) {
                hasher0[k] = Sha256d(nBitsLeaf + nBitsNeighbor);
                if (k == 0) {
                    for (j = 0; j < nBitsLeaf; j++) {
                        hasher0[k].in[j] <== leaf[j];
                    }
                    for (j = 0; j < nBitsNeighbor; j++) {
                        hasher0[k].in[j + nBitsLeaf] <== neighbor[j];
                    }
                } else {
                    for (j = 0; j < nBitsNeighbor; j++) {
                        hasher0[k].in[j] <== neighbor[j];
                    }
                    for (j = 0; j < nBitsLeaf; j++) {
                        hasher0[k].in[j + nBitsNeighbor] <== leaf[j];
                    }
                }
            }
            for (j = 0; j < 256; j++) {
                tmp0[0][j] <== (1 - index[0]) * hasher0[0].out[j];
                tmp0[1][j] <== index[0] * hasher0[1].out[j];
                hash[i][j] <== tmp0[0][j] + tmp0[1][j];
            }
        } else {
            hasher[i - 1] = Sha256d(512);
            for (j = 0; j < 256; j++) {
                tmp[i - 1][idx] <== (1 - index[i]) * hash[i - 1][j];
                tmp[i - 1][idx + 1] <== index[i] * merklePath[i - 1][j];
                hasher[i - 1].in[j] <== tmp[i - 1][idx] + tmp[i - 1][idx + 1];
                idx = idx + 2;
            }
            for (j = 0; j < 256; j++) {
                tmp[i - 1][idx] <== index[i] * hash[i - 1][j];
                tmp[i - 1][idx + 1] <== (1 - index[i]) * merklePath[i - 1][j];
                hasher[i - 1].in[j + 256] <== tmp[i - 1][idx] + tmp[i - 1][idx + 1];
                idx = idx + 2;
            }
            for (j = 0; j < 256; j++) {
                hash[i][j] <== hasher[i - 1].out[j];
            }
        }
    }
    for (i = 0; i < 256; i++) {
        hash[depth-1][i] === root[i];
    }
}