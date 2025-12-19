#!/bin/sh
# bootc-live-kexec - use kexec to load kernel provided by bootc live image

[ -z "$root" ] && root=$(getarg root=)

# Only do this if booting into a bootc-live environment
str_starts "$root" "bootc-live:" || return
# Only do this with explicit kernel arg
getargbool 0 bootc.kexec || return

# Save real cmdline from /proc/cmdline for kexec, plus overriding kexec argument to prevent loop-booting
kexec_cmdline=
while read -r _line || [ -n "$_line" ]; do
    kexec_cmdline="$kexec_cmdline $_line"
done < /proc/cmdline
echo "$kexec_cmdline bootc.kexec=0" > /run/kexec.cmdline