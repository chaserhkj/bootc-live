#!/bin/sh
# bootc live images - bootc oci archives specified like
# root=bootc-live:[url-to-backing-file]

[ -z "$root" ] && root=$(getarg root=)
. /lib/url-lib.sh

str_starts "$root" "bootc-live:" && bootcurl="$root"
str_starts "$bootcurl" "bootc-live:" || return
bootcurl="${bootcurl#bootc-live:}"

if get_url_handler "$bootcurl" > /dev/null; then
    info "bootc-live: root bootc archive at $bootcurl"
    # bootclivenet:... triggers bootclivenetroot later in network module
    netroot="bootclivenet:$bootcurl"
    root="bootclivenet" # quiet complaints from init
    # shellcheck disable=SC2034
    rootok=1
    wait_for_dev -n /dev/root
else
    info "bootc-live: no url handler for $bootcurl"
fi
