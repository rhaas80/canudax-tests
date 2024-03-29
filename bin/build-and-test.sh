#!/bin/bash
set -e -x

export SCRIPTSPACE=$PWD/scripts
export WORKSPACE=$PWD/workspace
export PAGESSPACE=$PWD/gh-pages
mkdir -p $WORKSPACE
cd $WORKSPACE

# TODO: add code to detect and report:
# - build failures
# - checkout failures
# - failures in this script
# - failures in Pythhon code (as much as possible)

# get a checkout of CanudaX
wget https://raw.githubusercontent.com/gridaphobe/CRL/master/GetComponents
chmod a+x GetComponents
# CanudaX does not have a self-contained thornlist, so I inject it into CarpetX
./GetComponents --no-parallel --shallow https://bitbucket.org/canuda/canudax_lean/raw/master/CanudaX.th
# unshallow canudax_lean repo
( cd Cactus/repos/canudax_lean && git fetch --unshallow && echo "At git ref: $(git rev-parse HEAD)" )


cd Cactus
./simfactory/bin/sim setup-silent --optionlist repos/cactusamrex/azure-pipelines/debian.cfg

# for Formaline, do not use git config --global since it overwrites the user's
# own .gitrc file if the script is run outside a container
export GIT_AUTHOR_EMAIL="maintainers@einsteintoolkit.org"
export GIT_AUTHOR_NAME="Github runner"
export GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"
export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME"

NCPUS=$(nproc)
time ./simfactory/bin/sim build -j$NCPUS --thornlist thornlists/CanudaX.th 2>&1 | tee build.log

# somehow /usr/local/lib is not in the search path
export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
# OpenMPI does not like to run as root (even in a container)
export OMPI_ALLOW_RUN_AS_ROOT=1
export OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1
time ./simfactory/bin/sim create-run TestJob01_temp_1 --cores 1 --num-threads 2 --testsuite --select-tests="CanudaX_Lean/CanudaX_BSSNMoL"
ONEPROC_DIR="$(./simfactory/bin/sim get-output-dir TestJob01_temp_1)/TEST/sim"

time ./simfactory/bin/sim create-run TestJob01_temp_2 --cores 2 --num-threads 1 --testsuite --select-tests="CanudaX_Lean/CanudaX_BSSNMoL"
TWOPROC_DIR="$(./simfactory/bin/sim get-output-dir TestJob01_temp_2)/TEST/sim"

# parse results, generate plots
cd $PAGESSPACE
python3 $SCRIPTSPACE/bin/store.py $WORKSPACE/Cactus/repos/canudax_lean $ONEPROC_DIR $TWOPROC_DIR

python3 $SCRIPTSPACE/bin/logpage.py $WORKSPACE/Cactus/repos/canudax_lean

# store HTML results
git add docs
git add records
git add test_nums.csv
if git commit -m "updated html file" ; then
  git push
fi
