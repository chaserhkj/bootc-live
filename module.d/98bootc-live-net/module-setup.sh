
check() {
    # This module should always be explicitly included
    return 255
}

depends() {
    # Use img-lib from builtin modules to handle oci-archive files
    # They are just tarballs really
    echo "network url-lib bootc-live bash"
}

install() {
    inst_hook cmdline 30 "$moddir/parse-bootc-live-net.sh"
    inst_script "$moddir/bootclivenetroot.sh" "/sbin/bootclivenetroot"
    if dracut_module_included "systemd-initrd"; then
        inst_script "$moddir/bootc-live-net-generator.sh" "$systemdutildir"/system-generators/bootc-live-net-generator
    fi
    dracut_need_initqueue
}