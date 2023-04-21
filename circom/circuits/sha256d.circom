pragma circom 2.0.0;

include "../../node_modules/circomlib/circuits/sha256/sha256.circom";

template Sha256d(nBits) {
    signal input in[nBits];
    signal output out[256];
    var i;
    component hasher1 = Sha256(nBits);
    for (i = 0; i < nBits; i++) {
        hasher1.in[i] <== in[i];
    }
    component hasher2 = Sha256(256);
    for (i = 0; i < 256; i++) {
        hasher2.in[i] <== hasher1.out[i];
    }

    for (i = 0; i < 256; i++) {
        out[i] <== hasher2.out[i];
    }
}