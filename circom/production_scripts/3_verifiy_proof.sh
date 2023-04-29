NODE_PATH=./node/out/Release/node
SNARKJS_PATH=./snarkjs/cli.js
CIRCUIT_NAME=plonky2
OUTPUT_PATH=./output

# 3. verify proof locally
echo "****VERIFYING PROOF****"
start=$(date +%s)
snarkjs groth16 verify ./output/verification_key.json ${OUTPUT_PATH}/proof.json ${OUTPUT_PATH}/public.json -v
end=$(date +%s)
echo "DONE ($((end - start))s)"