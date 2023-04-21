CIRCUIT_NAME=main
ORDER=19
POT_PATH=./powers_of_tau/powersOfTau28_hez_final


# 2.5. init powers of tau 
echo "****CREATE POWERS OF TAU****"
start=`date +%s`
snarkjs powersoftau new bn128 25 ${POT_PATH}_${ORDER}.ptau -v
end=`date +%s`
echo "DONE ($((end-start))s)"