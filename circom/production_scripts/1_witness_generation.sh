CIRCUIT_NAME=main
INPUT_PATH=./tests/data/proof.json

# 1. generate witness
echo "****WITNESS GENERATION****"
start=$(date +%s)
./${CIRCUIT_NAME}_cpp/${CIRCUIT_NAME} ${INPUT_PATH} ./witness.wtns
end=$(date +%s)
echo "DONE ($((end - start))s)"