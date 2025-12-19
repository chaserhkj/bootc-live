
check() {
    require_binaries skopeo || return 1
    # This module should always be explicitly included
    return 255
}

depends() {
    # Need url-lib to populate the cert store for skopeo
    echo "network url-lib bootc-live bash"
}

install() {
    inst_binary skopeo
    inst_hook cmdline 30 "$moddir/parse-bootc-live-registry.sh"
    inst_script "$moddir/bootcliveregistryroot.sh" "/sbin/bootcliveregistryroot"
    if dracut_module_included "systemd-initrd"; then
        inst_script "$moddir/bootc-live-registry-generator.sh" "$systemdutildir"/system-generators/bootc-live-registry-generator
    fi
    dracut_need_initqueue
}