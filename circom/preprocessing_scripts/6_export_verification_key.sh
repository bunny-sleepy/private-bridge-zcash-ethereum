CIRCUIT_NAME=example
ZKEY_PATH=./powers_of_tau

# 6. export verification key
echo "****EXPORTING VKEY****"
start=$(date +%s)
snarkjs zkey export verificationkey ${ZKEY_PATH}/"${CIRCUIT_NAME}".zkey ./output/verification_key.json -v
end=$(date +%s)
echo "DONE ($((end - start))s)"