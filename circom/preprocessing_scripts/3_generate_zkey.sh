CIRCUIT_NAME=example
ORDER=19
POT_PATH=./powers_of_tau/powersOfTau28_hez_final
ZKEY_PATH=./powers_of_tau

# 3. generate zkey_0 without contribution
echo "****GENERATING ZKEY 0 WITHOUT CONTRIBUTING TO PHASE 2 CEREMONY****"
# If failed: https://hackmd.io/@yisun/BkT0RS87q
start=$(date +%s)
snarkjs zkey new $CIRCUIT_NAME.r1cs ${POT_PATH}_${ORDER}.ptau ${ZKEY_PATH}/"$CIRCUIT_NAME"_0.zkey -v > ./output/zkey0.out
end=$(date +%s)
echo "DONE ($((end - start))s)"