#!/bin/sh

type getarg > /dev/null 2>&1 || . /lib/dracut-lib.sh

[ -z "$root" ] && root=$(getarg root=)

[ "${root%%:*}" = "bootc-live" ] || exit 0

case "$root" in
    bootc-live:/*)
        root="${root#bootc-live:}"
        rootok=1
        ;;
esac

[ "$rootok" != "1" ] && exit 0

GENERATOR_DIR="$2"
[ -z "$GENERATOR_DIR" ] && exit 1

[ -d "$GENERATOR_DIR" ] || mkdir -p "$GENERATOR_DIR"

{
    echo "[Unit]"
    echo "Before=initrd-root-fs.target"
    echo "[Mount]"
    echo "Where=/sysroot"
    echo "What=/run/bootc-live"
    echo "Options=rbind,slave,shared"
} > "$GENERATOR_DIR"/sysroot.mount
