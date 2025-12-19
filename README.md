# bootc-live

Dracut modules to load a bootable container image in oci-archive format as live system.

## How it works

- Embeds [umoci](https://github.com/opencontainers/umoci) into initramfs
- Obtains an OCI archive file at runtime by one of these ways:
    - Fetching an OCI archive file from a URL (`bootc-live-net`)
    - Reading an OCI archive file in initramfs that is pre-embedded
    - Reading an OCI archive file in initramfs that is append-loaded by PXE
- Extracts that oci archive file into a runtime bundle in memory
- Mounts entire rootfs readonly, /etc and /var read-write
- Pivot to in-memory rootfs and continue boot

Need at least memory twice the size of the image to work properly.

## Prepare image for live boot

Not all bootc images are suitable for live boot, some parts would need tweak to work, particularly:

- All SELinux labels set on the in-memory file tree before policies are loaded will be lost, resulting in a total break down of any SELinux system. Just disabling it would save a lot of work.
- Some distribution may carry default system services that assume the system is running on a disk-backed storage. e.g. `bootloader-update.service` in fedora

See [Containerfile.live](Containerfile.live) for an example of live-bootable fedora bootc image.

## Try it out

Try it out via `just` recipes:

Build builder image:

```bash
just build-builder-container-img
```

Build live image:

```bash
just build-live-container-img
```

Prepare kernel image:

```bash
just copy-kernel
```

Build initrd with embedded oci archive, suitable for testing in VMs

```bash
just build-full-img
```

Testing embedded initrd within qemu/kvm: (this calls sudo)

```bash
just run-vm
```

`kernel.img` and `initrd-full.img` produced by these recipes are suitable as boot artifacts, just add kernel cmdline `root=bootc-live:/root.oci` to boot

Or alternatively you can use `kernel.img`, then append-load both `initrd.img` and `rootfs.img` initrd from PXE.

### Net boot

Net boot allows specifying an oci archive file to fetch remotely. To get a net boot capable initramfs, with live and builder image already built, run recipe:

```bash
just build-initrd-net
```

Then run recipe

```bash
just build-rootfs-oci
```

This would produce a `root.oci` file, serve this file somewhere, say over http or something.

Then we can test net boot in VM by:

```bash
just run-vm initrd-net.img "root=bootc-live:http://url/to/root.oci"
```

`kernel.img` and `initrd-net.img` can be used to perform similar boots on a real machine.

## Kernel cmdline reference

Takes rootfs specification of format

```bash
root=bootc-live:/path/to/oci/file/in/initramfs.oci
```

Or for net boot

```bash
root=bootc-live:supported-protocol://url/to/rootfs.oci
```

For all supported protocols, see [dracut](https://github.com/dracutdevs/dracut) `url-lib` module.

OCI archives need an in-archive label to specific the particular image, this could be specified by `bootclabel=` kernel cmdline. If omitted, default to `latest`.
