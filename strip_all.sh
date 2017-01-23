#!/bin/bash
TARGET_DIR_EXT4=$(pwd)/dist/ext4/

find $TARGET_DIR_EXT4 -type f -name \*.ko \
   -exec arm-linux-gnueabihf-strip --strip-debug {} ';'

find $TARGET_DIR_EXT4/usr/lib -type f -name \*.a \
   -exec arm-linux-gnueabihf-strip --strip-debug {} ';'
find $TARGET_DIR_EXT4/lib $TARGET_DIR_EXT4/usr/lib -type f -name \*.so* \
   -exec arm-linux-gnueabihf-strip --strip-unneeded {} ';'
find $TARGET_DIR_EXT4/{bin,sbin} $TARGET_DIR_EXT4/usr/{bin,sbin,libexec} -type f \
    -exec arm-linux-gnueabihf-strip --strip-all {} ';'
