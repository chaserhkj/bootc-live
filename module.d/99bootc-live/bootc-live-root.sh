#!/bin/sh
# Unpacks and mounts a rootfs from an oci archive

type getarg > /dev/null 2>&1 || . /lib/dracut-lib.sh
command -v unpack_archive > /dev/null || . /lib/img-lib.sh

PATH=/usr/sbin:/usr/bin:/sbin:/bin

# Currently this only takes oci archive file from
# 1. script caller (downloaded then called from bootc-live-net)
# 2. /root.oci file (embedded in initramfs or chain-loaded from pxe)
# TODO: support loading oci archive file from local block devices
imgfile=$1
[ -z $imgfile ] && imgfile=/root.oci
[ -f $imgfile ] || exit 1

# Extract oci image from archive
image_dir=/run/initramfs/bootc-img
mkdir -p $image_dir
unpack_archive $imgfile $image_dir || { warn "failed to unpack oci-archive file $imgfile"; exit 1; }

# Use umoci to extract runtime oci bundle from oci image
bundle_dir=/run/initramfs/bootc-bundle
mkdir -p $bundle_dir
umoci unpack --image $image_dir:$bootclabel $bundle_dir || { warn "failed to unpack oci-img into runtime bundle"; exit 1; }

# Prepare rootfs for mounting
rootfs_dir=/run/bootc-live
var_dir=/run/ephemeral/var
etc_dir=/run/ephemeral/etc
mkdir -p $rootfs_dir $var_dir $etc_dir

# Mount rootfs read-only
mount --bind -o ro,shared $bundle_dir/rootfs $rootfs_dir

# Simulate bootc/ostree behavior and copy over initial var structure
cp -a $rootfs_dir/var/. $var_dir
mount --bind $var_dir $rootfs_dir/var

# Same for etc
cp -a $rootfs_dir/etc/. $etc_dir
mount --bind $etc_dir $rootfs_dir/etc

if [ -z "$DRACUT_SYSTEMD" ]; then
    printf 'mount -o rbind,slave,shared %s %s\n' "$rootfs_dir" "$NEWROOT" > "$hookdir"/mount/01-$$-bootc-live.sh
fi

ln -s null /dev/root

# Everything here is ephemeral, shutdown phrase is not needed