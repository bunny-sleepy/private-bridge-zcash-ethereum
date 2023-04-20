pragma circom 2.0.0;

function blake2b_iv(x) {
    var iv[8] = [0x6a09e667f3bcc908, 0xbb67ae8584caa73b,
                0x3c6ef372fe94f82b, 0xa54ff53a5f1d36f1,
                0x510e527fade682d1, 0x9b05688c2b3e6c1f,
                0x1f83d9abfb41bd6b, 0x5be0cd19137e2179];

    var bits[64];
    for (var i=0; i<64; i++) {
        bits[i] = (iv[x] >> i) & 1;
    }

    return bits;
}

function iv_init0() {
    var iv0 = 0x6a09e667f3bcc908;
    var bits[64];

    iv0 = iv0 ^ (0x01010000 | 0 | 32);
    
    for (var i=0; i<64; i++) {
        bits[i] = (iv0 >> i) & 1;
    }

    return bits;
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
        out[i] <== 1 - in[i];
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

template G(a,b,c,d) {
    signal input v[16][64];
    signal input x[64];
    signal input y[64];
    signal output v_out[16][64];

    for (var i=0; i<16; i++) {
        for (var j=0; j<64; j++) {
            if (i != a && i != b && i != c && i != d){
                v_out[i][j] <== v[i][j];
            }
        }
    }

    signal tmpa[64], tmpb[64], tmpc[64], tmpd[64];
    component xor[4], rot[4];
    
    xor[0] = xor64();
    xor[1] = xor64();
    xor[2] = xor64();
    xor[3] = xor64();
    rot[0] = rotr64(32);
    rot[1] = rotr64(24);
    rot[2] = rotr64(16);
    rot[3] = rotr64(63);

    for (var i=0; i<64; i++) {
        tmpa[i] <== v[a][i] + v[b][i] + x[i];
    }

    for (var i=0; i<64; i++) {
        xor[0].a[i] <== tmpa[i];
        xor[0].b[i] <== v[d][i];
    }
    for (var i=0; i<64; i++) {
        rot[0].in[i] <== xor[0].out[i];
    }
    for (var i=0; i<64; i++) {
        tmpd[i] <== rot[0].out[i];
    }
    
    for (var i=0; i<64; i++) {
        tmpc[i] <== v[c][i] + tmpd[i];
    }

    for (var i=0; i<64; i++) {
        xor[1].a[i] <== v[b][i];
        xor[1].b[i] <== tmpc[i];
    }
    for (var i=0; i<64; i++) {
        rot[1].in[i] <== xor[1].out[i];
    }
    for (var i=0; i<64; i++) {
        tmpb[i] <== rot[1].out[i];
    }
    
    for (var i=0; i<64; i++) {
        v_out[a][i] <== tmpa[i] + tmpb[i] + y[i];
    }

    for (var i=0; i<64; i++) {
        xor[2].a[i] <== v_out[a][i];
        xor[2].b[i] <== tmpd[i];
    }
    for (var i=0; i<64; i++) {
        rot[2].in[i] <== xor[2].out[i];
    }
    for (var i=0; i<64; i++) {
        v_out[d][i] <== rot[2].out[i];
    }

    for (var i=0; i<64; i++) {
        v_out[c][i] <== tmpc[i] + v_out[d][i];
    }

    for (var i=0; i<64; i++) {
        xor[3].a[i] <== tmpb[i];
        xor[3].b[i] <== v_out[c][i];
    }
    for (var i=0; i<64; i++) {
        rot[3].in[i] <== xor[3].out[i];
    }
    for (var i=0; i<64; i++) {
        v_out[b][i] <== rot[3].out[i];
    }
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

        G[k][0] = G(0, 4, 8, 12);
        G[k][1] = G(1, 5, 9, 13);
        G[k][2] = G(2, 6, 10, 14);
        G[k][3] = G(3, 7, 11, 15);
        G[k][4] = G(0, 5, 10, 15);
        G[k][5] = G(1, 6, 11, 12);
        G[k][6] = G(2, 7, 8, 13);
        G[k][7] = G(3, 4, 9, 14);

        for (var j = 0; j < 8; j++) {
            for (var l = 0; l < 64; l++) {
                G[k][j].x[l] <== m[sigma(k,2*j)][l];
                G[k][j].y[l] <== m[sigma(k,2*j+1)][l];
            }
        }

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
    signal input t0[64];

    signal output h_out[8][64];

    component Rounds = rounds();
    var iv[8][64];

    signal v[16][64], m[16][64];

    component xor;
    xor = xor64();

    component not = not64();

    for (var i=0; i<8; i++) {
        for (var j=0; j<64; j++) {
            v[i][j] <== h[i][j];
        }
    }
    for (var i=8; i<16; i++) {
        iv[i-8] = blake2b_iv(i-8);

        for (var j=0; j<64; j++) {
            if (i != 12 && (i != 14 || last == 0)){
                v[i][j] <== iv[i-8][j];
            }
            if (i == 12) {
                xor.a[j] <== iv[i-8][j];
                xor.b[j] <== t0[j];
            }
            if (i == 14 && last == 1) {
                not.in[j] <== iv[i-8][j];
            }
        }
    }
    for (var j=0; j<64; j++) {
        v[12][j] <== xor.out[j];
        v[14][j] <== not.out[j];
    }

    component get64[16];
    for (var i=0; i<16; i++) {
        get64[i] = get64(8*i);

        for (var j=0; j<128; j++) {
            for (var k=0; k<8; k++) {
                get64[i].b[j][k] <== b[j][k];
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
        xor3[i] = xor3();
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

function blake2b_init() {
    var h[8][64];

    for (var i=0; i<8; i++) {
        var tmp[64] = blake2b_iv(i);
        for (var j=0; j<64; j++) {
            h[i][j] = tmp[j];
        }
    }
    var tmp[64] = iv_init0();
    for (var j=0; j<64; j++) {
        h[0][j] = tmp[j];
    }

    return h;
}

template blake2b(inLen) {
    signal input in[inLen][8];
    signal output out[32][8];

    var nBlocks = (inLen % 128 == 0) ? (inLen >> 7) : ((inLen >> 7) + 1);

    signal pad_in[nBlocks*128][8];

    for (var i=0; i<inLen; i++) {
        for (var j=0; j<8; j++) {
            pad_in[i][j] <== in[i][j];
        }
    }
    for (var i=inLen; i<nBlocks*128; i++) {
        for (var j=0; j<8; j++) {
            pad_in[i][j] <== 0;
        }
    }

    var h_init[8][64] = blake2b_init();

    component comp[nBlocks];

    for (var i=0; i<nBlocks; i++){
        if (i == nBlocks-1)
            comp[i] = blake2b_compress(1);
        else
            comp[i] = blake2b_compress(1);

        for (var j=0; j<128; j++) {
            for (var k=0; k<8; k++) {
                comp[i].b[j][k] <== pad_in[i*128 + j][k];
            }
        }

        for (var j=0; j<8; j++) {
            for (var k=0; k<64; k++) {
                if (i == 0)
                    comp[i].h[j][k] <== h_init[j][k];
                else
                    comp[i].h[j][k] <== comp[i-1].h_out[j][k];
            }
        }
        
        for (var k=0; k<64; k++) {
            comp[i].t0[k] <== (128*i >> k) & 1;
        }
    }

    for (var i=0; i<32; i++) {
        for (var j=0; j<8; j++) {
            out[i][j] <== comp[nBlocks-1].h_out[i >> 3][j + 8*(i % 8)];
        }
    }

    log("aaa");

}

component main = blake2b(1024);