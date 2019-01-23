# platform-orangepi

This repo contains platform specific files used by the Volumio Builder to create **OrangePi** images:

The kernel, modules, firmware and u-boot files are created from armbian using the mainline kernel.
There is a dtb overlay to enable the i2s0 connection for pcm5102a audio devices.

Currently supported OrangePi devices are
* OrangePi One
* OrangePi Lite
* OrangePi PC

## Kernel Sources
Kernel sources ar from `git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git` branch `linux-4.14.y`

Firmware sources are from `https://github.com/armbian/firmware` branch `master`

U-Boot sources are from `git://git.denx.de/u-boot.git` the `2017.11` tag

## Creating/Updating a platform archive

Clone the armbian repository as a sibling to this directory
```bash
git clone https://github.com/armbian/build ../armbian
./mkplatform.sh lite
```

## Changelog
23 Jan 19
- update to armbian build 4.19.13

18 Apr 18
- Update to armbian build with kernel 4.14.34
