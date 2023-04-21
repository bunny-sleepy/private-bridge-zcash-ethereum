CIRCUIT_NAME=plonky2
ORDER=19
POT_PATH=./powers_of_tau/powersOfTau28_hez_final
ZKEY_PATH=./powers_of_tau


# 5. verify contributed zkey for production
echo "****VERIFYING FINAL ZKEY (SKIP FOR TESTING)****"
start=$(date +%s)
snarkjs zkey verify -verbose "$CIRCUIT_NAME".r1cs ${POT_PATH}_${ORDER}.ptau ${ZKEY_PATH}/"$CIRCUIT_NAME".zkey > ./output/verify.out
end=$(date +%s)
echo "DONE ($((end - start))s)"