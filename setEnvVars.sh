#!/usr/bin/env sh
# QUIP Stuff
export QUIP_ARCH=linux_x86_64_gfortran
export QUIP_INSTALLDIR=$CONDA_PREFIX/bin
export QUIP_STRUCTS_DIR=$PWD/structs
export PATH=$PATH:$QUIP_INSTALLDIR
export QUIP_ROOT="$(pwd)/QUIP"
export QGIT="$(pwd)"
unset SOURCE_DATE_EPOCH
export LD_LIBRARY_PATH=$CONDA_PREFIX/lib64:$LD_LIBRARY_PATH
# quippy Stuff
export QUIPPY_INSTALL_OPTS="--prefix $CONDA_PREFIX"
# pkg-config stuff
export MATH_LINKOPTS="$(pkg-config --libs openblas)"
