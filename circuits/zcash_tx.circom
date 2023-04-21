pragma circom 2.0.0;

include "./blake2b.circom";

// Use this to check that the tx hashes correctly to the txhash
// All digests are personalized BLAKE2b-256 hashes.
// In cases where no elements are available for hashing (for example, if there
// are no transparent transaction inputs or no Orchard actions), a personalized hash of the empty byte array will be used.
// The personalization string therefore provides domain separation for the hashes of even empty data fields.
// The notation BLAKE2b-256(personalization_string, []) is used to refer to hashes constructed in this manner.
// Reference: https://zips.z.cash/zip-0244
template zcash_tx_check() {
    // All the tx data input
    // TODO: Add the size of each field
    // signal input header[4*8];
    // signal input nVersionGroupId[4*8];
    // signal input nConsensusBranchId[4*8];
    // signal input nLockTime[4*8];
    // signal input nExpiryHeight[4*8];

    // signal input tx_in_count;
    // signal input tx_in;
    // signal input tx_out_count;
    // signal input tx_out;

    // signal input nSpendsSapling;
    // signal input nOutputsSapling;

    // signal input nActionsOrchard;
    // signal input vActionsOrchard;
    // signal input flagsOrchard[1*8];
    // signal input valueBalanceOrchard[8*8];
    // signal input anchorOrchard[32*8];
    // signal input sizeProofsOrchard;
    // signal input proofsOrchard;
    // signal input vSpendAuthSigsOrchard;
    // signal input bindingSigOrchard;

    var i;
    var j;
    var k;
    // OUTPUT: txid_digest
    // A BLAKE2b-256 hash of the following values
    // T.1: header_digest       (32-byte hash output)
    // T.2: transparent_digest  (32-byte hash output)
    // T.3: sapling_digest      (32-byte hash output)
    // T.4: orchard_digest      (32-byte hash output)
    // The personalization field of this hash is set to: "ZcashTxHash_" || CONSENSUS_BRANCH_ID
    signal output txid_digest[32][8];
    var personalization_txid_digest[12][8] = [[0, 1, 0, 1, 1, 0, 1, 0], [0, 1, 1, 0, 0, 0, 1, 1], [0, 1, 1, 0, 0, 0, 0, 1], [0, 1, 1, 1, 0, 0, 1, 1], [0, 1, 1, 0, 1, 0, 0, 0], [0, 1, 0, 1, 0, 1, 0, 0], [0, 1, 1, 1, 1, 0, 0, 0], [0, 1, 0, 0, 1, 0, 0, 0], [0, 1, 1, 0, 0, 0, 0, 1], [0, 1, 1, 1, 0, 0, 1, 1], [0, 1, 1, 0, 1, 0, 0, 0], [0, 1, 0, 1, 1, 1, 1, 1]];
    signal input CONSENSUS_BRANCH_ID[4][8];
    component hasher_txid_digest = blake2b(12+4+(4*32));
    k = 0;
    for (i = 0; i < 12; i++) {
        for (j = 0; j < 8; j++) {
            hasher_txid_digest.in[k][j] <== personalization_txid_digest[i][j];
        }
        k++;
    }
    for (i = 0; i < 32; i++) {
        for (j = 0; j < 8; j++) {
            hasher_txid_digest.in[k][j] <== header_digest[i][j];
        }
        k++;
    }
    for (i = 0; i < 32; i++) {
        for (j = 0; j < 8; j++) {
            hasher_txid_digest.in[k][j] <== transparent_digest[i][j];
        }
        k++;
    }
    for (i = 0; i < 32; i++) {
        for (j = 0; j < 8; j++) {
            hasher_txid_digest.in[k][j] <== sapling_digest[i][j];
        }
        k++;
    }
    for (i = 0; i < 32; i++) {
        for (j = 0; j < 8; j++) {
            hasher_txid_digest.in[k][j] <== orchard_digest[i][j];
        }
        k++;
    }
    // txid_digest
    for (i = 0; i < 32; i++) {
        for (j = 0; j < 8; j++) {
            txid_digest[i][j] <== hasher_txid_digest.out[i][j];
        }
    }

    // 1. block header
    // A BLAKE2b-256 hash of the following values
    // T.1a: version             (4-byte little-endian version identifier including overwinter flag)
    // T.1b: version_group_id    (4-byte little-endian version group identifier)
    // T.1c: consensus_branch_id (4-byte little-endian consensus branch id)
    // T.1d: lock_time           (4-byte little-endian nLockTime value)
    // T.1e: expiry_height       (4-byte little-endian block height)
    // The personalization field of this hash is set to: "ZTxIdHeadersHash"
    signal header_digest[32][8];
    signal input version[4][8];
    signal input version_group_id[4][8];
    signal input consensus_branch_id[4][8];
    signal input lock_time[4][8];
    signal input expiry_height[4][8];
    var personalization_header_digest[16][8] = [[0, 1, 0, 1, 1, 0, 1, 0], [0, 1, 0, 1, 0, 1, 0, 0], [0, 1, 1, 1, 1, 0, 0, 0], [0, 1, 0, 0, 1, 0, 0, 1], [0, 1, 1, 0, 0, 1, 0, 0], [0, 1, 0, 0, 1, 0, 0, 0], [0, 1, 1, 0, 0, 1, 0, 1], [0, 1, 1, 0, 0, 0, 0, 1], [0, 1, 1, 0, 0, 1, 0, 0], [0, 1, 1, 0, 0, 1, 0, 1], [0, 1, 1, 1, 0, 0, 1, 0], [0, 1, 1, 1, 0, 0, 1, 1], [0, 1, 0, 0, 1, 0, 0, 0], [0, 1, 1, 0, 0, 0, 0, 1], [0, 1, 1, 1, 0, 0, 1, 1], [0, 1, 1, 0, 1, 0, 0, 0]];
    component hasher_header_digest = blake2b(16+(5*4));
    k = 0;
    for (i = 0; i < 16; i++) {
        for (j = 0; j < 8; j++) {
            hasher_header_digest.in[k][j] <== personalization_header_digest[i][j];
        }
        k++;
    }
    for (i = 0; i < 4; i++) {
        for (j = 0; j < 8; j++) {
            hasher_header_digest.in[k][j] <== version[i][j];
        }
        k++;
    }
    for (i = 0; i < 4; i++) {
        for (j = 0; j < 8; j++) {
            hasher_header_digest.in[k][j] <== version_group_id[i][j];
        }
        k++;
    }
    for (i = 0; i < 4; i++) {
        for (j = 0; j < 8; j++) {
            hasher_header_digest.in[k][j] <== consensus_branch_id[i][j];
        }
        k++;
    }
    for (i = 0; i < 4; i++) {
        for (j = 0; j < 8; j++) {
            hasher_header_digest.in[k][j] <== lock_time[i][j];
        }
        k++;
    }
    for (i = 0; i < 4; i++) {
        for (j = 0; j < 8; j++) {
            hasher_header_digest.in[k][j] <== expiry_height[i][j];
        }
        k++;
    }
    // header_digest
    for (i = 0; i < 32; i++) {
        for (j = 0; j < 8; j++) {
            header_digest[i][j] <== hasher_header_digest.out[i][j];
        }
    }

    // 2. transparent_digest
    // T.2a: prevouts_digest (32-byte hash)
    // T.2b: sequence_digest (32-byte hash)
    // T.2c: outputs_digest  (32-byte hash)
    // The personalization field of this hash is set to: "ZTxIdTranspaHash"
    signal transparent_digest[32][8];
    var personalization_transparent_digest[16][8] = [[0, 1, 0, 1, 1, 0, 1, 0], [0, 1, 0, 1, 0, 1, 0, 0], [0, 1, 1, 1, 1, 0, 0, 0], [0, 1, 0, 0, 1, 0, 0, 1], [0, 1, 1, 0, 0, 1, 0, 0], [0, 1, 0, 1, 0, 1, 0, 0], [0, 1, 1, 1, 0, 0, 1, 0], [0, 1, 1, 0, 0, 0, 0, 1], [0, 1, 1, 0, 1, 1, 1, 0], [0, 1, 1, 1, 0, 0, 1, 1], [0, 1, 1, 1, 0, 0, 0, 0], [0, 1, 1, 0, 0, 0, 0, 1], [0, 1, 0, 0, 1, 0, 0, 0], [0, 1, 1, 0, 0, 0, 0, 1], [0, 1, 1, 1, 0, 0, 1, 1], [0, 1, 1, 0, 1, 0, 0, 0]]
    component hasher_transparent_digest = blake2b(16+(3*32));
    k = 0;
    for (i = 0; i < 16; i++) {
        for (j = 0; j < 8; j++) {
            hasher_transparent_digest.in[k][j] <== personalization_transparent_digest[i][j];
        }
        k++;
    }
    for (i = 0; i < 32; i++) {
        for (j = 0; j < 8; j++) {
            hasher_transparent_digest.in[k][j] <== prevouts_digest[i][j];
        }
        k++;
    }
    for (i = 0; i < 32; i++) {
        for (j = 0; j < 8; j++) {
            hasher_transparent_digest.in[k][j] <== sequence_digest[i][j];
        }
        k++;
    }
    for (i = 0; i < 32; i++) {
        for (j = 0; j < 8; j++) {
            hasher_transparent_digest.in[k][j] <== outputs_digest[i][j];
        }
        k++;
    }
    // transparent_digest
    for (i = 0; i < 32; i++) {
        for (j = 0; j < 8; j++) {
            transparent_digest[i][j] <== hasher_transparent_digest.out[i][j];
        }
    }

    // T.2a: prevouts_digest 
    // A BLAKE2b-256 hash of the field encoding of all outpoint field values of transparent inputs to the transaction.
    // The personalization field of this hash is set to: "ZTxIdPrevoutHash"
    signal prevouts_digest[32][8];
    var personalization_prevouts_digest[16][8] = [[0, 1, 0, 1, 1, 0, 1, 0], [0, 1, 0, 1, 0, 1, 0, 0], [0, 1, 1, 1, 1, 0, 0, 0], [0, 1, 0, 0, 1, 0, 0, 1], [0, 1, 1, 0, 0, 1, 0, 0], [0, 1, 0, 1, 0, 0, 0, 0], [0, 1, 1, 1, 0, 0, 1, 0], [0, 1, 1, 0, 0, 1, 0, 1], [0, 1, 1, 1, 0, 1, 1, 0], [0, 1, 1, 0, 1, 1, 1, 1], [0, 1, 1, 1, 0, 1, 0, 1], [0, 1, 1, 1, 0, 1, 0, 0], [0, 1, 0, 0, 1, 0, 0, 0], [0, 1, 1, 0, 0, 0, 0, 1], [0, 1, 1, 1, 0, 0, 1, 1], [0, 1, 1, 0, 1, 0, 0, 0]];

    // T.2b: sequence_digest 
    // A BLAKE2b-256 hash of the 32-bit little-endian representation of all nSequence field values of transparent inputs to the transaction.
    // The personalization field of this hash is set to: "ZTxIdSequencHash"
    signal sequence_digest[32][8];
    var personalization_sequence_digest[16][8] = [[0, 1, 0, 1, 1, 0, 1, 0], [0, 1, 0, 1, 0, 1, 0, 0], [0, 1, 1, 1, 1, 0, 0, 0], [0, 1, 0, 0, 1, 0, 0, 1], [0, 1, 1, 0, 0, 1, 0, 0], [0, 1, 0, 1, 0, 0, 1, 1], [0, 1, 1, 0, 0, 1, 0, 1], [0, 1, 1, 1, 0, 0, 0, 1], [0, 1, 1, 1, 0, 1, 0, 1], [0, 1, 1, 0, 0, 1, 0, 1], [0, 1, 1, 0, 1, 1, 1, 0], [0, 1, 1, 0, 0, 0, 1, 1], [0, 1, 0, 0, 1, 0, 0, 0], [0, 1, 1, 0, 0, 0, 0, 1], [0, 1, 1, 1, 0, 0, 1, 1], [0, 1, 1, 0, 1, 0, 0, 0]];

    // T.2c: outputs_digest 
    // A BLAKE2b-256 hash of the concatenated field encodings of all transparent output values of the transaction. The field encoding of such an output consists of the encoded output amount (8-byte little endian) followed by the scriptPubKey byte array (serialized as Bitcoin script).
    // The personalization field of this hash is set to: "ZTxIdOutputsHash"
    signal outputs_digest[32][8];
    var personalization_outputs_digest[16][8] = [[0, 1, 0, 1, 1, 0, 1, 0], [0, 1, 0, 1, 0, 1, 0, 0], [0, 1, 1, 1, 1, 0, 0, 0], [0, 1, 0, 0, 1, 0, 0, 1], [0, 1, 1, 0, 0, 1, 0, 0], [0, 1, 0, 0, 1, 1, 1, 1], [0, 1, 1, 1, 0, 1, 0, 1], [0, 1, 1, 1, 0, 1, 0, 0], [0, 1, 1, 1, 0, 0, 0, 0], [0, 1, 1, 1, 0, 1, 0, 1], [0, 1, 1, 1, 0, 1, 0, 0], [0, 1, 1, 1, 0, 0, 1, 1], [0, 1, 0, 0, 1, 0, 0, 0], [0, 1, 1, 0, 0, 0, 0, 1], [0, 1, 1, 1, 0, 0, 1, 1], [0, 1, 1, 0, 1, 0, 0, 0]];

    // T.3: sapling_digest (OMITTED)
    // This digest is a BLAKE2b-256 hash of the following values
    // T.3a: sapling_spends_digest  (32-byte hash)
    // T.3b: sapling_outputs_digest (32-byte hash)
    // T.3c: valueBalance           (64-bit signed little-endian)
    // The personalization field of this hash is set to: "ZTxIdSaplingHash"
    // In the case that the transaction has no Sapling spends or outputs, sapling_digest is BLAKE2b-256("ZTxIdSaplingHash", [])
    signal sapling_digest[32][8];
    var personalization_sapling_digest[16][8] = [[0, 1, 0, 1, 1, 0, 1, 0], [0, 1, 0, 1, 0, 1, 0, 0], [0, 1, 1, 1, 1, 0, 0, 0], [0, 1, 0, 0, 1, 0, 0, 1], [0, 1, 1, 0, 0, 1, 0, 0], [0, 1, 0, 1, 0, 0, 1, 1], [0, 1, 1, 0, 0, 0, 0, 1], [0, 1, 1, 1, 0, 0, 0, 0], [0, 1, 1, 0, 1, 1, 0, 0], [0, 1, 1, 0, 1, 0, 0, 1], [0, 1, 1, 0, 1, 1, 1, 0], [0, 1, 1, 0, 0, 1, 1, 1], [0, 1, 0, 0, 1, 0, 0, 0], [0, 1, 1, 0, 0, 0, 0, 1], [0, 1, 1, 1, 0, 0, 1, 1], [0, 1, 1, 0, 1, 0, 0, 0]];
    // NOTE: we omit the input field of sapling for now, as we only consider orchard
    // signal sapling_spends_digest[32][8];
    // signal sapling_outputs_digest[32][8];
    component hasher_sapling_digest = blake2b(16);
    k = 0;
    for (i = 0; i < 16; i++) {
        for (j = 0; j < 8; j++) {
            hasher_sapling_digest[i][j] <== personalization_sapling_digest[k][j];
        }
        k++;
    }

    // T.4: orchard_digest 
    // In the case that Orchard actions are present in the transaction, this digest is a BLAKE2b-256 hash of the following values
    // T.4a: orchard_actions_compact_digest      (32-byte hash output)
    // T.4b: orchard_actions_memos_digest        (32-byte hash output)
    // T.4c: orchard_actions_noncompact_digest   (32-byte hash output)
    // T.4d: flagsOrchard                        (1 byte)
    // T.4e: valueBalanceOrchard                 (64-bit signed little-endian)
    // T.4f: anchorOrchard                       (32 bytes)
    // The personalization field of this hash is set to: "ZTxIdOrchardHash"
    // In the case that the transaction has no Orchard actions, orchard_digest is BLAKE2b-256("ZTxIdOrchardHash", [])
    signal orchard_digest[32][8];
    var personalization_orchard_digest[16][8] = [[0, 1, 0, 1, 1, 0, 1, 0], [0, 1, 0, 1, 0, 1, 0, 0], [0, 1, 1, 1, 1, 0, 0, 0], [0, 1, 0, 0, 1, 0, 0, 1], [0, 1, 1, 0, 0, 1, 0, 0], [0, 1, 0, 0, 1, 1, 1, 1], [0, 1, 1, 1, 0, 0, 1, 0], [0, 1, 1, 0, 0, 0, 1, 1], [0, 1, 1, 0, 1, 0, 0, 0], [0, 1, 1, 0, 0, 0, 0, 1], [0, 1, 1, 1, 0, 0, 1, 0], [0, 1, 1, 0, 0, 1, 0, 0], [0, 1, 0, 0, 1, 0, 0, 0], [0, 1, 1, 0, 0, 0, 0, 1], [0, 1, 1, 1, 0, 0, 1, 1], [0, 1, 1, 0, 1, 0, 0, 0]];

    // T.4a: orchard_actions_compact_digest 
    // A BLAKE2b-256 hash of the subset of Orchard Action information intended to be included in an updated version of the ZIP-307 8 CompactBlock format for all Orchard Actions belonging to the transaction. For each Action, the following elements are included in the hash:
    // T.4a.i  : nullifier            (field encoding bytes)
    // T.4a.ii : cmx                  (field encoding bytes)
    // T.4a.iii: ephemeralKey         (field encoding bytes)
    // T.4a.iv : encCiphertext[..52]  (First 52 bytes of field encoding)
    // The personalization field of this hash is set to: "ZTxIdOrcActCHash"
    signal orchard_actions_compact_digest[32][8];
    var personalization_orchard_actions_compact_digest[16][8] = [[0, 1, 0, 1, 1, 0, 1, 0], [0, 1, 0, 1, 0, 1, 0, 0], [0, 1, 1, 1, 1, 0, 0, 0], [0, 1, 0, 0, 1, 0, 0, 1], [0, 1, 1, 0, 0, 1, 0, 0], [0, 1, 0, 0, 1, 1, 1, 1], [0, 1, 1, 1, 0, 0, 1, 0], [0, 1, 1, 0, 0, 0, 1, 1], [0, 1, 0, 0, 0, 0, 0, 1], [0, 1, 1, 0, 0, 0, 1, 1], [0, 1, 1, 1, 0, 1, 0, 0], [0, 1, 0, 0, 0, 0, 1, 1], [0, 1, 0, 0, 1, 0, 0, 0], [0, 1, 1, 0, 0, 0, 0, 1], [0, 1, 1, 1, 0, 0, 1, 1], [0, 1, 1, 0, 1, 0, 0, 0]];

    // T.4b: orchard_actions_memos_digest 
    // A BLAKE2b-256 hash of the subset of Orchard shielded memo field data for all Orchard Actions belonging to the transaction. For each Action, the following elements are included in the hash:
    // T.4b.i: encCiphertext[52..564] (contents of the encrypted memo field)
    // The personalization field of this hash is set to: "ZTxIdOrcActMHash"
    signal orchard_actions_memos_digest[32][8];
    var personalization_orchard_actions_memos_digest[16][8] = [[0, 1, 0, 1, 1, 0, 1, 0], [0, 1, 0, 1, 0, 1, 0, 0], [0, 1, 1, 1, 1, 0, 0, 0], [0, 1, 0, 0, 1, 0, 0, 1], [0, 1, 1, 0, 0, 1, 0, 0], [0, 1, 0, 0, 1, 1, 1, 1], [0, 1, 1, 1, 0, 0, 1, 0], [0, 1, 1, 0, 0, 0, 1, 1], [0, 1, 0, 0, 0, 0, 0, 1], [0, 1, 1, 0, 0, 0, 1, 1], [0, 1, 1, 1, 0, 1, 0, 0], [0, 1, 0, 0, 1, 1, 0, 1], [0, 1, 0, 0, 1, 0, 0, 0], [0, 1, 1, 0, 0, 0, 0, 1], [0, 1, 1, 1, 0, 0, 1, 1], [0, 1, 1, 0, 1, 0, 0, 0]];

    // T.4c: orchard_actions_noncompact_digest 
    // A BLAKE2b-256 hash of the remaining subset of Orchard Action information not intended for inclusion in an updated version of the the ZIP 307 8 CompactBlock format, for all Orchard Actions belonging to the transaction. For each Action, the following elements are included in the hash:
    // T.4c.i  : cv                    (field encoding bytes)
    // T.4c.ii : rk                    (field encoding bytes)
    // T.4c.iii: encCiphertext[564..]  (post-memo suffix of field encoding)
    // T.4c.iv : outCiphertext         (field encoding bytes)
    // The personalization field of this hash is set to: "ZTxIdOrcActNHash"
    signal orchard_actions_noncompact_digest;
    var personalization_orchard_actions_noncompact_digest[16][8] = [[0, 1, 0, 1, 1, 0, 1, 0], [0, 1, 0, 1, 0, 1, 0, 0], [0, 1, 1, 1, 1, 0, 0, 0], [0, 1, 0, 0, 1, 0, 0, 1], [0, 1, 1, 0, 0, 1, 0, 0], [0, 1, 0, 0, 1, 1, 1, 1], [0, 1, 1, 1, 0, 0, 1, 0], [0, 1, 1, 0, 0, 0, 1, 1], [0, 1, 0, 0, 0, 0, 0, 1], [0, 1, 1, 0, 0, 0, 1, 1], [0, 1, 1, 1, 0, 1, 0, 0], [0, 1, 0, 0, 1, 1, 1, 0], [0, 1, 0, 0, 1, 0, 0, 0], [0, 1, 1, 0, 0, 0, 0, 1], [0, 1, 1, 1, 0, 0, 1, 1], [0, 1, 1, 0, 1, 0, 0, 0]];
    
}