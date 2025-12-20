
check() {
    require_binaries zramctl || return 1
    # This module should always be explicitly included
    return 255
}

depends() {
    echo "bash"
}

installkernel() {
    hostonly='' instmods -c zram
}

install() {
    inst_binary zramctl
    inst_hook cmdline 30 "$moddir/parse-bootc-live-zram.sh"
    dracut_need_initqueue
}