# This image includes the necessary tools for building live boot initramfs
FROM quay.io/fedora/fedora-bootc:latest

RUN dnf install -y umoci skopeo && dnf clean all