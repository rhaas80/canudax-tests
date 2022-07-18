#!/bin/bash
set -e -x

export SCRIPTSPACE=$PWD/scripts
export WORKSPACE=$PWD/workspace
export PAGESSPACE=$PWD/gh-pages
mkdir -p $WORKSPACE
cd $WORKSPACE

# get a checkout of the gh-pages branch
cp -rl $SCRIPTSPACE $PAGESSPACE
( cd $PAGESSPACE && git checkout gh-pages )

# get a checkout of CarpetX

curl -kLO https://raw.githubusercontent.com/gridaphobe/CRL/master/GetComponents
chmod a+x GetComponents
./GetComponents --no-parallel --shallow https://bitbucket.org/eschnett/cactusamrex/raw/master/azure-pipelines/carpetx.th

cd Cactus
./simfactory/bin/sim setup-silent --optionlist repos/cactusamrex/azure-pipelines/debian.cfg

time ./simfactory/bin/sim build --thornlist repos/cactusamrex/carpetx.th 2>&1 | tee build.log

time ./simfactory/bin/sim create-run TestJob01_temp_1 --cores 1 --num-threads 2 --testsuite --testsuite-tests=CarpetX

time ./simfactory/bin/sim create-run TestJob01_temp_2 --cores 2 --num-threads 1 --testsuite --testsuite-tests=CarpetX

# parse results, generate plots

cd $PAGESSPACE
python3 $SCRIPTSPACE/bin/store.py

python3 $SCRIPTSPACE/bin/logpage.py
