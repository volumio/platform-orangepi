# platform-orangepi

This repo contains platform specific files used by the Volumio Builder to create **OrangePi** Allwinner H3 based images:

Currently supported OrangePi devices are
* OrangePi One
* OrangePi Lite
* OrangePi PC
* OrangePi Zero

## Kernel Sources

| Type         | Source                                                          | Version          |
| :----------- | :-------------------------------------------------------------- | :--------------- |
| U-Boot       | [u-boot/u-boot.git](https://source.denx.de/u-boot/u-boot.git)   | `2022.07`        |
| Kernel       | [megous/linux.git](https://megous.com/git/linux)                | `orange-pi-5.15` |
| Firmware     | [armbian/firmware.git](https://github.com/armbian/firmware.git) | `master`         |
| Build System | [armbian/build](https://github.com/armbian/build.git)           | `master`         |

## Changelog
Jan 01 2023
- Update to kernel 5.15.85 and uboot 2022.07
- Predictable names on WiFi interfaces

Feb 17 2022
- Update to kernel 5.15.yy
- Add support for WM8809 (@mafiulo)
- Add support for E1DA 9038d and Tempotec Sonata E44 DSD USB DACs (@Vyacheslav-S)

Feb 07 2021 
- Update to kernel 5.10.yy

Feb 28 2020
- Update to kernel 5.4.yy
  
Jan 24 2019
- Update to kernel 4.19.17

Apr 18 2018
- Update to kernel 4.14.34
