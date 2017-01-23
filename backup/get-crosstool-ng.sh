#!/bin/bash
###http://crosstool-ng.org
CROSSTOOL_VERSION=1.22.0
TOOLCHAIN_DIR=$(pwd)/crosstool-ng
rm -rf crosstool-ng
mkdir -p crosstool-ng
cd /tmp
mkdir tmpcrosstool
cd tmpcrosstool
rm -f crosstool-ng-${CROSSTOOL_VERSION}.tar.*
wget http://crosstool-ng.org/download/crosstool-ng/crosstool-ng-${CROSSTOOL_VERSION}.tar.bz2
tar xjf crosstool-ng-${CROSSTOOL_VERSION}.tar.bz2
cd crosstool-ng
./configure --prefix=${TOOLCHAIN_DIR}
make
make install
echo "export PATH="${PATH}:${TOOLCHAIN_DIR}/bin""
cd ../..



