pragma circom 2.0.0;

include "./sha256d.circom";

// Use this to check that the tx hashes correctly to the txhash
template zcash_tx_check() {
    signal input txhash[256];

    // All the tx data 
    // ? Add the size of each field
    signal input header[4*8];
    signal input nVersionGroupId[4*8];
    signal input nConsensusBranchId[4*8];
    signal input nLockTime[4*8];
    signal input nExpiryHeight[4*8];

    signal input tx_in_count;
    signal input tx_in;
    signal input tx_out_count;
    signal input tx_out;

    signal input nSpendsSapling;
    signal input nOutputsSapling;

    signal input nActionsOrchard;
    signal input vActionsOrchard;
    signal input flagsOrchard[1*8];
    signal input valueBalanceOrchard[8*8];
    signal input anchorOrchard[32*8];
    signal input sizeProofsOrchard;
    signal input proofsOrchard;
    signal input vSpendAuthSigsOrchard;
    signal input bindingSigOrchard;




}