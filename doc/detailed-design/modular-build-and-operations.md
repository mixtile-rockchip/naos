# Modular Build, Unified Management, and Operations

## 1. Separated Build: U-Boot + Kernel, RootFS, and Applications

### 1.1 Design Goal

The build flow decouples core system components such as **U-Boot + kernel**, **base rootfs**, and **applications**. Each module has its own source, build script, and output, while upper-level control scripts expose a unified interface to standardize and automate the full build process.

**Note**: Because the encrypted FIT kernel image depends on the SPL boot key produced by the U-Boot build, U-Boot and the kernel are currently built together rather than fully separated.

### 1.2 Components and Responsibilities

| Module | Build Method | Output | Responsibility | Unified Interface |
|--------|--------------|--------|----------------|------------------|
| **U-Boot + Kernel** | scripts | `uboot.img`, `boot.img` | build U-Boot, support secure boot, configure DTB, optimize the kernel, pack a FIT image, and integrate filesystem encryption support | provides `uboot.img` and `boot.img` |
| **Base RootFS** | scripts | `rootfs.tar` or `rootfs/` | build a minimal rootfs from Alpine minirootfs | provides `rootfs` |
| **Application** | module-specific `build.sh` | container images and startup scripts, or traditional binaries and libraries | implement a standard build entry; containerized apps include Docker images and launch scripts | provides application APKs |

### 1.3 Application Packaging Styles

**Containerized applications**:

Applications are often delivered as containers together with their runtime environment.

1. **Application contents**:

- container image file such as a `.docker` archive
- startup script for launching and managing the container
- dependency declarations such as `docker`, `docker-compose`, and `fuse-overlayfs`

2. **Packaging flow**:

- install the container image into a target directory such as `/etc/`
- install the startup script into a system path such as `/usr/bin/`
- declare runtime dependencies

3. **Deployment**:

- install the application through the APK package manager
- launch the container through the installed script
- keep applications independent from the base image for easier updates

**Traditional applications**:

For non-containerized applications, the executable and required libraries are packaged directly into the APK.

### 1.4 Unified Build Interface

Each module provides a standard `build.sh` entry point and produces normalized outputs. The upper-level control script calls these build scripts and collects artifacts for packaging.

---

## 2. Package Management and Version Control with APK

### 2.1 Design Goal

NAOS uses Alpine's native **APK package manager** to package, version, publish, and deploy core system components such as bootloader images, kernel assets, drivers, configuration, and applications.

### 2.2 Packaging and Repository Management

Build artifacts are packaged into `.apk` files with `abuild` and published to a private APK repository. During system assembly, `apk add` is used to fetch the required component versions.

**Versioning**:

Each package has a version such as `1.0.0-r0`, which supports both upgrades and rollbacks.

---

## 3. Automated CI/CD Flow

The project automates the flow from source code to artifact publishing through **GitLab CI/CD**.

**Pipeline**:

```text
Git tag trigger -> build stage -> apkbuild stage -> upload stage
```

**Stage description**:

- **build**: build U-Boot, kernel, and rootfs; produce and cache build outputs
- **apkbuild**: package U-Boot, kernel, and rootfs into APKs in parallel
- **upload**: upload APKs to S3 and trigger repository index refresh through a webhook

---

## 4. Upgrade and Deployment

### 4.1 OTA and Offline Upgrade

| Upgrade Type | Method | Key Components | Notes |
|--------------|--------|----------------|-------|
| **Online OTA** | Deploy a HawkBit server, install a customized HawkBit agent on the device, and trigger upgrades through `upgrade-system` | HawkBit, update engine | devices check for updates regularly and upgrade automatically |
| **Offline** | Upload the upgrade package to the device manually or insert a USB drive to trigger the upgrade script through `udev` | `bee`, `upgrade-system` | suitable for no-network environments |

**Usage**:

**Web-based local upgrade**:

- upload the update package to the device
- run `upgrade-system -p path/update.img -r`
- omit `-r` if you want to reboot later

**USB upgrade**:

plug in the USB drive and let the device upgrade automatically.
For detailed operating steps, see the **USB upgrade** section in the [Build Guide](../user-guide/build-guide.md).

### 4.2 Batch Deployment

HawkBit version tags can be used to push a specific image version to multiple devices for centralized version control.

---

## 5. Image Generator

NAOS provides scripts to generate deployable system images quickly by pulling prebuilt components from the APK repository.

**Generation flow**:

```text
download components from APK repository -> customize rootfs -> create rootfs image -> copy boot images -> apply security configuration -> generate final image
```

**Key features**:

- reuse prebuilt components from the APK repository
- install custom APK packages and application payloads
- calculate image size automatically
- integrate filesystem encryption
- generate both full images and update packages

---

## 6. Chip-Independent GPIO Interface Through DTS

### 6.1 Design Goal

Provide a **unified GPIO programming interface** to upper-layer applications and drivers by hiding chip-specific details behind the device tree.

This is achieved by defining `gpio-name` in DTS so that:

- applications no longer depend on board-specific pinmux details
- access is standardized through symbolic names such as `LED_RED` or `BUTTON_POWER`
- new hardware platforms can be supported by updating DTS only

### 6.2 Implementation

Each GPIO pin is given a `gpio-name` property in DTS. Applications use that logical name instead of hard-coded hardware details. When the hardware platform changes, only the DTS needs to be updated.

---

## 7. Build and Operations Summary

**Build flow**:

source repository -> Git tag trigger -> build stage -> apkbuild stage -> upload stage -> private APK repository -> image generator -> final image

**Deployment flow**:

private repository or HawkBit -> OTA or offline upgrade -> device-side A/B slots -> automatic rollback

**Core advantages**:

- modular build
- automated CI/CD
- versioned management
- standardized interfaces
- easier deployment and operations
