CIRCUIT_NAME=example
ORDER=19
POT_PATH=./powers_of_tau/powersOfTau19


# 2.5. init powers of tau 
echo "****CREATE POWERS OF TAU****"
start=`date +%s`
snarkjs powersoftau new bn128 ${ORDER} ${POT_PATH}_${ORDER}_0.ptau -v
snarkjs powersoftau prepare phase2 ${POT_PATH}_${ORDER}_0.ptau ${POT_PATH}_${ORDER}.ptau -v
end=`date +%s`
echo "DONE ($((end-start))s)"