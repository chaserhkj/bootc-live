#!/bin/sh
# bootc live images - use bootc image from container registry as live image

[ -z "$root" ] && root=$(getarg root=)

str_starts "$root" "bootc-live:docker://" || return
bootc_img_spec="${root#bootc-live:docker://}"

# bootcliveregistry:... triggers bootcliveregistryroot later in network module
netroot="bootcliveregistry:$bootc_img_spec"
root="bootcliveregistry" # quiet complaints from init
# shellcheck disable=SC2034
rootok=1
wait_for_dev -n /dev/root
