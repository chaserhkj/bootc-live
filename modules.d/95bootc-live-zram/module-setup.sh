
check() {
    require_binaries zramctl mkfs.ext4 || return 1
    # This module should always be explicitly included
    return 255
}

depends() {
    echo "bash"
}

installkernel() {
    hostonly='' instmods -c zram ext4
}

install() {
    inst_multiple zramctl mkfs.ext4
    inst_hook pre-udev 00 "$moddir/parse-bootc-live-zram.sh"
    dracut_need_initqueue
}