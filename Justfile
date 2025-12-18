# Base bootc image for everything
base := "localhost/coreos-test"
podman := require("podman")
skopeo := require("skopeo")
cpio := require("cpio")
qemu := require("sudo") + " " + require("qemu-system-x86_64")
modules := justfile_directory() / "module.d"

default: build-full-img copy-kernel

build-test-container:
    {{podman}} build -f Containerfile -t "localhost/coreos-test" {{justfile_directory()}}

# Build initrd with bootc-live dracut module, save to $PWD/initrd.img
build-initrd: 
    just _run /bin/sh /work/for-container.sh build-initrd

# Copy kernel image from bootc image to $PWD/kernel.img
copy-kernel: 
    just _run /bin/sh /work/for-container.sh copy-kernel

# Create oci archive for rootfs, $PWD/root.oci
build-rootfs-oci:
    cd {{justfile_directory()}} && {{skopeo}} copy containers-storage:{{base}} oci-archive:root.oci:latest

# Create $PWD/rootfs.img, which is root.oci wrapped in cpio
build-rootfs-img: build-rootfs-oci
    cd {{justfile_directory()}} && echo root.oci | {{cpio}} -vo -R root:root --format=newc > rootfs.img

# Create $PWD/initrd-full.img which is initrd.img combined with rootfs.img
build-full-img: build-initrd build-rootfs-img
    cd {{justfile_directory()}} && cat initrd.img rootfs.img > initrd-full.img

run-vm initrd="initrd-full.img" cmdline="root=bootc-live:/root.oci" mem="16G":
    cd {{justfile_directory()}} && {{qemu}} \
        -kernel kernel.img -initrd {{initrd}} -m {{mem}} \
        -accel kvm -cpu host \
        -device virtio-serial-pci,id=virtio-serial0 \
        -chardev stdio,id=charconsole0 \
        -device virtconsole,chardev=charconsole0,id=console0 \
        -display none \
        -append "console=hvc0 {{cmdline}}"

_volume_flags := \
    f'-v {{modules/"98bootc-live-net"}}:/usr/lib/dracut/modules.d/98bootc-live-net '+\
    f'-v {{modules/"99bootc-live"}}:/usr/lib/dracut/modules.d/99bootc-live '+\
    f'-v {{invocation_directory()}}:/work '

# Runs command in the base image
_run +CMDS:
    {{podman}} run --rm -it --entrypoint "" \
        {{_volume_flags}} {{base}} {{CMDS}}