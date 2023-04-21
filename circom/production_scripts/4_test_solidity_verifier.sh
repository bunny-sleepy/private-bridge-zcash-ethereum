NODE_PATH=./node/out/Release/node
SNARKJS_PATH=./snarkjs/cli.js
CIRCUIT_NAME=plonky2

# 4. test solidity verifier
echo "****SOLIDITY VERIFIER TEST****"
start=$(date +%s)
snarkjs generatecall --pub ./tests/data/public.json --proof ./tests/data/proof.json > ./output/solidity_public.txt
end=$(date +%s)
echo "DONE ($((end - start))s)"