CIRCUIT_NAME=main
INPUT_PATH=./tests/data/proof.json
ZKEY_PATH=./powers_of_tau
RAPIDSNARK=./rapidsnark/build/prover
OUTPUT_PATH=./output

# 2. proof generation using the zkey, witness and inputs
echo "****GENERATING PROOF****"
start=$(date +%s)
${RAPIDSNARK} ${ZKEY_PATH}/"${CIRCUIT_NAME}".zkey ./witness.wtns ${OUTPUT_PATH}/proof.json ${OUTPUT_PATH}/public.json
end=$(date +%s)
echo "DONE ($((end - start))s)"