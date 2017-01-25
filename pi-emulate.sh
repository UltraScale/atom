#!/bin/bash
set -x
TARGET_DIR_FAT32=$(pwd)/dist/fat32/

KERNEL=qemu-zimage/zImage
IMAGE=archlinuxarm-29-04-2012/archlinuxarm-29-04-2012.img
MY_IMAGE=dist/ext4.img


#### FOR ARCH IMAGE ####
#qemu-system-arm  -nographic -serial mon:stdio  -kernel $KERNEL  -cpu arm1176 -M versatilepb  -append "root=/dev/sda2 console=ttyS0,115200n8 console=tty0 debug loglevel=7 panic=1 rootfstype=ext4 rw" -hda $IMAGE  -clock dynticks

qemu-system-arm  -nographic -serial mon:stdio  -kernel $KERNEL  -cpu arm1176 -M versatilepb  -append "root=/dev/hda1 console=ttyS0,115200n8 console=tty0 debug loglevel=7 panic=1 rootfstype=ext4 rw init=/bin/bash" -hda $MY_IMAGE  -clock dynticks


