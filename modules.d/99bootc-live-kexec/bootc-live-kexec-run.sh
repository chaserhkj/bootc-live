#!/bin/sh

[ -f /run/kexec.cmdline ] || return
read -r kexec_cmdline < /run/kexec.cmdline

/sbin/bootc-live-kexec "$kexec_cmdline"
# If we are reaching this point, it means something is wrong
die "bootc-live-kexec failed"