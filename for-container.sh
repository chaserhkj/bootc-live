#!/bin/sh
# shell script to be run in container for build

kver=$(basename /usr/lib/modules/*)

additional_dracut_flags="-i /work/workarounds/network-wait-online-fix.sh /usr/lib/systemd/system-generators/network-wait-any-if-generator"

case $1 in
    build-initrd)
    dracut --kver $kver $additional_dracut_flags -L 4 -a "bootc-live bootc-live-zram" --gzip --force /work/initrd.img
    ;;
    build-initrd-net)
    dracut --kver $kver $additional_dracut_flags -L 4 -a "bootc-live bootc-live-zram bootc-live-net bootc-live-kexec" --gzip --force /work/initrd-net.img
    ;;
    build-initrd-registry)
    dracut --kver $kver $additional_dracut_flags -L 4 -a "bootc-live bootc-live-zram bootc-live-registry bootc-live-kexec" --gzip --force /work/initrd-registry.img
    ;;
    build-initrd-all-mods)
    dracut --kver $kver $additional_dracut_flags -L 4 -a "bootc-live bootc-live-zram bootc-live-net bootc-live-registry bootc-live-kexec" --gzip --force /work/initrd-all-mods.img
    ;;
    copy-kernel)
    cp -f /usr/lib/modules/$kver/vmlinuz /work/kernel.img
    ;;
esac
