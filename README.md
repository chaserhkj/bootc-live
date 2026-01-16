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

See [Containerfile](Containerfile) for an example of live-bootable fedora bootc image.

### Notes on Fedora CoreOS (FCOS) Images

While FCOS container images like `quay.io/fedora/fedora-coreos:stable` are bootc-compatible, using these together with this project will NOT give you an live system equivalent to a CoreOS live system. This is because on top of a dracut-generated initramfs, FCOS does a lot of extended stuff through [coreos-assembler](https://github.com/coreos/coreos-assembler) and [osbuild](https://github.com/osbuild/osbuild) to handle iso image, ignition, etc.  (see [this file](https://github.com/osbuild/osbuild/blob/f295fc5489eb47d22f97408c33e5a4e7c11e1cd1/stages/org.osbuild.coreos.live-artifacts.mono) for details)

However you can still make these images work through some modifications mentioned above. But `fedora-bootc` might be a leaner and better starting point if you need to do the mods anyways.

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

### Registry boot

Registry boot enabled by module `bootc-live-registry` further allows specifying an image from a registry to be used as rootfs

This uses [skopeo](https://github.com/containers/skopeo) under the hood and increases the size of initramfs for quite a bit, so be aware if that's a contraint for you.

Similarly use recipe:

```bash
just build-initrd-registry
```

Push the live image built previously to some accessible registry, or you can use `docker.io/chaserhkj/fedora-bootc-live` from me

Then we can test registry boot in VM by:

```bash
just run-vm initrd-registry.img "root=bootc-live:docker://docker.io/chaserhkj/fedora-bootc-live"
```

`kernel.img` and `initrd-registry.img` can be used to perform similar boots on a real machine.

### Kexec

When using net boot/registry boot, since kernel first loaded for booting and kernel modules in the rootfs can be fetched from different sources, there is a risk of version drift when the rootfs container image is updated but PXE/bootloader is still loading the old kernel and initramfs.

This can be mitigated by using the `bootc-live-kexec` module. With kernel args `bootc.kexec=1` set, the initramfs will attempt to use [kexec](https://en.wikipedia.org/wiki/Kexec) to load the kernel from the rootfs image and handle over execution. All kernel args to the boot kernel will be used for the new kernel except `bootc.kexec`.

This essentially uses the boot kernel and initramfs as a chain loader to load the boot artifacts from the roofs bootc image.

You can do some really fancy tricks with this, e.g. booting to different distro bootc containers from the same set of boot artifacts, just change the boot kernel args.

### Zram

By default all oci archive extraction and unpacking operations are done in initramfs. This by default has a maximum size of half of the total system memory. For larger rootfs this may pose a problem.

`bootc-live-zram` could partially resolve this by compressing the contents of rootfs in-place in memory. Enable this by adding kernel arg `bootc.zram=<zram disk size>`, e.g. `bootc.zram=8G` to allocate a ram disk with a compressed size of 8GiB.

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

For registry boot

```bash
root=bootc-live:docker://your.registry.com/repo/image-name:image-tag
```

If your registry is served over HTTP (e.g. local registry on LAN or VPN), you can set `bootc.registry.unsecure(=1)` to use it.

OCI archives need an in-archive label to specific the particular image, this could be specified by `bootclabel=` kernel cmdline. If omitted, default to `latest`.

To enable kexec and boot with kernel/initramfs from the bootc image, set `bootc.kexec(=1)`

When kexec is enabled, bootc-live will attempt to reuse the downloaded OCI image by repacking it into the next stage initramfs, so that next stage will not need to download the image again. However this will induce more memory usage. Set `bootc.kexec.reuse-image=0`

To enable zram compression, set `bootc.zram=<zram disk size>`

When mounting the pulled image in initramfs, bootc-live has two modes of operation:

1. Bind mount mode: rootfs will be bind-mounted to be the new root, this is the default
2. EROFS mode: rootfs will be made into an EROFS image and mounted to be the new root, the EROFS image will be set to have a fixed null UUID and all timestamps are set to Unix epoch. This has the benefit of reproducibility and would make any consistent state verification from the booted image much easier. set karg `bootc.live.erofs(=1)` to enable

By default, the rootfs will be mounted as readonly. Set `rw` on kernel cmdline to override. Note that:

1. `ro` on kernel cmdline is always ignored, to override a previously set `rw` flag, append `rw=0` to kernel cmdline instead.
2. This will have no effect with EROFS mode since all EROFS images are read only.

By default, `/var` and `/etc` will be mounted read-write (under EROFS they are copied to make that happen), set `bootc.live.var.rw=0` or `bootc.live.etc.rw=0` to disable
