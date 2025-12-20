#!/bin/sh
# bootc-live-zram - use zram to compress bootc-live ram usage in-place

type getarg > /dev/null 2>&1 || . /lib/dracut-lib.sh

[ -z "$bootczram" ] && bootczram=$(getarg bootc.zram=)
[ -n "$bootczram" ] || return

info "Setting up zram with size $bootczram"

modprobe zram || { warn "Failed to load zram kernel module"; return; }

zram_path=/run/initramfs/bootc
zram_dev=$(zramctl -f -s "$bootczram")

[ -n "$zram_dev" ] || { warn "Failed to create zram device"; return; }
mkfs.ext4 -m 0 "$zram_dev" || { warn "Failed to create fs on zram device $zram_dev"; return; }
mkdir -p $zram_path
mount -o discard,noatime,commit=60,lazytime -t ext4 "$zram_dev" "$zram_path" || { warn "Failed to mount zram device $zram_dev"; return; }