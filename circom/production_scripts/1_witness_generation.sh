CIRCUIT_NAME=example
INPUT_PATH=./input.json

# 1. generate witness
echo "****WITNESS GENERATION****"
start=$(date +%s)
./${CIRCUIT_NAME}_cpp/${CIRCUIT_NAME} ${INPUT_PATH} ./witness.wtns
end=$(date +%s)
echo "DONE ($((end - start))s)"