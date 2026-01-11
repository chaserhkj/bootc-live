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

warn "bootc-live-kexec: found kernel: $kernel_img"
warn "bootc-live-kexec: found initramfs: $initramfs_img"
# Trying to reuse the oci image
reuse_oci_image() {
    local workspace="/run/initramfs/bootc"
    imgfile=$(readlink -e $workspace/extracted-rootfs.oci)
    [[ -s $imgfile ]] || { warn "bootc-live-kexec: no reusable image found"; return; }
    warn "bootc-live-kexec: attempting to reuse existing imgfile $imgfile"
    (
        set -e
        mkdir -p $workspace/repack-rootfs
        cd $workspace/repack-rootfs
        cp $imgfile root.oci
        echo root.oci | cpio -o --format=newc > $workspace/repacked-rootfs.img
        rm -rf $workspace/repack-rootfs
        cat $workspace/repacked-rootfs.img $initramfs_img > $workspace/repacked-initrd.img
        rm -f $workspace/repacked-rootfs.img
    )
    if [ $? -ne 0 ]; then
        warn "bootc-live-kexec: failed to setup image reuse"
        return
    fi
    kargs+=" bootc.kexec.reuse-image=0 root=bootc-live:/root.oci"
    initramfs_img=$workspace/repacked-initrd.img
}

if getargbool 1 bootc.kexec.reuse-image; then
    reuse_oci_image
fi

warn "bootc-live-kexec: use kernel cmdline: $kargs"
warn "bootc-live-kexec: commencing kexec"

kexec -l $kernel_img --initrd=$initramfs_img --command-line="$kargs" || exit 1
kexec -e

# If we are reaching this point, something seriously went wrong
exit 1