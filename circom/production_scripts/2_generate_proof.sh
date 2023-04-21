CIRCUIT_NAME=main
INPUT_PATH=./tests/data/proof.json
ZKEY_PATH=./powers_of_tau

# 2. proof generation using the zkey, witness and inputs
echo "****GENERATING PROOF****"
start=$(date +%s)
rapidsnark ${ZKEY_PATH}/"${CIRCUIT_NAME}".zkey ./witness.wtns ./tests/data/proof.json ./tests/data/public.json
end=$(date +%s)
echo "DONE ($((end - start))s)"