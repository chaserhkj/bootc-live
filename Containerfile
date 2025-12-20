# Builder image with the necessary tools for building live boot initramfs
FROM quay.io/fedora/fedora-bootc:latest as builder

RUN dnf install -y umoci skopeo && dnf clean all

# initramfs building pipeline within containers
# builds initramfs with all bootc-live modules enabled

FROM builder as initramfs-build

COPY . /work
WORKDIR /work

RUN for mod in /work/modules.d/* ; do ln -s $mod /usr/lib/dracut/modules.d; done;
RUN /bin/sh for-container.sh build-initrd-all-mods

# This image includes correct configurations to be booted as live system
FROM quay.io/fedora/fedora-bootc:latest

# Replace the embedded initramfs with bootc-live version
# This is for bootc-live-kexec to work
RUN --mount=type=bind,from=initramfs-build,target=/tmp \
    cp -f /tmp/work/initrd-all-mods.img /usr/lib/modules/*/initramfs.img

# SELinux is disabled by default for all fedora live systems
# We should disable it here as well to make everything work
RUN sed -i 's/^SELINUX=.*$/SELINUX=disabled/g' /etc/selinux/config

# bootloader update really makes no sense in a live system
RUN systemctl disable bootloader-update.service

# Create a user "liveuser" without password, and configure sudo for it
RUN useradd -m liveuser && passwd -d liveuser && \
    echo 'liveuser ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/99_liveuser