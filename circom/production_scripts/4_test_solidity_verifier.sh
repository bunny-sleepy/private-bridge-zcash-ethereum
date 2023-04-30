SNARKJS_PATH=./snarkjs/cli.js
CIRCUIT_NAME=example
OUTPUT_PATH=./output

# 4. test solidity verifier
echo "****SOLIDITY VERIFIER TEST****"
start=$(date +%s)
snarkjs generatecall --pub ${OUTPUT_PATH}/public.json --proof ${OUTPUT_PATH}/proof.json > ./output/solidity_public.out
end=$(date +%s)
echo "DONE ($((end - start))s)"