#!/bin/bash
# bootc-live-kexec - Finds vmlinuz and initramfs.img in mounted bootc image and kexec into them

kargs="$1"

# Should be mounted by bootc-live
rootfs=/run/bootc-live
# Determine the kver for the bootc image
kver=$rootfs/usr/lib/modules/*
# If multiple kvers are present, this selects the last one
# Per bootc specification bootc image SHOULD only have one kernel so this is not a problem
kver=${kver##*/}

# Locations specified by bootc
kernel_img=$rootfs/usr/lib/modules/$kver/vmlinuz
initramfs_img=$rootfs/usr/lib/modules/$kver/initramfs.img
[ -s $kernel_img ] || exit 1
[ -s $initramfs_img ] || exit 1

kexec -l $kernel_img --initrd=$initramfs_img --command-line="$kargs" || exit 1
kexec -e

# If we are reaching this point, something seriously went wrong
exit 1