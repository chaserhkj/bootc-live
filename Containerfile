FROM quay.io/fedora/fedora-coreos:stable

RUN dnf install -y umoci && dnf clean all