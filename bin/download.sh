#!/bin/bash

set -ex

export CANUDAXSPACE="$PWD"
export WORKSPACE="$PWD/../workspace"
mkdir -p "$WORKSPACE"
cd "$WORKSPACE"

# Check out Cactus
wget https://raw.githubusercontent.com/gridaphobe/CRL/master/GetComponents
chmod a+x GetComponents
./GetComponents --no-parallel --shallow https://bitbucket.org/canuda/canudax_lean/raw/master/CanudaX.th

cd Cactus

# Create a link to the CanudaX_Lean repository
ln -s "$CANUDAXSPACE" repos
# Create links for the CanudaX_Lean
mkdir -p arrangements/CanudaX_Lean
pushd arrangements/CanudaX_Lean
ln -s ../../repos/canudax_lean
popd
