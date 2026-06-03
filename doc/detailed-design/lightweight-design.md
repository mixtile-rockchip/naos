# Lightweight Design

## 1. Choosing a Lightweight Base System

### 1.1 Background and Goals

NAOS targets **resource-constrained embedded environments** such as industrial control systems, edge devices, and kiosks. The operating system is expected to provide:

- a small image footprint
- fast boot time
- low CPU, memory, and storage usage
- easy customization and maintenance
- package management support for later upgrades and feature expansion

To meet these goals, NAOS uses **Alpine Linux** as its base operating system.

### 1.2 Why Alpine Linux

| Feature | Description | Value to NAOS |
|---------|-------------|---------------|
| **musl libc + BusyBox** | Lighter than glibc; BusyBox integrates common commands such as `ls`, `sh`, and `cat` | Smaller system and faster startup |
| **Very small base image** | The base image can often be only a few MB to a few tens of MB | Lower storage and memory usage |
| **Efficient package manager: apk** | Fast install, upgrade, dependency handling, version control, and repository management | Easier customization, updates, and maintenance |
| **Minimal installation profile** | Official minimal installation path installs only required packages | Good foundation for rootfs minimization |

---

## 2. RootFS and Applications: Minimized Build and Trimming

### 2.1 RootFS Minimization

The NAOS root filesystem is built from the official Alpine **minirootfs** archive, for example `alpine-minirootfs-3.22.0-aarch64.tar.gz`. It is customized inside a chroot environment to produce a **NAOS-specific minimal base image**.

The design rule is simple: **install only what the system needs, and remove non-essential services, tools, documents, and files to control image size and runtime overhead at the source.**

**Build flow**:

1. Download the official Alpine minirootfs archive.
2. Extract it into the build directory and create a chroot environment.
3. Copy custom APK packages into the rootfs from `PACKAGES_DIR`.
4. Inside chroot:

- update APK repository indexes
- install required system packages and applications
- configure OpenRC services with `rc-update`
- set system configuration such as hostname and version

5. Apply system-specific customization:

- configure UART access control
- set startup scripts
- enable custom services

**Version and platform handling**:

- system version is controlled by the `VERSION` environment variable, default `0.0.1`
- hostname is generated from the target `BOARD`
- multiple platforms are supported through `PLATFORM`

#### 2.1.1 Filesystem Layout

| Mount Point | Filesystem | Design Goal | Description |
|-------------|------------|-------------|-------------|
| `/` | `overlay` | Combine read-only rootfs with writable `/userdata` | Preserves a read-only base system while still allowing user-installed data |
| `/tmp` | `tmpfs` | Keep temporary files in memory | Suitable for temporary data, cache, and runtime files |

#### 2.1.2 Core Directories Kept in the Image

| Directory | Purpose |
|-----------|---------|
| `/bin` | Basic user commands such as `ls` and `cp` |
| `/sbin` | System administration commands such as `mount` |
| `/lib` | System libraries such as libc |
| `/etc` | System configuration |
| `/usr` | User programs and read-only data |
| `/dev`, `/proc`, `/sys` | Virtual filesystems |
| `/boot` | Boot files |

#### 2.1.3 Required Base Tools and Services

**Core system packages**:

| Tool / Service | Purpose | Reason |
|----------------|---------|--------|
| `alpine-base` | Alpine base system | Provides the minimum required runtime environment |
| `BusyBox` | Core commands such as `ls`, `sh`, and `cat` | Alpine default, replaces heavier GNU coreutils usage |
| `OpenRC` | Init system | Lightweight init system used by Alpine |

**Networking and connectivity**:

| Tool / Service | Purpose | Reason |
|----------------|---------|--------|
| `openssh-server` | SSH service | Supports CA-based authentication |
| `dhcpcd` | DHCP client | Automatic network configuration |
| `avahi`, `avahi-tools` | mDNS discovery | Zero-config service discovery |
| `iptables`, `ip6tables` | Firewall | Packet filtering and network control |
| `curl` | Runtime dependency of `hawkbit-updater` | Network requests and data transfer |

**System management**:

| Tool / Service | Purpose | Reason |
|----------------|---------|--------|
| `watchdog` | Watchdog service | Improves runtime resilience |
| `eudev` | Device node management | Lightweight `udev` replacement |
| `usbutils` | USB utilities | USB identification and management |
| `util-linux` | System tools | Provides `lsblk`, `mount`, and related tools |
| `parted` | Partition management | Disk layout operations |
| `chrony` | Time synchronization | NTP client |

**System services**:

| Tool / Service | Purpose | Reason |
|----------------|---------|--------|
| `acpid-openrc` | ACPI daemon | Power event handling |
| `dbus` | Message bus | Inter-process communication |
| `rsyslog` | System log service | Persistent logs |

**Library dependencies**:

| Tool / Service | Purpose | Reason |
|----------------|---------|--------|
| `json-glib` | JSON processing library | Dependency of `hawkbit-updater` |
| `bzip2-dev` | Compression library package | Dependency of `hawkbit-updater` |

**Custom services and scripts**:

| Tool / Service | Purpose | Description |
|----------------|---------|-------------|
| `hawkbit-updater` | OTA client | Customized OTA client for remote updates |
| `fix-solt` | Repair partition service | Custom partition repair logic |
| `otp` | OTP writing tool | One-time write of serial number and MAC address |
| `auto_set_mac.sh` | Automatic MAC setup | Sets MAC addresses during boot if hardware does not provide one |
| `link_part.sh` | Partition linking script | Partition mount and link management |
| `updateAB.sh` | A/B update script | A/B slot switching and handling |
| `reboot-loader` | Reboot to loader mode | Reboot into loader or maskrom mode |
| `wipe_userdata` | Clear user data | Remove user data |

#### 2.1.4 OpenRC Service Configuration

NAOS manages services through OpenRC. The following services are enabled by default. The rootfs should still be tailored to actual product needs.

**Default runlevel**:

- `sshd`
- `networking`
- `acpid`
- `dhcpcd`
- `dbus`
- `rsyslog`
- `avahi-daemon`
- `local`
- `watchdog`
- `hawkbit-updater`

**Boot runlevel**:

- `sysctl`
- `hostname`
- `chronyd`

**Custom startup tasks**:

Configured in `/etc/local.d/start-server.start`:

- `auto_set_mac.sh`
- `link_part.sh`
- `updateAB.sh`
- `fix-solt`

#### 2.1.5 UART Access Control

To satisfy security and compliance requirements, NAOS restricts UART access:

- disable standard serial login by removing all `tty` and `console` entries from `/etc/inittab`
- keep only the debug UART, such as `ttyFIQ0`, in `/etc/securetty` for root login during debugging and recovery

This reduces exposure in production while still preserving a controlled debug path.

---

## 3. Minimal Application Design

### 3.1 SSH Service

- **OpenSSH**: supports CA-based authentication and provides a widely supported remote access solution

## 4. Kernel Optimization

### 4.1 Goal

Reduce kernel size, improve boot time, and lower security risk while keeping required functionality intact.

### 4.2 Main Optimization Measures

**Remove dynamic modules**:

- kernel functionality required at runtime is compiled directly into the kernel with `=y`
- no dynamic module installation into the rootfs
- kernel functionality is decoupled from rootfs module payloads

**Benefits**:

- smaller kernel footprint due to no module files
- faster boot due to no module loading phase
- simpler update flow because the kernel is delivered as a single image
- fewer runtime dependency failures

---

## 5. Summary: Key Points of the Lightweight Base System

| Area | Implementation | Benefit |
|------|----------------|---------|
| **Base system** | Alpine Linux with musl and BusyBox | Small footprint, fast boot, easy package management |
| **RootFS trimming** | Built from `alpine-minirootfs` in chroot with only required packages | Minimal rootfs and reduced storage and memory usage |
| **Filesystem** | `ext4` with `noatime`, `tmpfs` for temporary paths, and `overlay` | Less write amplification and better performance |
| **Core tooling** | OpenSSH, BusyBox, OpenRC | Lightweight replacements while still meeting feature needs |
| **Libraries** | Keep only musl, libmodbus, OpenSSL, and core dependencies | Remove redundancy and focus on core functionality |
| **Kernel** | Statically compiled drivers and features on demand | Smaller kernel, faster boot, and no module coupling |

---

## Design Principle Summary

1. **Minimum necessary components**
2. **Static integration over runtime modules**
3. **Separate read-only system content from writable user data**
4. **Prefer stability over aggressive minimization**
5. **Preserve extensibility through APK package management**

---
