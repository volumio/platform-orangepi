#!/bin/bash
set -eo pipefail

# Default to One
ver="${1:-one}"
[[ $# -ge 1 ]] && shift 1
if [[ $# -ge 0 ]]; then
  armbian_extra_flags=("$@")
  echo "Passing additional args to Armbian ${armbian_extra_flags[*]}"
else
  armbian_extra_flags=("")
fi

C=$(pwd)
A=../../armbian-master
P="orangepi${ver}"
B="current"
T="orangepi${ver}"
K="sunxi"

# Make sure we grab the right version
ARMBIAN_VERSION=$(cat ${A}/VERSION)

# Custom patches
echo "Adding custom patches"
ls "${C}/patches/"
mkdir -p "${A}"/userpatches/kernel/"${K}"-"${B}"/
rm -rf "${A}"/userpatches/kernel/"${K}"-"${B}"/*.patch
cp "${C}"/patches/*.patch "${A}"/userpatches/kernel/"${K}"-"${B}"/

# Custom kernel Config
if [ -e "${C}"/kernel-config/linux-"${K}"-"${B}".config ]
then
  echo "Copy custom Kernel config"
  ls "${C}"/kernel-config/linux-"${K}"-"${B}".config
  cp "${C}"/kernel-config/linux-"${K}"-"${B}".config "${A}"/userpatches/
fi

# Select specific Kernel and/or U-Boot version
rm -rf "${A}"/userpatches/lib.config
if [ -e "${C}"/kernel-ver/"${P}".config ]
then
  echo "Copy specific kernel/uboot version config"
  cp "${C}"/kernel-ver/"${P}"*.config "${A}"/userpatches/lib.config
fi

cd ${A}
ARMBIAN_HASH=$(git rev-parse --short HEAD)
echo "Building for $P -- with Armbian ${ARMBIAN_VERSION} -- $B"

./compile.sh BOARD="${T}" BRANCH="${B}" RELEASE=buster KERNEL_CONFIGURE=no EXTERNAL=yes BUILD_KSRC=no BUILD_DESKTOP=no BUILD_ONLY=u-boot,kernel,armbian-firmware "${armbian_extra_flags[@]}"

echo "Done!"

cd "${C}"
echo "Creating platform ${P} files"
[[ -d ${P} ]] && rm -rf "${P}"
mkdir -p "${P}"/u-boot
mkdir -p "${P}"/lib/firmware
mkdir -p "${P}"/boot/overlay-user
# Keep a copy for later just in case
cp "${A}/output/debs/linux-headers-${B}-${K}_${ARMBIAN_VERSION}"* "${C}"

dpkg-deb -x "${A}/output/debs/linux-dtb-${B}-${K}_${ARMBIAN_VERSION}"* "${P}"
dpkg-deb -x "${A}/output/debs/linux-image-${B}-${K}_${ARMBIAN_VERSION}"* "${P}"
dpkg-deb -x "${A}/output/debs/linux-u-boot-${B}-${T}_${ARMBIAN_VERSION}"* "${P}"
dpkg-deb -x "${A}/output/debs/armbian-firmware_${ARMBIAN_VERSION}"* "${P}"

# Copy bootloader stuff
cp "${P}"/usr/lib/linux-u-boot-${B}-*/u-boot-sunxi-with-spl.bin "${P}/u-boot"

mv "${P}"/boot/dtb* "${P}"/boot/dtb
mv "${P}"/boot/vmlinuz* "${P}"/boot/zImage

# Clean up unneeded parts
rm -rf "${P}/lib/firmware/.git"
rm -rf "${P:?}/usr" "${P:?}/etc"

# Set USB OTG port to host
dtc -I dtb -O dts -o "${P}"/boot/dtb/sun8i-h3-orangepi-one.dts "${P}"/boot/dtb/sun8i-h3-orangepi-one.dtb
sed -i -e 's/dr_mode = "otg";/dr_mode = "host";/g' "${P}"/boot/dtb/sun8i-h3-orangepi-one.dts
dtc -I dts -O dtb -o "${P}"/boot/dtb/sun8i-h3-orangepi-one.dtb "${P}"/boot/dtb/sun8i-h3-orangepi-one.dts

# Compile and copy over overlay(s) files
for dts in "${C}"/overlay-user/overlays-"${P}"/*.dts; do
  dts_file=${dts%%.*}
  if [ -s "${dts_file}.dts" ]
  then
    echo "Compiling ${dts_file}"
    dtc -O dtb -o "${dts_file}.dtbo" "${dts_file}.dts"
    cp "${dts_file}.dtbo" "${P}"/boot/overlay-user
  fi
done

# Copy and compile boot script
cp "${A}"/config/bootscripts/boot-"${K}".cmd "${P}"/boot/boot.cmd
mkimage -C none -A arm -T script -d "${P}"/boot/boot.cmd "${P}"/boot/boot.scr

# Signal mainline kernel
touch "${P}"/boot/.next

# Prepare boot parameters
overlays=("i2c0" "usbhost0" "usbhost1" "usbhost2" "usbhost3")
[[ ${ver} == "pc" || ${ver} == "zero" ]] && overlays+=("analog-codec")

cat <<-EOF >>"${P}/boot/armbianEnv.txt"
verbosity=0
bootlogo=true
console=both
disp_mode=1920x1080p60
overlay_prefix=sun8i-h3
overlays=${overlays[@]}
rootdev=/dev/mmcblk0p2
rootfstype=ext4
user_overlays=sun8i-h3-i2s0
usbstoragequirks=0x2537:0x1066:u,0x2537:0x1068:u
extraargs=imgpart=/dev/mmcblk0p2 imgfile=/volumio_current.sqsh net.ifnames=0 hwver=orangepi
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
