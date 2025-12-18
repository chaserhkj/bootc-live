#!/bin/sh
# bootc live images - boot from oci archives
# currently this only supports embedded oci archives
# either directly with initramfs or chain-loaded by PXE
# root=bootc-live:/[path in initramfs to oci]

[ -z "$root" ] && root=$(getarg root=)

str_starts "$root" "bootc-live:/" || return

root="bootclive" # quiet complaints from init
# shellcheck disable=SC2034
rootok=1
wait_for_dev -n /dev/root