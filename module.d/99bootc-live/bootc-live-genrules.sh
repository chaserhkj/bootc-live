#!/bin/sh

case "$root" in
    # TODO: add support for reading oci from block devices here
    bootc-live:/*)
        if [ -f "${root#bootc-live:}" ]; then
            /sbin/initqueue --settled --onetime --unique /sbin/bootc-live-root "${root#bootc-live:}"
        fi
        ;;
esac