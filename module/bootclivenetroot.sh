#!/bin/sh
# bootclivenetroot - fetch a bootc oci archive from network and run it as live system

type getarg > /dev/null 2>&1 || . /lib/dracut-lib.sh

. /lib/url-lib.sh

PATH=/usr/sbin:/usr/bin:/sbin:/bin
RETRIES=${RETRIES:-100}
SLEEP=${SLEEP:-5}

[ -e /tmp/bootclivenet.downloaded ] && exit 0

bootclabel=$(getarg bootclabel=)
[ -z "$bootclabel" ] && bootclabel="latest"

netroot="$2"
liveurl="${netroot#bootclivenet:}"
info "fetching $liveurl"

imgfile=
#retry until the imgfile is populated with data or the max retries
i=1
while [ "$i" -le "$RETRIES" ]; do
    imgfile=$(fetch_url "$liveurl")

    # shellcheck disable=SC2181
    if [ $? != 0 ]; then
        warn "failed to download live image: error $?"
        imgfile=
    fi

    if [ -n "$imgfile" -a -s "$imgfile" ]; then
        break
    else
        if [ $i -ge "$RETRIES" ]; then
            warn "failed to download live image after $i attempts."
            exit 1
        fi

        sleep "$SLEEP"
    fi

    i=$((i + 1))
done > /tmp/bootclivenet.downloaded

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
