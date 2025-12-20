#!/bin/sh
# bootc-live-zram - use zram to compress bootc-live ram usage in-place

[ -z "$bootczram" ] && bootczram=$(getarg bootc.zram)
[ -z "$bootczram" ] || return

zram_path=/run/initramfs/bootc
zram_dev=$(zramctl -f -s "$bootczram")

[ -z "$zram_dev" ] || { warn "Failed to create zram device"; return; }
mount "$zram_dev" "$zram_path" || { warn "Failed to mount zram device $zram_dev"; return; }