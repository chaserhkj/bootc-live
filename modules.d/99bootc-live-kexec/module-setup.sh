
check() {
    require_binaries kexec cpio || return 1
    # This module should always be explicitly included
    return 255
}

depends() {
    echo "bootc-live bash"
}

install() {
    inst_multiple kexec cpio
    inst_hook cmdline 30 "$moddir/parse-bootc-live-kexec.sh"
    inst_hook pre-pivot 99 "$moddir/bootc-live-kexec-run.sh"
    inst_script "$moddir/bootc-live-kexec.sh" "/sbin/bootc-live-kexec"
    dracut_need_initqueue
}