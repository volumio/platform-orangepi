# platform-orangepi

This repo contains platform specific files used by the Volumio Builder to create **OrangePi** images:

The kernel and u-boot files are created from armbian using the mainline kernel.
There is a dtb overlay to enable the i2s0 connection for pcm audio devices.

Currently supported OrangePi devices are
* OrangePi One
* OrangePi Lite
