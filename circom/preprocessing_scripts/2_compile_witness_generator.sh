CIRCUIT_NAME=main

# 2. compile witness generator
echo "****COMPILING WITNESS GENERATOR****"
start=$(date +%s)
cd ${CIRCUIT_NAME}_cpp && make -j && cd ..
end=$(date +%s)
echo "DONE ($((end - start))s)"