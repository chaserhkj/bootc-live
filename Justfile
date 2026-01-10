# Builder image to build initrd and copy kernel image from
builder_img := env("BUILDER_IMG", "localhost/fedora-bootc-live-builder")
# Live image to export oci archive from
live_img := env("LIVE_IMG", "localhost/fedora-bootc-live")
podman := require("podman")
skopeo := require("skopeo")
cpio := require("cpio")
qemu := require("sudo") + " " + require("qemu-system-x86_64")
gzip := require("gzip")
modules := justfile_directory() / "modules.d"

default: build-full-img copy-kernel

# Build container image for builder tasks
build-builder-container-img:
    {{podman}} build --target builder -t {{builder_img}} {{justfile_directory()}}

# Build container image for live booting
build-live-container-img:
    {{podman}} build -t {{live_img}} {{justfile_directory()}}

# Build initrd with bootc-live dracut module, save to $PWD/initrd.img
build-initrd: 
    just _run /bin/sh /work/for-container.sh build-initrd

# Build initrd with bootc-live-net dracut module, save to $PWD/initrd.img
build-initrd-net:
    just _run /bin/sh /work/for-container.sh build-initrd-net

# Build initrd with bootc-live-registry dracut module, save to $PWD/initrd.img
build-initrd-registry:
    just _run /bin/sh /work/for-container.sh build-initrd-registry

# Build initrd with all bootc-live modules, save to $PWD/initrd-all-mods.img
build-initrd-all-mods:
    just _run /bin/sh /work/for-container.sh build-initrd-all-mods

# Copy kernel image from bootc image to $PWD/kernel.img
copy-kernel: 
    just _run /bin/sh /work/for-container.sh copy-kernel

# Create oci archive for rootfs, $PWD/root.oci
build-rootfs-oci:
    cd {{justfile_directory()}} && {{skopeo}} copy containers-storage:{{live_img}} oci-archive:root.oci:latest

# Create $PWD/rootfs.img, which is root.oci wrapped in cpio
build-rootfs-img: build-rootfs-oci
    cd {{justfile_directory()}} && echo root.oci | {{cpio}} -vo -R root:root --format=newc | gzip -9 > rootfs.img

# Create $PWD/initrd-full.img which is initrd.img combined with rootfs.img
build-full-img: build-initrd build-rootfs-img
    cd {{justfile_directory()}} && cat initrd.img rootfs.img > initrd-full.img

# Create UKI with built images
build-uki variant="full" cmdline="root=bootc-live:/root.oci":
    [ "{{variant}}" != "none" ] && postfix=-{{variant}} || postfix= ; \
    /usr/lib/systemd/ukify build --linux=kernel.img --initrd=initrd${postfix}.img \
    --cmdline="{{cmdline}}" --output=bootc-live${postfix}.efi

run-vm initrd="initrd-full.img" cmdline="root=bootc-live:/root.oci" mem="16G" cores="4":
    cd {{justfile_directory()}} && {{qemu}} \
        -kernel kernel.img -initrd {{initrd}} -m {{mem}} \
        -accel kvm -cpu host -smp {{cores}} \
        -device virtio-serial-pci,id=virtio-serial0 \
        -chardev stdio,id=charconsole0 \
        -overcommit mem-lock=on-fault \
        -device virtconsole,chardev=charconsole0,id=console0 \
        -display none \
        -append "console=hvc0 {{cmdline}}"

_volume_flags := \
    f'-v {{modules/"95bootc-live-zram"}}:/usr/lib/dracut/modules.d/95bootc-live-zram '+\
    f'-v {{modules/"98bootc-live-net"}}:/usr/lib/dracut/modules.d/98bootc-live-net '+\
    f'-v {{modules/"98bootc-live-registry"}}:/usr/lib/dracut/modules.d/98bootc-live-registry '+\
    f'-v {{modules/"99bootc-live"}}:/usr/lib/dracut/modules.d/99bootc-live '+\
    f'-v {{modules/"99bootc-live-kexec"}}:/usr/lib/dracut/modules.d/99bootc-live-kexec '+\
    f'-v {{invocation_directory()}}:/work '

# Runs command in the builder image
_run +CMDS:
    {{podman}} run --rm -it --entrypoint "" \
        {{_volume_flags}} {{builder_img}} {{CMDS}}