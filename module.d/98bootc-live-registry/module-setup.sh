
check() {
    require_binaries skopeo || return 1
    # This module should always be explicitly included
    return 255
}

depends() {
    # Use img-lib from builtin modules to handle oci-archive files
    # They are just tarballs really
    echo "network bootc-live bash"
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