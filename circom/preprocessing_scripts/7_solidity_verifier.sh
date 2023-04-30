CIRCUIT_NAME=example
ZKEY_PATH=./powers_of_tau

# 7. generate solidity verifier file, DONE (1s)
echo "****GENERATE SOLIDITY VERIFIER****"
start=$(date +%s)
snarkjs zkey export solidityverifier ${ZKEY_PATH}/"${CIRCUIT_NAME}".zkey ./solidity/contracts/verifier.sol
end=$(date +%s)
echo "DONE ($((end - start))s)"