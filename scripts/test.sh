#!/bin/bash

set -ex

export CANUDAXSPACE="$PWD"
export WORKSPACE="$PWD/../workspace"
export PAGESSPACE="$PWD/gh-pages"
mkdir -p "$WORKSPACE"
cd "$WORKSPACE"

cd Cactus

# Somehow /usr/local/lib is not in the search path
export LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH"
# OpenMPI does not like to run as root (even in a container)
export OMPI_ALLOW_RUN_AS_ROOT=1
export OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1

time ./simfactory/bin/sim --machine="actions-$ACCELERATOR-$REAL_PRECISION" create-run TestJob01_temp_1 --cores 1 --num-threads 2 --testsuite --select-tests=CanudaX_Lean
ONEPROC_DIR="$(./simfactory/bin/sim --machine="actions-$ACCELERATOR-$REAL_PRECISION" get-output-dir TestJob01_temp_1)/TEST/sim"

# time ./simfactory/bin/sim --machine="actions-$ACCELERATOR-$REAL_PRECISION" create-run TestJob01_temp_2 --cores 2 --num-threads 1 --testsuite --select-tests=CanudaX_Lean
# TWOPROC_DIR="$(./simfactory/bin/sim --machine="actions-$ACCELERATOR-$REAL_PRECISION" get-output-dir TestJob01_temp_2)/TEST/sim"

# # Parse results and generate plots
# cd "$PAGESSPACE"
# python3 "$CANUDAXSPACE/scripts/store.py" "$WORKSPACE/Cactus/repos/canudax_lean" "$ONEPROC_DIR"
# python3 "$CANUDAXSPACE/scripts/logpage.py" "$WORKSPACE/Cactus/repos/canudax_lean"
# 
# # Store HTML results
# git add docs
# git add records
# git add test_nums.csv
# git commit -m "Add new test result" && git push

# Show all log, output, and error files
echo 'All log files:'
echo '================================================================================'
for logfile in $(find "${ONEPROC_DIR}" -name '*.log' -print); do
    echo "Log file $logfile:"
    ls -l "$logfile"
    cat "$logfile"
    echo '================================================================================'
done
echo 'All output files:'
echo '================================================================================'
for outfile in $(find "${ONEPROC_DIR}/../.." -name '*.out' -print); do
    echo "Output file $outfile:"
    ls -l "$outfile"
    cat "$outfile"
    echo '================================================================================'
done
echo 'All error files:'
echo '================================================================================'
for errfile in $(find "${ONEPROC_DIR}/../.." -name '*.err' -print); do
    echo "Error file $errfile:"
    ls -l "$errfile"
    cat "$errfile"
    echo '================================================================================'
done

TESTS_FAILED=False
for test_dir in "${ONEPROC_DIR}"; do
    log="${test_dir}/summary.log"
    if ! grep -q '^    Number failed            -> 0$' ${log}; then
        TESTS_FAILED=True
    fi
done
echo "TESTS_FAILED=${TESTS_FAILED}" >>"${GITHUB_ENV}"
