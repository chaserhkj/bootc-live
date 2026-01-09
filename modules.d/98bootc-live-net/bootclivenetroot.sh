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
warn "fetching $liveurl"

imgfile=
save_path=/run/initramfs/bootc/root.oci
mkdir -p "${save_path%/*}"
#retry until the imgfile is populated with data or the max retries
i=1
while [ "$i" -le "$RETRIES" ]; do
    imgfile=$(fetch_url "$liveurl" "$save_path")

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

exec /sbin/bootc-live-root "$imgfile" "$bootclabel"
