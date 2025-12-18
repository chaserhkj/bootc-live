# bootc-live

(WIP) Dracut modules to load a bootable container image in oci-archive format as live system.

## Proof of concept

Currently this module can boot up a fedora-coreos bootc image. But there are still a few missing
pieces and the initramfs does not recognize itself as booting a live image. As a result SELinux rules
and a bunch of other stuff like ignition is still broken, but you can try this out by:

```bash
$ just build-test-container
... Builds test containers image on top of quay.io/fedora/fedora-coreos to work with
$ just
... Builds kernel.img and initrd-full.img (initrd with embedded oci archive file)
$ just run-vm initrd-full.img "root=bootc-live:/root.oci"
... Calls qemu/kvm to boot VM from the generated artifacts
```
