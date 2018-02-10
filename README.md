# platform-orangepi

This repo contains platform specific files used by the Volumio Builder to create **OrangePi** images:

The kernel, modules, firmware and u-boot files are created from armbian using the mainline kernel.
There is a dtb overlay to enable the i2s0 connection for pcm audio devices.

kernel repo is from `git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git` branch `linux-4.14.y`

Currently supported OrangePi devices are
* OrangePi One
* OrangePi Lite

## Creating a new platform

Clone the armbian repository as a sibling to this directory
```bash
git clone https://github.com/armbian/build ../armbian
./mkplatform.sh lite
```

