#!/bin/bash
#
# PiLFS Build Script SVN-20161203 v1.0
# Builds chapters 6.7 - Raspberry Pi Linux API Headers to 6.70 - Vim
# http://www.intestinate.com/pilfs
#
# Optional parameteres below:
LFS_TGT=arm-linux-gnueabihf
TARGET_DIR=$(pwd)/dist/ext4/
PARALLEL_JOBS=1                 # Number of parallel make jobs, 1 for RPi1 and 4 for RPi2 and RPi3 recommended.
LOCAL_TIMEZONE=Europe/London    # Use this timezone from /usr/share/zoneinfo/ to set /etc/localtime. See "6.9.2. Configuring Glibc".
GROFF_PAPER_SIZE=A4             # Use this default paper size for Groff. See "6.52. Groff-1.22.3".
INSTALL_OPTIONAL_DOCS=0         # Install optional documentation when given a choice?
INSTALL_ALL_LOCALES=0           # Install all glibc locales? By default only en_US.ISO-8859-1 and en_US.UTF-8 are installed.
INSTALL_SYSTEMD_DEPS=1          # Install optional systemd dependencies? (Attr, Acl, Libcap, Expat, XML::Parser & Intltool)

# End of optional parameters
set -x
set -o nounset
set -o errexit

mkdir -p $TARGET_DIR/{var,lib,etc,bin,usr,root,sbin}
mkdir -p $TARGET_DIR/usr/include

function prebuild_sanity_check {
    
    if ! [[ -d ./sources ]] ; then
        echo "Can't find your sources directory!"
        exit 1
    fi

    if ! [[ -d ${HOME}/x-tools/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian-x64/bin ]] ; then
        echo "No toolchain istalled in ${HOME}/x-tools"
        exit 1
    fi

}

function check_tarballs {
LIST_OF_TARBALLS="
#vim-8.0.069.tar.bz2
#master.tar.gz
"

#for tarball in $LIST_OF_TARBALLS ; do
#    if ! [[ -f ./sources/$tarball ]] ; then
#        echo "Can't find /sources/$tarball!"
#        exit 1
#    fi
#done
}

function timer {
    if [[ $# -eq 0 ]]; then
        echo $(date '+%s')
    else
        local stime=$1
        etime=$(date '+%s')
        if [[ -z "$stime" ]]; then stime=$etime; fi
        dt=$((etime - stime))
        ds=$((dt % 60))
        dm=$(((dt / 60) % 60))
        dh=$((dt / 3600))
        printf '%02d:%02d:%02d' $dh $dm $ds
    fi
}

prebuild_sanity_check
check_tarballs

total_time=$(timer)

echo "# Downloding the sources"
cd sources
bash -c "wget -c -nc -i ../wget-list"
cd ..


## SKIP
if false; then
echo ""
fi ### SKIP


echo "# 6.7. Raspberry Pi Linux API Headers"
cd sources
rm -rf linux-rpi-4.4.y
tar -zxf rpi-4.4.y.tar.gz
cd linux-rpi-4.4.y
make mrproper
make INSTALL_HDR_PATH=dest headers_install
find dest/include \( -name .install -o -name ..install.cmd \) -delete
cp -rv dest/include/* $TARGET_DIR/usr/include
cd ../..






echo "# 6.9. Glibc-2.24"
rm -f $TARGET_DIR/usr/lib/ld-linux*
rm -f $TARGET_DIR/lib/ld-linux*
cd sources
tar -Jxf glibc-2.24.tar.xz
cd glibc-2.24
patch -Np1 -i ../glibc-2.24-fhs-1.patch
rm -rf build
mkdir -vp build
cd build

             ##--with-headers=$TARGET_DIR/usr/include \

../configure --prefix=$TARGET_DIR/usr      \
             --host=$LFS_TGT           \
             --enable-kernel=2.6.32 \
             --enable-obsolete-rpc
make -j $PARALLEL_JOBS
touch $TARGET_DIR/etc/ld.so.conf
make install
cp -v ../nscd/nscd.conf $TARGET_DIR/etc/nscd.conf
mkdir -pv $TARGET_DIR/var/cache/nscd

## TODO ## 
#if [[ $INSTALL_ALL_LOCALES = 1 ]] ; then
#    make localedata/install-locales
#else
#    mkdir -pv $TARGET_DIR/usr/lib/locale
#    localedef -i en_US -f ISO-8859-1 en_US
#    localedef -i en_US -f UTF-8 en_US.UTF-8
#fi
cat > $TARGET_DIR/etc/nsswitch.conf << "EOF"
# Begin /etc/nsswitch.conf

passwd: files
group: files
shadow: files

hosts: files dns
networks: files

protocols: files
services: files
ethers: files
rpc: files

# End /etc/nsswitch.conf
EOF
tar -zxf ../../tzdata2016j.tar.gz
ZONEINFO=$TARGET_DIR/usr/share/zoneinfo
mkdir -pv $ZONEINFO/{posix,right}
for tz in etcetera southamerica northamerica europe africa antarctica  \
          asia australasia backward pacificnew systemv; do
    zic -L /dev/null   -d $ZONEINFO       -y "sh yearistype.sh" ${tz}
    zic -L /dev/null   -d $ZONEINFO/posix -y "sh yearistype.sh" ${tz}
    zic -L leapseconds -d $ZONEINFO/right -y "sh yearistype.sh" ${tz}
done
cp -v zone.tab zone1970.tab iso3166.tab $ZONEINFO
zic -d $ZONEINFO -p America/New_York
unset ZONEINFO
if ! [[ -f $TARGET_DIR/usr/share/zoneinfo/$LOCAL_TIMEZONE ]] ; then
    echo "Seems like your timezone won't work out. Defaulting to London. Either fix it yourself later or consider moving there :)"
    cp -v $TARGET_DIR/usr/share/zoneinfo/Europe/London $TARGET_DIR/etc/localtime
else
    cp -v $TARGET_DIR/usr/share/zoneinfo/$LOCAL_TIMEZONE $TARGET_DIR/etc/localtime
fi
cat > $TARGET_DIR/etc/ld.so.conf << "EOF"
# Begin /etc/ld.so.conf
/usr/local/lib
/opt/lib

EOF
cat >> $TARGET_DIR/etc/ld.so.conf << "EOF"
# Add an include directory
include /etc/ld.so.conf.d/*.conf

EOF
mkdir -pv $TARGET_DIR/etc/ld.so.conf.d
# Compatibility symlink for non ld-linux-armhf awareness


ln -sv ld-2.24.so $TARGET_DIR/usr/lib/ld-linux.so.3
ln -sv ../usr/lib/ld-2.24.so $TARGET_DIR/lib/ld-linux-armhf.so.3
ln -sv ../usr/lib/ld-2.24.so $TARGET_DIR/lib/ld-linux.so.3
cd ../..
rm -rf glibc-2.24
cd ..





echo "# 6.20. Ncurses-6.0"
echo "Removing previously installed libraries"
for lib in ncurses form panel menu ; do
    rm -vf                    $TARGET_DIR/usr/lib/lib${lib}.so
    rm -vf                    $TARGET_DIR/usr/lib/lib${lib}w.so
done
cd sources
rm -rf ncurses-6.0
tar -zxf ncurses-6.0.tar.gz
cd ncurses-6.0
sed -i '/LIBTOOL_INSTALL/d' c++/Makefile.in
./configure --prefix=$TARGET_DIR/usr           \
            --host=$LFS_TGT           \
            --with-shared           \
            --without-debug         \
            --without-normal        \
            --enable-pc-files       \
            --enable-widec         \
            LDFLAGS=-L$TARGET_DIR/usr/lib  \
            CPPFLAGS="-P"
make -j $PARALLEL_JOBS

rm -rf $TARGET_DIR/usr/lib/libncursesw.so
rm -rf $TARGET_DIR/lib/libncursesw.so

CPPFLAGS="-P" make install
mv -v $TARGET_DIR/usr/lib/libncursesw.so.6* $TARGET_DIR/lib
echo "RECREATING LINK: " 
ln -sfv ../../lib/$(readlink $TARGET_DIR/usr/lib/libncursesw.so) $TARGET_DIR/usr/lib/libncursesw.so
for lib in ncurses form panel menu ; do
    rm -vf                    $TARGET_DIR/usr/lib/lib${lib}.so
    echo "INPUT(-l${lib}w)" > $TARGET_DIR/usr/lib/lib${lib}.so
    ln -sfv ${lib}w.pc        $TARGET_DIR/usr/lib/pkgconfig/${lib}.pc || true
done
rm -vf                     $TARGET_DIR/usr/lib/libcursesw.so
echo "INPUT(-lncursesw)" > $TARGET_DIR/usr/lib/libcursesw.so
ln -sfv libncurses.so      $TARGET_DIR/usr/lib/libcurses.so
rm -rf $TARGET_DIR/usr/share/man
cd ..
rm -rf ncurses-6.0
cd ..


echo "# 6.32. Readline-7.0"

rm -f $TARGET_DIR/lib/libreadline.so.7
rm -f $TARGET_DIR/lib/libhistory.so.7
cd sources
tar -zxf readline-7.0.tar.gz
cd readline-7.0
sed -i '/MV.*old/d' Makefile.in
sed -i '/{OLDSUFF}/c:' support/shlib-install
./configure --prefix=$TARGET_DIR/usr   \
            --disable-static \
            --host=$LFS_TGT \
            LDFLAGS=-L$TARGET_DIR/usr/lib  \
            --docdir=$TARGET_DIR/usr/share/doc/readline-7.0 
make -j $PARALLEL_JOBS SHLIB_LIBS=-lncurses
make SHLIB_LIBS=-lncurses install
mv -v $TARGET_DIR/usr/lib/lib{readline,history}.so.* $TARGET_DIR/lib
ln -sfv ../../lib/$(readlink $TARGET_DIR/usr/lib/libreadline.so) $TARGET_DIR/usr/lib/libreadline.so
ln -sfv ../../lib/$(readlink $TARGET_DIR/usr/lib/libhistory.so ) $TARGET_DIR/usr/lib/libhistory.so
cd ..
rm -rf readline-7.0
cd ..





echo "# 6.33. Bash-4.4"
cd sources
tar -zxf bash-4.4.tar.gz
cd bash-4.4
./configure --prefix=$TARGET_DIR/usr                    \
            --docdir=$TARGET_DIR/usr/share/doc/bash-4.4 \
            --without-bash-malloc            \
            --with-installed-readline        \
            LDFLAGS=-L$TARGET_DIR/usr/lib  \
            --host=$LFS_TGT           
make -j $PARALLEL_JOBS
make install
mv -vf $TARGET_DIR/usr/bin/bash $TARGET_DIR/bin
# exec /bin/bash --login +h
# Don't know of a good way to keep running the script after entering bash here.
cd ..
rm -rf bash-4.4
cd ..


exit 0
######## HERE ############################################



if [[ $INSTALL_SYSTEMD_DEPS = 1 ]] ; then
echo "6.22. Acl-2.2.52"
tar -zxf acl-2.2.52.src.tar.gz
cd acl-2.2.52
sed -i -e 's|/@pkg_name@|&-@pkg_version@|' include/builddefs.in
sed -i "s:| sed.*::g" test/{sbits-restore,cp,misc}.test
sed -i -e "/TABS-1;/a if (x > (TABS-1)) x = (TABS-1);" libacl/__acl_to_any_text.c
./configure --prefix=/usr \
            --bindir=/bin \
            --disable-static \
            --libexecdir=/usr/lib
make -j $PARALLEL_JOBS
make install install-dev install-lib
chmod -v 755 /usr/lib/libacl.so
mv -vf /usr/lib/libacl.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libacl.so) /usr/lib/libacl.so
cd /sources
rm -rf acl-2.2.52
fi

if [[ $INSTALL_SYSTEMD_DEPS = 1 ]] ; then
echo "6.23. Libcap-2.25"
tar -Jxf libcap-2.25.tar.xz
cd libcap-2.25
sed -i '/install.*STALIBNAME/d' libcap/Makefile
make -j $PARALLEL_JOBS
make RAISE_SETFCAP=no prefix=/usr install
chmod -v 755 /usr/lib/libcap.so
mv -v /usr/lib/libcap.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libcap.so) /usr/lib/libcap.so
cd /sources
rm -rf libcap-2.25
fi

echo "# 6.27. Iana-Etc-2.30"
tar -jxf iana-etc-2.30.tar.bz2
cd iana-etc-2.30
make -j $PARALLEL_JOBS
make install
cd /sources
rm -rf iana-etc-2.30

echo "# 6.33. Bash-4.4"
tar -zxf bash-4.4.tar.gz
cd bash-4.4
./configure --prefix=/usr                    \
            --docdir=/usr/share/doc/bash-4.4 \
            --without-bash-malloc            \
            --with-installed-readline
make -j $PARALLEL_JOBS
make install
mv -vf /usr/bin/bash /bin
# exec /bin/bash --login +h
# Don't know of a good way to keep running the script after entering bash here.
cd /sources
rm -rf bash-4.4


echo "#?? 6.40. Perl-5.24.0"
tar -jxf perl-5.24.0.tar.bz2
cd perl-5.24.0
echo "127.0.0.1 localhost $(hostname)" > /etc/hosts
export BUILD_ZLIB=False
export BUILD_BZIP2=0
sh Configure -des -Dprefix=/usr                 \
                  -Dvendorprefix=/usr           \
                  -Dman1dir=/usr/share/man/man1 \
                  -Dman3dir=/usr/share/man/man3 \
                  -Dpager="/usr/bin/less -isR"  \
                  -Duseshrplib
make -j $PARALLEL_JOBS
make install
unset BUILD_ZLIB BUILD_BZIP2
cd /sources
rm -rf perl-5.24.0

if [[ $INSTALL_SYSTEMD_DEPS = 1 ]] ; then
echo "6.41. XML::Parser-2.44"
tar -zxf XML-Parser-2.44.tar.gz
cd XML-Parser-2.44
perl Makefile.PL
make -j $PARALLEL_JOBS
make install
cd /sources
rm -rf XML-Parser-2.44
fi

if [[ $INSTALL_SYSTEMD_DEPS = 1 ]] ; then
echo "6.42. Intltool-0.51.0"
tar -zxf intltool-0.51.0.tar.gz
cd intltool-0.51.0
sed -i 's:\\\${:\\\$\\{:' intltool-update.in
./configure --prefix=/usr
make -j $PARALLEL_JOBS
make install
if [[ $INSTALL_OPTIONAL_DOCS = 1 ]] ; then
    install -v -Dm644 doc/I18N-HOWTO /usr/share/doc/intltool-0.51.0/I18N-HOWTO
fi
cd /sources
rm -rf intltool-0.51.0
fi


echo "#? 6.46. Kmod-23"
tar -Jxf kmod-23.tar.xz
cd kmod-23
./configure --prefix=/usr          \
            --bindir=/bin          \
            --sysconfdir=/etc      \
            --with-rootlibdir=/lib \
            --with-xz              \
            --with-zlib
make -j $PARALLEL_JOBS
make install
for target in depmod insmod lsmod modinfo modprobe rmmod; do
  ln -sv ../bin/kmod /sbin/$target
done
ln -sv kmod /bin/lsmod
cd /sources
rm -rf kmod-23


echo "#?? 6.63. Sysklogd-1.5.1"
tar -zxf sysklogd-1.5.1.tar.gz
cd sysklogd-1.5.1
sed -i '/Error loading kernel symbols/{n;n;d}' ksym_mod.c
sed -i 's/union wait/int/' syslogd.c
make -j $PARALLEL_JOBS
make BINDIR=/sbin install
cat > /etc/syslog.conf << "EOF"
# Begin /etc/syslog.conf

auth,authpriv.* -/var/log/auth.log
*.*;auth,authpriv.none -/var/log/sys.log
daemon.* -/var/log/daemon.log
kern.* -/var/log/kern.log
mail.* -/var/log/mail.log
user.* -/var/log/user.log
*.emerg *

# End /etc/syslog.conf
EOF
cd /sources
rm -rf sysklogd-1.5.1


echo "# 6.65. Eudev-3.2"
tar -zxf eudev-3.2.tar.gz
cd eudev-3.2
sed -r -i 's|/usr(/bin/test)|\1|' test/udev-test.pl
cat > config.cache << "EOF"
HAVE_BLKID=1
BLKID_LIBS="-lblkid"
BLKID_CFLAGS="-I/tools/include"
EOF
./configure --prefix=/usr           \
            --bindir=/sbin          \
            --sbindir=/sbin         \
            --libdir=/usr/lib       \
            --sysconfdir=/etc       \
            --libexecdir=/lib       \
            --with-rootprefix=      \
            --with-rootlibdir=/lib  \
            --enable-manpages       \
            --disable-static        \
            --config-cache
LIBRARY_PATH=/tools/lib make -j $PARALLEL_JOBS
mkdir -pv /lib/udev/rules.d
mkdir -pv /etc/udev/rules.d
make LD_LIBRARY_PATH=/tools/lib install
tar -jxf ../udev-lfs-20140408.tar.bz2
make -f udev-lfs-20140408/Makefile.lfs install
LD_LIBRARY_PATH=/tools/lib udevadm hwdb --update
cd /sources
rm -rf eudev-3.2


echo -e "\nYou made it! Now there are just a few things left to take care of..."
