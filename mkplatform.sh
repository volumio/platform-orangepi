#!/bin/bash
set -eo pipefail

# Default to lite
ver="${1:-lite}"

C=$(pwd)
A=../../armbian
P="orangepi${ver}"
B=current
# Make sure we grab the right version
ARMBIAN_VERSION=$(cat ${A}/VERSION)

# Shouldn't be needed anymore
# cp kernel-sunxi-legacy.patch ${A}/userpatches/kernel/sunxi-legacy/
# cp ${A}/config/kernel/linux-sunxi-legacy.config ${A}/userpatches
cd ${A}
ARMBIAN_HASH=$(git rev-parse --short HEAD)
echo "Building for OrangePi ${ver} -- with Armbian ${ARMBIAN_VERSION} -- $B"

./compile.sh docker KERNEL_ONLY=yes BOARD="${P}" BRANCH=${B} RELEASE=buster KERNEL_CONFIGURE=no EXTERNAL=yes BUILD_KSRC=no BUILD_DESKTOP=no
echo "Done!"

cd "${C}"
[[ -d ${P} ]] && rm -rf "${P}"
mkdir -p "${P}/u-boot"
mkdir -p "${P}/lib/firmware"
mkdir -p "${P}"/boot/overlay-user
# Keep a copy for later just in case
cp "${A}/output/debs/linux-headers-${B}-sunxi_${ARMBIAN_VERSION}"_* "${C}"

dpkg-deb -x "${A}/output/debs/linux-dtb-${B}-sunxi_${ARMBIAN_VERSION}"_* "${P}"
dpkg-deb -x "${A}/output/debs/linux-image-${B}-sunxi_${ARMBIAN_VERSION}"_* "${P}"
dpkg-deb -x "${A}/output/debs/linux-u-boot-${B}-${P}_${ARMBIAN_VERSION}"_* "${P}"

git clone --depth 1 https://github.com/armbian/firmware "${P}/lib/firmware"

# Copy bootloader stuff
cp "${P}"/usr/lib/linux-u-boot-${B}-*/u-boot-sunxi-with-spl.bin "${P}/u-boot"

mv "${P}"/boot/dtb* "${P}"/boot/dtb
mv "${P}"/boot/vmlinuz* "${P}"/boot/zImage

# Clean up unneeded parts
rm -rf "${P}/lib/firmware/.git"
rm -rf "${P:?}/usr" "${P:?}/etc"

# Compile and copy over overlay(s) files
for dts in "${C}"/overlays/*.dts; do
  dts_file=${dts%%.*}
  echo "Compiling ${dts_file}"
  dtc -O dtb -o "${dts_file}.dts" "${dts_file}.dtbo"
  cp "${dts_file}".{dts,dtbo} "${P}"/boot/overlay-user
done

cp ${A}/config/bootscripts/boot-sunxi.cmd "${P}"/boot/boot.cmd
touch "${P}"/boot/.next # Signal mainline kernel
mkimage -c none -A arm -T script -d "${P}"/boot/boot.cmd "${P}"/boot/boot.scr

# Prepare boot parameters
overlays=("i2c0")
[[ ${ver} == "pc" || ${ver} == "zero" ]] && overlays+=("analog-codec")

cat <<-EOF >>"${P}/boot/armbianEnv.txt"
verbosity=8
logo=disabled
console=both
disp_mode=1920x1080p60
overlay_prefix=sun8i-h3
overlays=${overlays[@]}
rootdev=/dev/mmcblk0p2
rootfstype=ext4
user_overlays=sun8i-h3-i2s0
usbstoragequirks=0x2537:0x1066:u,0x2537:0x1068:u
extraargs=imgpart=/dev/mmcblk0p2 imgfile=/volumio_current.sqsh
EOF

echo "Creating device tarball.."
tar cJf "${P}_${B}.tar.xz" "$P"

echo "Renaming tarball for Build scripts to pick things up"
mv "${P}_${B}.tar.xz" "${P}.tar.xz"
KERNEL_VERSION="$(basename ./"${P}"/boot/config-*)"
KERNEL_VERSION=${KERNEL_VERSION#*-}
echo "Creating a version file Kernel: ${KERNEL_VERSION}"
cat <<EOF >"${C}/version"
BUILD_DATE=$(date +"%m-%d-%Y")
ARMBIAN_VERSION=${ARMBIAN_VERSION}
ARMBIAN_HASH=${ARMBIAN_HASH}
KERNEL_VERSION=${KERNEL_VERSION}
EOF

echo "Cleaning up.."
rm -rf "${P}"
