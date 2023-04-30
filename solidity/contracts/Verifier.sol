//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// 2019 OKIMS
//      ported to solidity 0.6
//      fixed linter warnings
//      added requiere error messages
//
//
// SPDX-License-Identifier: GPL-3.0
pragma solidity >= 0.8.0;

import {IVerifier} from "./Interface/IVerifier.sol";
library Pairing {
    struct G1Point {
        uint X;
        uint Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }
    /// @return the generator of G1
    function P1() internal pure returns (G1Point memory) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2
    function P2() internal pure returns (G2Point memory) {
        // Original code point
        return G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );

/*
        // Changed by Jordi point
        return G2Point(
            [10857046999023057135944570762232829481370756359578518086990519993285655852781,
             11559732032986387107991004021392285783925812861821192530917403151452391805634],
            [8495653923123431417604973247489272438418190587263600148770280649306958101930,
             4082367875863433681332203403145435568316851327593401208105741076214120093531]
        );
*/
    }
    /// @return r the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point memory p) internal pure returns (G1Point memory r) {
        // The prime q in the base field F_q for G1
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return r the sum of two points of G1
    function addition(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success,"pairing-add-failed");
    }
    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point memory p, uint s) internal view returns (G1Point memory r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success,"pairing-mul-failed");
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length,"pairing-lengths-failed");
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[0];
            input[i * 6 + 3] = p2[i].X[1];
            input[i * 6 + 4] = p2[i].Y[0];
            input[i * 6 + 5] = p2[i].Y[1];
        }
        uint[1] memory out;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success,"pairing-opcode-failed");
        return out[0] != 0;
    }
    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(G1Point memory a1, G2Point memory a2, G1Point memory b1, G2Point memory b2) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for three pairs.
    function pairingProd3(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for four pairs.
    function pairingProd4(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2,
            G1Point memory d1, G2Point memory d2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
}
contract Verifier is IVerifier {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G1Point alfa1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        Pairing.G1Point[] IC;
    }
    struct Proof {
        Pairing.G1Point A;
        Pairing.G2Point B;
        Pairing.G1Point C;
    }
    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = Pairing.G1Point(
            1,
            2
        );

        vk.beta2 = Pairing.G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );
        vk.gamma2 = Pairing.G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );
        vk.delta2 = Pairing.G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );
        vk.IC = new Pairing.G1Point[](481);
        
        vk.IC[0] = Pairing.G1Point( 
            1,
            2
        );                                      
        
        vk.IC[1] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[2] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[3] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[4] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[5] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[6] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[7] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[8] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[9] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[10] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[11] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[12] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[13] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[14] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[15] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[16] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[17] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[18] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[19] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[20] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[21] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[22] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[23] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[24] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[25] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[26] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[27] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[28] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[29] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[30] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[31] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[32] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[33] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[34] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[35] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[36] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[37] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[38] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[39] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[40] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[41] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[42] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[43] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[44] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[45] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[46] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[47] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[48] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[49] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[50] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[51] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[52] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[53] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[54] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[55] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[56] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[57] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[58] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[59] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[60] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[61] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[62] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[63] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[64] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[65] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[66] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[67] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[68] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[69] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[70] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[71] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[72] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[73] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[74] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[75] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[76] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[77] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[78] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[79] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[80] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[81] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[82] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[83] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[84] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[85] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[86] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[87] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[88] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[89] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[90] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[91] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[92] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[93] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[94] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[95] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[96] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[97] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[98] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[99] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[100] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[101] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[102] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[103] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[104] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[105] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[106] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[107] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[108] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[109] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[110] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[111] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[112] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[113] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[114] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[115] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[116] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[117] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[118] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[119] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[120] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[121] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[122] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[123] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[124] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[125] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[126] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[127] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[128] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[129] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[130] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[131] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[132] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[133] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[134] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[135] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[136] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[137] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[138] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[139] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[140] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[141] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[142] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[143] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[144] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[145] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[146] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[147] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[148] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[149] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[150] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[151] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[152] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[153] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[154] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[155] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[156] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[157] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[158] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[159] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[160] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[161] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[162] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[163] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[164] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[165] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[166] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[167] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[168] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[169] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[170] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[171] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[172] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[173] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[174] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[175] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[176] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[177] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[178] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[179] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[180] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[181] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[182] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[183] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[184] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[185] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[186] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[187] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[188] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[189] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[190] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[191] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[192] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[193] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[194] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[195] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[196] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[197] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[198] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[199] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[200] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[201] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[202] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[203] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[204] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[205] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[206] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[207] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[208] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[209] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[210] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[211] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[212] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[213] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[214] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[215] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[216] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[217] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[218] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[219] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[220] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[221] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[222] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[223] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[224] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[225] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[226] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[227] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[228] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[229] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[230] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[231] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[232] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[233] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[234] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[235] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[236] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[237] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[238] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[239] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[240] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[241] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[242] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[243] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[244] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[245] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[246] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[247] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[248] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[249] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[250] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[251] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[252] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[253] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[254] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[255] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[256] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[257] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[258] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[259] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[260] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[261] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[262] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[263] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[264] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[265] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[266] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[267] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[268] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[269] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[270] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[271] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[272] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[273] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[274] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[275] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[276] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[277] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[278] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[279] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[280] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[281] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[282] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[283] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[284] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[285] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[286] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[287] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[288] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[289] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[290] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[291] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[292] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[293] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[294] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[295] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[296] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[297] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[298] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[299] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[300] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[301] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[302] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[303] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[304] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[305] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[306] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[307] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[308] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[309] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[310] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[311] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[312] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[313] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[314] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[315] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[316] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[317] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[318] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[319] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[320] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[321] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[322] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[323] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[324] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[325] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[326] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[327] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[328] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[329] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[330] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[331] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[332] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[333] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[334] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[335] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[336] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[337] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[338] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[339] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[340] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[341] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[342] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[343] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[344] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[345] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[346] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[347] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[348] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[349] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[350] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[351] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[352] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[353] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[354] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[355] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[356] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[357] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[358] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[359] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[360] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[361] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[362] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[363] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[364] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[365] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[366] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[367] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[368] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[369] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[370] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[371] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[372] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[373] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[374] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[375] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[376] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[377] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[378] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[379] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[380] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[381] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[382] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[383] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[384] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[385] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[386] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[387] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[388] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[389] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[390] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[391] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[392] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[393] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[394] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[395] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[396] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[397] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[398] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[399] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[400] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[401] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[402] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[403] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[404] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[405] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[406] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[407] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[408] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[409] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[410] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[411] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[412] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[413] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[414] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[415] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[416] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[417] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[418] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[419] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[420] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[421] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[422] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[423] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[424] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[425] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[426] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[427] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[428] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[429] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[430] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[431] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[432] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[433] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[434] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[435] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[436] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[437] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[438] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[439] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[440] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[441] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[442] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[443] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[444] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[445] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[446] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[447] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[448] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[449] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[450] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[451] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[452] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[453] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[454] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[455] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[456] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[457] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[458] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[459] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[460] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[461] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[462] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[463] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[464] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[465] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[466] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[467] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[468] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[469] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[470] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[471] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[472] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[473] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[474] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[475] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[476] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[477] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[478] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[479] = Pairing.G1Point( 
            0,
            1
        );                                      
        
        vk.IC[480] = Pairing.G1Point( 
            0,
            1
        );                                      
        
    }
    function verify(uint[] memory input, Proof memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.IC.length,"verifier-bad-input");
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field,"verifier-gte-snark-scalar-field");
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.IC[i + 1], input[i]));
        }
        vk_x = Pairing.addition(vk_x, vk.IC[0]);
        if (!Pairing.pairingProd4(
            Pairing.negate(proof.A), proof.B,
            vk.alfa1, vk.beta2,
            vk_x, vk.gamma2,
            proof.C, vk.delta2
        )) return 1;
        return 0;
    }
    /// @return r  bool true if proof is valid
    function verifyProof(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[480] memory input
        ) external view returns (bool r) {
        Proof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = Pairing.G1Point(c[0], c[1]);
        uint[] memory inputValues = new uint[](input.length);
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}
