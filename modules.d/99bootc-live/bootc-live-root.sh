#!/bin/sh
# Unpacks and mounts a rootfs from an oci archive

type getarg > /dev/null 2>&1 || . /lib/dracut-lib.sh

PATH=/usr/sbin:/usr/bin:/sbin:/bin

# Currently this only takes oci archive file from
# 1. script caller (downloaded then called from bootc-live-net)
# 2. /root.oci file (embedded in initramfs or chain-loaded from pxe)
# TODO: support loading oci archive file from local block devices
imgfile=$1
[ -z $imgfile ] && imgfile=/root.oci
[ -f $imgfile ] || { die "oci-archive file $imgfile does not exist"; }

oci_label=$2
[ -z $oci_label ] && oci_label=latest

workspace=/run/initramfs/bootc
mkdir -p $workspace
# workspace must be mounted with suid,dev options for rootfs to work with sudo, overlayfs, etc.
# but /run in initramfs is often mounted as tmpfs with nosuid,nodev
# other modules may mount to this location as well (e.g. bootc-live-zram)
# apply simple assumption and just test if /run and workspace are on same device
# mount new tmpfs with proper options if they are, noop otherwise
[ "$(stat -c '%d' -f /run )" = "$(stat -c '%d' -f $workspace)" ] && mount -t tmpfs -o suid,dev none $workspace


# Extract oci image from archive
image_dir=$workspace/img
mkdir -p $image_dir
warn "Unpacking oci image from archive file"
tar -C $image_dir -xf $imgfile || { die "failed to unpack oci-archive file $imgfile"; }

# Use umoci to extract runtime oci bundle from oci image
bundle_dir=$workspace/bundle
mkdir -p $bundle_dir
warn "Unpacking oci bundle from oci image"
umoci unpack --image $image_dir:$oci_label $bundle_dir || { die "failed to unpack oci-img into runtime bundle"; }

# Prepare rootfs for mounting
rootfs_dir=/run/bootc-live
mkdir -p $rootfs_dir

# Mount rootfs read-only
mount --bind -o ro,shared $bundle_dir/rootfs $rootfs_dir

# Mount var and etc read-write
mount --bind $bundle_dir/rootfs/var $rootfs_dir/var
mount --bind $bundle_dir/rootfs/etc $rootfs_dir/etc

# Clean up to free memory
rm -rf $image_dir
rm -f $imgfile

if [ -z "$DRACUT_SYSTEMD" ]; then
    printf 'mount -o rbind,slave,shared %s %s\n' "$rootfs_dir" "$NEWROOT" > "$hookdir"/mount/01-$$-bootc-live.sh
fi

ln -s null /dev/root

# Everything here is ephemeral, shutdown phrase is not needed