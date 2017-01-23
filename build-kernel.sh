#!/bin/bash
set -x

TARGET_DIR_EXT4=$(pwd)/dist/ext4/
TARGET_DIR_FAT32=$(pwd)/dist/fat32/

rm -rf $TARGET_DIR_FAT32
mkdir -p $TARGET_DIR_FAT32/overlays/

git clone --depth=1 https://github.com/raspberrypi/linux linux-kernel
cd linux-kernel

echo "# Building the kernel and modules"

## FOR Pi 1
#KERNEL=kernel
#make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- bcmrpi_defconfig

## FOR Pi 2/3
KERNEL=kernel7
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- bcm2709_defconfig

##FOR ALL Pi
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- zImage modules dtbs


echo "# Intall the kernel and modules"
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- INSTALL_MOD_PATH=$TARGET_DIR_EXT4 modules_install

#scripts/mkknlimg arch/arm/boot/zImage $TARGET_DIR_FAT32/zImage
cp arch/arm/boot/zImage $TARGET_DIR_FAT32/zImage
cp -v arch/arm/boot/dts/*.dtb $TARGET_DIR_FAT32
cp -v arch/arm/boot/dts/overlays/*.dtb* $TARGET_DIR_FAT32/overlays/
cp -v arch/arm/boot/dts/overlays/README $TARGET_DIR_FAT32/overlays/
cd ..
