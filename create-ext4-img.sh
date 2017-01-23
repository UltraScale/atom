#!/bin/bash
TARGET_DIR_EXT4=$(pwd)/dist/ext4/

mkdir -p .dist

dd if=/dev/null of=dist/ext4.img  bs=1M seek=250
mkfs.ext4 -F dist/ext4.img
mkdir -p .mnt/ext4
sudo mount -t ext4 -o loop dist/ext4.img .mnt/ext4
sudo cp -r $TARGET_DIR_EXT4/*  .mnt/ext4/
sudo umount .mnt/ext4


