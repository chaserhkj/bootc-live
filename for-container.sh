#!/bin/sh
# shell script to be run in container for build

kver=$(basename /usr/lib/modules/*)

case $1 in
    build-initrd)
    dracut --kver $kver -L 4 -a bootc-live --gzip --force /work/initrd.img
    ;;
    copy-kernel)
    cp -f /usr/lib/modules/$kver/vmlinuz /work/kernel.img
    ;;
esac
