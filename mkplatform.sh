#!/bin/bash
C=`pwd`
A=../armbian
P=orangepi$1

cp kernel-sunxi-next.patch ${A}/userpatches/kernel/sunxi-next/
cp ${A}/config/kernel/linux-sunxi-next.config ${A}/userpatches
cd ${A}
patch -p0 < ${C}/config.patch
./compile.sh KERNEL_ONLY=yes BOARD=${P} BRANCH=next RELEASE=jessie KERNEL_CONFIGURE=no EXTERNAL=yes BUILD_KSRC=no BUILD_DESKTOP=no

cd ${C}
rm -rf ${P}
mkdir ${P}
mkdir ${P}/u-boot

dpkg-deb -x ${A}/output/debs/linux-dtb-next-sunxi_* ${P}
dpkg-deb -x ${A}/output/debs/linux-image-next-sunxi_* ${P}
dpkg-deb -x ${A}/output/debs/linux-u-boot-next-${P}_* ${P}
mkdir ${P}/lib/firmware
git clone https://github.com/armbian/firmware ${P}/lib/firmware
rm -rf ${P}/lib/firmware/.git

cp ${P}/usr/lib/linux-u-boot-next-*/u-boot-sunxi-with-spl.bin ${P}/u-boot

rm -rf ${P}/usr ${P}/etc

mv ${P}/boot/dtb* ${P}/boot/dtb
mv ${P}/boot/vmlinuz* ${P}/boot/zImage

mkdir ${P}/boot/overlay-user
cp sun8i-h3-i2s0.* ${P}/boot/overlay-user

cp ${A}/config/bootscripts/boot-sunxi.cmd ${P}/boot/boot.cmd
mkimage -c none -A arm -T script -d ${P}/boot/boot.cmd ${P}/boot/boot.scr
touch ${P}/boot/.next

echo "verbosity=1
logo=disabled
console=both
disp_mode=1920x1080p60
overlay_prefix=sun8i-h3
rootdev=/dev/mmcblk0p2
rootfstype=ext4
user_overlays=sun8i-h3-i2s0
usbstoragequirks=0x2537:0x1066:u,0x2537:0x1068:u
extraargs=imgpart=/dev/mmcblk0p2 imgfile=/volumio_current.sqsh" >> ${P}/boot/armbianEnv.txt

tar cJf $P.tar.xz $P
