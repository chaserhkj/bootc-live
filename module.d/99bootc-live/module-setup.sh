
check() {
    require_binaries tar umoci || return 1
    # This module should always be explicitly included
    return 255
}

depends() {
    echo "bash"
}

install() {
    inst_multiple tar umoci
    inst_script "$moddir/bootc-live-root.sh" "/sbin/bootc-live-root"
    inst_hook pre-udev 30 "$moddir/bootc-live-genrules.sh"
    if dracut_module_included "systemd-initrd"; then
        inst_script "$moddir/bootc-live-generator.sh" "$systemdutildir"/system-generators/bootc-live-generator
    fi
    dracut_need_initqueue
}