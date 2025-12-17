# Base bootc image for everything
base := "quay.io/fedora/fedora-coreos:stable"
podman := require("podman")
skopeo := require("skopeo")
modules := justfile_directory() / "module.d"

# Build initrd with bootc-live dracut module, save to $PWD/initrd.img
build-initrd: 
    just _run /bin/sh /work/for-container.sh build-initrd

# Copy kernel image from bootc image to $PWD/kernel.img
copy-kernel: 
    just _run /bin/sh /work/for-container.sh copy-kernel

# Create $PWD/rootfs.img that is just cpio archive wrapped around oci archive
build-rootfs-img:

_volume_flags := \
    f'-v {{modules/"98bootc-live-net"}}:/usr/lib/dracut/modules.d/98bootc-live-net '+\
    f'-v {{modules/"99bootc-live"}}:/usr/lib/dracut/modules.d/99bootc-live '+\
    f'-v {{invocation_directory()}}:/work '

# Runs command as interpreted by sh in the base image
_run +CMDS:
    {{podman}} run --rm -it --entrypoint "" \
        {{_volume_flags}} {{base}} {{CMDS}}