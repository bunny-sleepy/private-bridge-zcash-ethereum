pragma circom 2.0.0;

template blake2b_iv(x) {
    signal output out[64];
    var iv[8] = [0x6a09e667f3bcc908, 0xbb67ae8584caa73b,
                0x3c6ef372fe94f82b, 0xa54ff53a5f1d36f1,
                0x510e527fade682d1, 0x9b05688c2b3e6c1f,
                0x1f83d9abfb41bd6b, 0x5be0cd19137e2179];

    for (var i=0; i<64; i++) {
        out[i] <== (iv[x] >> i) & 1;
    }
}

template rotr64(c) {
    signal input in[64];
    signal output out[64];

    for (var i=0; i<64; i++) {
        out[i] <== in[ (i+c)%64 ];
    }
}

template shiftr64(c) {
    signal input in[64];
    signal output out[64];

    for (var i=0; i<64; i++) {
        if (i+c >= 64) {
            out[i] <== 0;
        } else {
            out[i] <== in[ i+c ];
        }
    }
}

template get64(loc) {
    signal input b[128][8];
    signal output out[64];

    for (var i=0; i<64; i++) {
        out[i] <== b[loc + (i >> 3)][i % 3];
    }
}

// Requires input to be 64 bits
template xor64() {
    signal input a[64];
    signal input b[64];
    signal output out[64];

    for (var i=0; i<64; i++) {
        out[i] <== a[i] + b[i] - 2*a[i]*b[i];
    }
}

template xor3() {
    signal input a[64];
    signal input b[64];
    signal input c[64];
    signal output out[64];
    signal mid[64];

    for (var k=0; k<64; k++) {
        mid[k] <== b[k]*c[k];
        out[k] <== a[k] * (1 -2*b[k]  -2*c[k] +4*mid[k]) + b[k] + c[k] -2*mid[k];
    }
}

template not64() {
    signal input in[64];
    signal output out[64];

    for (var i=0; i<64; i++) {
        out[i] <== 1 + in[i] - 2*in[i];
    }
}

function sigma(a,b) {
    var sigma[12][16] = [
           [ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 ],
           [ 14, 10, 4, 8, 9, 15, 13, 6, 1, 12, 0, 2, 11, 7, 5, 3 ],
           [ 11, 8, 12, 0, 5, 2, 15, 13, 10, 14, 3, 6, 7, 1, 9, 4 ],
           [ 7, 9, 3, 1, 13, 12, 11, 14, 2, 6, 5, 10, 4, 0, 15, 8 ],
           [ 9, 0, 5, 7, 2, 4, 10, 15, 14, 1, 11, 12, 6, 8, 3, 13 ],
           [ 2, 12, 6, 10, 0, 11, 8, 3, 4, 13, 7, 5, 15, 14, 1, 9 ],
           [ 12, 5, 1, 15, 14, 13, 4, 10, 0, 7, 6, 3, 9, 2, 8, 11 ],
           [ 13, 11, 7, 14, 12, 1, 3, 9, 5, 0, 15, 4, 8, 6, 2, 10 ],
           [ 6, 15, 14, 9, 11, 3, 0, 8, 12, 2, 13, 7, 1, 4, 10, 5 ],
           [ 10, 2, 8, 4, 7, 6, 1, 5, 15, 11, 9, 14, 3, 12, 13, 0 ],
           [ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 ],
           [ 14, 10, 4, 8, 9, 15, 13, 6, 1, 12, 0, 2, 11, 7, 5, 3 ]
    ];

    return sigma[a][b];
}

template G(a,b,c,d,x,y) {
    signal input v[16][64];
    signal output v_out[16][64];

    for (var i=0; i<64; i++) {
        if (i != a && i != b && i != c && i != d){
            v_out[i] <== v[i];
        }
    }

    var tmpa, tmpb, tmpc, tmpd;
    component xor[4], rot[4];
    
    xor[0] = xor64();
    xor[1] = xor64();
    xor[2] = xor64();
    xor[3] = xor64();
    rot[0] = rotr64(32);
    rot[1] = rotr64(24);
    rot[2] = rotr64(16);
    rot[3] = rotr64(63);

    tmpa <== v[a] + v[b] + x;
    
    xor[0].in <== tmpa;
    xor[0].in <== v[d];
    rot[0].in <== xor[0].out;
    tmpd <== rot[0].out;

    tmpc <== v[c] + tmpd;

    xor[1].in <== v[b];
    xor[1].in <== tmpc;
    rot[1].in <== xor[1].out;
    tmpb <== rot[1].out;

    v_out[a] <== tmpa + tmpb + y;

    xor[2].in <== v_out[a];
    xor[2].in <== tmpd;
    rot[2].in <== xor[2].out;
    v_out[d] <== rot[2].out;

    v_out[c] <== tmpc + v_out[d];

    xor[3].in <== tmpb;
    xor[3].in <== v_out[c];
    rot[3].in <== xor[3].out;
    v_out[b] <== rot[3].out;

}

// All 12 rounds
template rounds() {
    signal input v[16][64];
    signal input m[16][64];
    signal output v_out[16][64];

    component G[12][8];
    signal tmpv[12][16][64];

    for (var l=0; l<16; l++) {
        tmpv[0][l] <== v[l];
    }

    for (var k=0; k<12; k++) {
        if(k != 0){
            for (var l=0; l<16; l++) {
                for (var i=0; i<64; i++) {
                    tmpv[k][l][i] <== tmpv[k-1][l][i];
                }
            }
        }

        G[k][0] = G(0, 4, 8, 12, m[sigma(k,0)], m[sigma(k,1)]);
        G[k][1] = G(1, 5, 9, 13, m[sigma(k,2)], m[sigma(k,3)]);
        G[k][2] = G(2, 6, 10, 14, m[sigma(k,4)], m[sigma(k,5)]);
        G[k][3] = G(3, 7, 11, 15, m[sigma(k,6)], m[sigma(k,7)]);
        G[k][4] = G(0, 5, 10, 15, m[sigma(k,8)], m[sigma(k,9)]);
        G[k][5] = G(1, 6, 11, 12, m[sigma(k,10)], m[sigma(k,11)]);
        G[k][6] = G(2, 7, 8, 13, m[sigma(k,12)], m[sigma(k,13)]);
        G[k][7] = G(3, 4, 9, 14, m[sigma(k,14)], m[sigma(k,15)]);

        for (var j = 0; j < 8; j++) {
            for (var l = 0; l < 16; l++) {
                G[k][j].v[l] <== tmpv[k][l];
            }
        }
    }

    for (var l=0; l<16; l++) {
        v_out[l] <== tmpv[11][l];
    }
}

template blake2b_compress(last) {
    signal input b[128][8];
    signal input h[8][64];
    signal input t[2][64];

    signal output h_out[8][64];

    component Rounds = rounds();
    component iv[8];

    var v[16][64], m[16][64];

    component xor[2];
    xor[0] = xor64();
    xor[1] = xor64();

    component not = not64();

    for (var i=0; i<16; i++) {
        if (i < 8) {
            for (var j=0; j<64; j++) {
                v[i][j] <== h[i][j];
            }
        } 
        else {
            iv = blake2b_iv(i-8);

            for (var j=0; j<64; j++) {
                if (i != 12 && i != 13 && (i != 14 || last == 0)){
                    v[i][j] <== iv.out[j];
                }
                if (i == 12) {
                    xor[0].in <== iv.out[j];
                    xor[0].in <== t[0][j];
                    v[12][j] <== xor[0].out;
                }
                if (i == 13) {
                    xor[1].in <== iv.out[j];
                    xor[1].in <== t[1][j];
                    v[13][j] <== xor[1].out;
                }
                if (i == 14 && last == 1) {
                    not.in <== iv.out[j];
                    v[14][j] <== iv.out[j];
                }
            }
        }
    }

    component get64[16];
    for (var i=0; i<16; i++) {
        get64[i] = get64(8*i);

        for (var j=0; j<128; j++) {
            for (var k=0; k<8; k++) {
                get64[i].in[j][k] <== b[j][k];
            }
        }

        for (var j=0; j<64; j++) {
            m[i][j] <== get64[i].out[j];
        }
    }

    for (var i=0; i<16; i++) {
        for (var j=0; j<64; j++) {
            Rounds.v[i][j] <== v[i][j];
            Rounds.m[i][j] <== m[i][j];
        }
    }

    component xor3[8];

    for (var i=0; i<8; i++) {
        xor3[i] = xor64();
        for (var j=0; j<64; j++) {
            xor3[i].a[j] <== h[i][j];
            xor3[i].b[j] <== Rounds.v_out[i][j];
            xor3[i].c[j] <== Rounds.v_out[i+8][j];
        }
        for (var j=0; j<64; j++) {
            h_out[i][j] <== xor3[i].out[j];
        }
    }
}

template blake2b_init() {
    signal output h[8][64];
    signal output t[2][64];
    signal output b[128][8];

    component iv[8];

    for (var i=1; i<8; i++) {
        iv = blake2b_iv(i);
        for (var j=0; j<64; j++) {
            h[i][j] <== iv.out[j];
        }
    }
    
    component xor = xor64();
    for (var i=0; i<64; i++) {
        xor.a[i] <== iv.out[i];
        xor.b[i] <== ((0x01010000 | 0 | 32) >> i) & 1;
    }
    for (var i=0; i<64; i++) {
        h[0][i] <== xor.out[i];
    }

    for (var i=0; i<2; i++) {
        for (var j=0; j<64; j++) {
            t[i][j] <== 0;
        }
    }
    
    for (var i=0; i<128; i++) {
        for (var j=0; j<8; j++) {
            b[i][j] <== 0;
        }
    }
}

template blake2b_update(inLen) {
    signal input in[inLen][8];
    signal input b[128][8];
    signal input h[8][64];
    signal input t[2][64];
    signal input c;

    signal output h_out[8][64];
    signal output t_out[2][64];
    signal output b_out[128][8];
    signal output c_out;

    var tmpt[2][64], tmpb[128][8], tmpc;

    for (var i=0; i<inLen; i++) {

    }

}

template blake2b_final() {
    signal input b[128][8];
    signal input h[8][64];
    signal input t[2][64];
    signal input c;

    signal output out[32][8];
}
