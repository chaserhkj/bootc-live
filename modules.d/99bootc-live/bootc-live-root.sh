#!/bin/sh
# Unpacks and mounts a rootfs from an oci archive

type getarg > /dev/null 2>&1 || . /lib/dracut-lib.sh
. /lib/bootc-live-lib.sh

PATH=/usr/sbin:/usr/bin:/sbin:/bin

check_bootc_quiet

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

# Reference where the oci image is, for kexec processing
ln -sfT $imgfile $workspace/extracted-rootfs.oci

# Extract oci image from archive
image_dir=$workspace/img
mkdir -p $image_dir
warn "bootc-live: Unpacking oci image from archive file"
$bootc_long_running_process tar -C $image_dir -xvf $imgfile || { die "failed to unpack oci-archive file $imgfile"; }

# Use umoci to extract runtime oci bundle from oci image
bundle_dir=$workspace/bundle
mkdir -p $bundle_dir

# rootfs unpack location must be mounted with suid,dev options for rootfs to work with sudo, overlayfs, etc.
# but /run in initramfs is often mounted as tmpfs with nosuid,nodev
# other modules may mount to workspace location as well (e.g. bootc-live-zram)
# apply simple assumption and just test if /run and bundle_dir are on same device
# mount new tmpfs with proper options if they are, noop otherwise
[ "$(stat -c '%d' -f /run )" = "$(stat -c '%d' -f $bundle_dir)" ] && mount -t tmpfs -o suid,dev none $bundle_dir

warn "bootc-live: Unpacking oci bundle from oci image"
$bootc_long_running_process umoci --verbose unpack --image $image_dir:$oci_label $bundle_dir || { die "failed to unpack oci-img into runtime bundle"; }

# Prepare rootfs for mounting
rootfs_dir=/run/bootc-live
mkdir -p $rootfs_dir

# Unless explicitly set mount flags, mount var and etc read-write by default
rootflags=$(getarg rootflags=)

if getargbool 0 bootc.live.erofs; then

    warn "bootc-live: making erofs image"

    mkfs.erofs -U 00000000-0000-0000-0000-000000000000 -T 0 $workspace/erofs.img $bundle_dir/rootfs/

    loop_dev=$(losetup --find --show --direct-io=on $workspace/erofs.img)

    mount -t erofs $loop_dev -o "$rootflags" $rootfs_dir

    if getargbool bootc.live.var.rw 1; then
        cp -a $rootfs_dir/var $bundle_dir/var
        mount --bind -o rw $bundle_dir/var $rootfs_dir/var
    fi

    if getargbool bootc.live.etc.rw 1; then
        cp -a $rootfs_dir/etc $bundle_dir/etc
        mount --bind -o rw $bundle_dir/etc $rootfs_dir/etc
    fi

    # Clean up extracted bundle to save space
    rm -rf $bundle_dir/rootfs
else
    # Resolve rootfs mount flags
    if getargbool 0 rw; then
        getargbool 0 ro && warn "bootc-live: both ro and rw set, assuming rw"
        mount_flags=rw
    else
        mount_flags=ro
    fi
    [ -n $rootflags ] && mount_flags="$mount_flags,$rootflags"

    # Mount rootfs
    mount --bind --make-shared -o $mount_flags $bundle_dir/rootfs $rootfs_dir

    if getargbool bootc.live.var.rw 1; then
        mount --bind -o rw $bundle_dir/rootfs/var $rootfs_dir/var
    fi
    if getargbool bootc.live.etc.rw 1; then
        mount --bind -o rw $bundle_dir/rootfs/etc $rootfs_dir/etc
    fi
fi


# Clean up to free memory
rm -rf $image_dir
if ! getargbool 1 bootc.kexec.reuse-image; then
    rm -f $imgfile
fi

if [ -z "$DRACUT_SYSTEMD" ]; then
    printf 'mount -o rbind,slave,shared %s %s\n' "$rootfs_dir" "$NEWROOT" > "$hookdir"/mount/01-$$-bootc-live.sh
fi

ln -s null /dev/root

# Everything here is ephemeral, shutdown phrase is not needed