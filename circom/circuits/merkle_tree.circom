pragma circom 2.0.0;

include "./sha256d.circom";

// nBits: leaf node bit number
template MerkleTree(depth, nBitsLeaf, nBitsNeighbor) {
    signal output root[256];
    signal input merklePath[depth - 1][256];
    // leaf we what to commit to
    signal input leaf[nBitsLeaf];
    // neighbor of leaf in the last layer
    signal input neighbor[nBitsNeighbor];
    // index[i] = 0 means hash / leaf is on the left; 1 otherwise
    signal input index[depth];

    signal hash[depth][256];
    signal tmp[depth][1024];
    signal tmp0[2][256];

    component hasher[depth];
    component hasherLeaf = Sha256d(nBitsLeaf);
    component hasherNeighbor = Sha256d(nBitsNeighbor);
    
    var i;
    var j;
    var k;
    var idx;
    // bottom-up
    for (i = 0; i < depth; i++) {
        // dual selector
        idx = 0;
        index[i] * (1 - index[i]) === 0;
        if (i == 0) {
            // leaf inputs
            for (j = 0; j < nBitsLeaf; j++) {
                hasherLeaf.in[j] <== leaf[j];
            }
            for (j = 0; j < nBitsNeighbor; j++) {
                hasherNeighbor.in[j] <== neighbor[j];
            }
            hasher[i] = Sha256d(512);
            for (j = 0; j < 256; j++) {
                tmp[i][idx] <== (1 - index[i]) * hasherLeaf.out[j];
                tmp[i][idx + 1] <== index[i] * hasherNeighbor.out[j];
                hasher[i].in[j] <== tmp[i][idx] + tmp[i][idx + 1];
                idx = idx + 2;
            }
            for (j = 0; j < 256; j++) {
                tmp[i][idx] <== index[i] * hasherLeaf.out[j];
                tmp[i][idx + 1] <== (1 - index[i]) * hasherNeighbor.out[j];
                hasher[i].in[j + 256] <== tmp[i][idx] + tmp[i][idx + 1];
                idx = idx + 2;
            }
            for (j = 0; j < 256; j++) {
                hash[i][j] <== hasher[i].out[j];
            }
        } else {
            hasher[i] = Sha256d(512);
            for (j = 0; j < 256; j++) {
                tmp[i][idx] <== (1 - index[i]) * hash[i - 1][j];
                tmp[i][idx + 1] <== index[i] * merklePath[i - 1][j];
                hasher[i].in[j] <== tmp[i][idx] + tmp[i][idx + 1];
                idx = idx + 2;
            }
            for (j = 0; j < 256; j++) {
                tmp[i][idx] <== index[i] * hash[i - 1][j];
                tmp[i][idx + 1] <== (1 - index[i]) * merklePath[i - 1][j];
                hasher[i].in[j + 256] <== tmp[i][idx] + tmp[i][idx + 1];
                idx = idx + 2;
            }
            for (j = 0; j < 256; j++) {
                hash[i][j] <== hasher[i].out[j];
            }
        }
    }
    for (i = 0; i < 256; i++) {
        root[i] <== hash[depth-1][i];
    }
}