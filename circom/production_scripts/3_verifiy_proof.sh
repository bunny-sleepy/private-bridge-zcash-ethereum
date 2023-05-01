SNARKJS_PATH=./snarkjs/cli.js
CIRCUIT_NAME=example
OUTPUT_PATH=./output

# 3. verify proof locally
echo "****VERIFYING PROOF****"
start=$(date +%s)
snarkjs groth16 verify ${OUTPUT_PATH}/verification_key.json ${OUTPUT_PATH}/public.json ${OUTPUT_PATH}/proof.json -v
end=$(date +%s)
echo "DONE ($((end - start))s)"