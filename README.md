# AtomOS

The Atom image is the minimalistic linux+systemd image to run kubernetes on.

First we are going to tune the experimental strategy and once all is working we are going to create an automation to generate the atom image. For finishing this stage we are going to improve the automation by adding optional packages and strip the binaries for decrease the image base.

**Important links:**

RBPi LFS: 
 
* http://www.intestinate.com/pilfs/guide.html
* http://www.intestinate.com/pilfs/scripts/ch5-build.sh
* http://www.intestinate.com/pilfs/scripts/ch6-build.sh

Kernel Compilation and Toolchain:
             
* https://www.raspberrypi.org/documentation/linux/kernel/building.md

Boot emulation: 

* http://raspberrypi.stackexchange.com/questions/165/emulation-on-a-linux-pc

Arch Linux Sample:

* http://mirrors.fe.up.pt/mirrors/downloads.raspberrypi.org/images/archlinuxarm/archlinuxarm-29-04-2012/archlinuxarm-29-04-2012.zip


## Development environment setup

```
sudo apt-get install bison gawk m4 texinfo flex automake libtool libtool-bin cvs ncurses-dev gperf help2man gettext bc qemu-system-arm
sudo apt-get install gcc-arm-linux-gnueabihf
sudo apt-get install build-essential libncurses5-dev
sudo apt-get install automake libtool bison flex texinfo
sudo apt-get install gawk curl cvs subversion gcj-jdk
sudo apt-get install libexpat1-dev python-dev
```

**Installing the toolchain**
```
git clone https://github.com/raspberrypi/tools ${HOME}/x-tools
```
Add this to  .bashrc
```
export PATH=${PATH}:${HOME}/x-tools/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian-x64/bin
```
Now you can cross compile using the ```--host=arm-linux-gnueabihf```



## Building the OS
```
├── dist
│   ├── ext4       : The system compilation fill this directory
│   ├── ext4.img   : Image created by the script create-ext4-img.sh
│   └── fat32      : The kernel compilation fill this directory
├── mnt            : Temporal directory used to generate ext4.img
├── sources        : This directory is used to download the sources and the builds
├── linux-kernel   : Temporal directory created by the script build-kernel to download and compile the linux kernel 
```


### Scripts

**build-kernel.sh:** Download the temporal directory ```linux-kernel```, then build and compile the kernel, save the results in ```dist/fat32``` and ```dist/ext4```

**build-system.sh:** Download the sources and build the linux system, save the result in ```dist/ext4```

**create-ext4-img.sh:** Take ```dist/ext4``` and creates the image file ```dist/ext4.img```

**pi-emulate.sh:**: Emulates a raspberry pi3 using the kernel located in ```dist/fat32
``` and the linux system in ```dist/ext4.img```

**strip_all.sh:** Delete all the build symbols in the binaries in ```dist/**```


**To stop the emulator:** Open another console and run ```killall qemu-system-arm```

## Test the emulator

Download the kernel and the image:
```
wget http://mirrors.fe.up.pt/mirrors/downloads.raspberrypi.org/images/archlinuxarm/archlinuxarm-29-04-2012/archlinuxarm-29-04-2012.zip
unzip archlinuxarm-29-04-2012.zip
wget http://dl.dropbox.com/u/45842273/zImage
```

Run the emulator:
```
qemu-system-arm  -curses -kernel zImage  -cpu arm1176 -M versatilepb -serial stdio -append "root=/dev/sda2" -hda  archlinuxarm-29-04-2012/archlinuxarm-29-04-2012.img -clock dynticks
```


# TODO
```
[] Install bash in the linux system
[] Install systemd in the linux system
[] Try to boot my image in the qemu emulator 
```


# IDEAS

Recursive make

```
SUBDIRS = foo bar baz

.PHONY: subdirs $(SUBDIRS)

subdirs: $(SUBDIRS)

$(SUBDIRS):
        $(MAKE) -C $@

foo: baz
```
