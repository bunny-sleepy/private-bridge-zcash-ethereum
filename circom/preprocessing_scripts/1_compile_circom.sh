CIRCUIT_PATH=./circuits/main.circom

# 1. compile the circom circuit
echo "****COMPILING CIRCUIT****"
start=$(date +%s)
# Note: we use O0 optimization to reduce circuit size
circom ${CIRCUIT_PATH} --c --r1cs --sym
end=$(date +%s)
echo "DONE ($((end - start))s)"