#!/bin/bash
set -e -x

export SCRIPTSPACE=$PWD/scripts
export WORKSPACE=$PWD/workspace
export PAGESSPACE=$PWD/gh-pages
mkdir -p $WORKSPACE
cd $WORKSPACE

# get a checkout of the gh-pages branch
cp -ra $SCRIPTSPACE $PAGESSPACE
( cd $PAGESSPACE && git checkout -f gh-pages )

# get a checkout of CarpetX

wget https://raw.githubusercontent.com/gridaphobe/CRL/master/GetComponents
chmod a+x GetComponents
./GetComponents --no-parallel --shallow https://bitbucket.org/eschnett/cactusamrex/raw/master/azure-pipelines/carpetx.th
# unshallow carpetx repo
( cd Cactus/repos/cactusamrex && git fetch --unshallow )


cd Cactus
./simfactory/bin/sim setup-silent --optionlist repos/cactusamrex/azure-pipelines/debian.cfg

NCPUS=$(nproc)
time ./simfactory/bin/sim build -j$NCPUS --thornlist repos/cactusamrex/azure-pipelines/carpetx.th 2>&1 | tee build.log

# somehow /usr/local/lib is not in the search path
export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
time ./simfactory/bin/sim create-run TestJob01_temp_1 --cores 1 --num-threads 2 --testsuite --select-tests=CarpetX

time ./simfactory/bin/sim create-run TestJob01_temp_2 --cores 2 --num-threads 1 --testsuite --select-tests=CarpetX

# parse results, generate plots

cd $PAGESSPACE
python3 $SCRIPTSPACE/bin/store.py $WORKSPACE/Cactus/repos/cactusamrex

python3 $SCRIPTSPACE/bin/logpage.py $WORKSPACE/Cactus/repos/cactusamrex
