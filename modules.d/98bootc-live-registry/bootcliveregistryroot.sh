#!/bin/sh
# bootclivenetroot - fetch a bootc oci archive from network and run it as live system

type getarg > /dev/null 2>&1 || . /lib/dracut-lib.sh

PATH=/usr/sbin:/usr/bin:/sbin:/bin
RETRIES=${RETRIES:-100}
SLEEP=${SLEEP:-5}

[ -e /tmp/bootcliveregistry.downloaded ] && exit 0

netroot="$2"
image_tag="${netroot#bootcliveregistry:}"
warn "fetching oci archive for $image_tag"

img_path=/run/initramfs/bootc/root.oci
mkdir -p "${img_path%/*}"
oci_archive_tag=latest
rm -f $img_path
# Retry loop
i=1
while [ "$i" -le "$RETRIES" ]; do
    if getargbool 0 bootc.registry.unsecure; then
        skopeo --insecure-policy copy --src-tls-verify=false docker://"$image_tag" oci-archive:$img_path:$oci_archive_tag
    else
        skopeo --insecure-policy copy docker://"$image_tag" oci-archive:$img_path:$oci_archive_tag
    fi

    # shellcheck disable=SC2181
    if [ $? != 0 ]; then
        warn "failed to download oci live image: error $?"
    fi

    if [ -n "$img_path" -a -s "$img_path" ]; then
        break
    else
        if [ $i -ge "$RETRIES" ]; then
            warn "failed to download oci live image after $i attempts."
            exit 1
        fi

        sleep "$SLEEP"
    fi

    i=$((i + 1))
done > /tmp/bootcliveregistry.downloaded

exec /sbin/bootc-live-root "$img_path" "$oci_archive_tag"
