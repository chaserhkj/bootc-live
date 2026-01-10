#!/bin/bash
# bootc-live-kexec - Finds vmlinuz and initramfs.img in mounted bootc image and kexec into them

type getarg > /dev/null 2>&1 || . /lib/dracut-lib.sh
kargs="$1"

# Should be mounted by bootc-live
rootfs=/run/bootc-live
# Determine the kver for the bootc image
kver=( $rootfs/usr/lib/modules/* )
# If multiple kvers are present, this selects the first one
# Per bootc specification bootc image SHOULD only have one kernel so this is not a problem
kver=${kver[0]##*/}

# Locations specified by bootc
kernel_img=$rootfs/usr/lib/modules/$kver/vmlinuz
initramfs_img=$rootfs/usr/lib/modules/$kver/initramfs.img
[ -s $kernel_img ] || exit 1
[ -s $initramfs_img ] || exit 1

info "found kernel: $kernel_img"
info "found initramfs: $initramfs_img"
info "use kernel cmdline: $kargs"
warn "found kernel from mounted rootfs, commencing kexec"

kexec -l $kernel_img --initrd=$initramfs_img --command-line="$kargs" || exit 1
kexec -e

# If we are reaching this point, something seriously went wrong
exit 1