CIRCUIT_NAME=plonky2
ZKEY_PATH=./powers_of_tau

# 4. contribute to trusted setup ceremony
echo "****CONTRIBUTE TO PHASE 2 CEREMONY****"
start=`date +%s`
snarkjs zkey contribute -verbose ${ZKEY_PATH}/"$CIRCUIT_NAME"_0.zkey ${ZKEY_PATH}/"$CIRCUIT_NAME".zkey -n="First phase2 contribution" -e="CipherSquad" > ./output/contribute.out
end=`date +%s`
echo "DONE ($((end-start))s)"