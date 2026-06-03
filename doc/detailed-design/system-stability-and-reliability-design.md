# System Stability and Reliability Design

## 1. Seamless A/B Upgrade and Rollback

### 1.1 Goal and Background

To improve reliability and availability during **OTA updates** and **field upgrades**, NAOS uses an **A/B partition strategy** that provides:

- **seamless upgrade**: write the new system image to the inactive slot and switch slots after reboot
- **automatic rollback**: fall back to the last known-good slot if the new system cannot boot
- **automatic repair**: rebuild the failed slot after the healthy slot runs stably for a period of time

### 1.2 Design and Flow

#### 1.2.1 Enable A/B Support

Enable A/B support in U-Boot:

```config
CONFIG_SPL_AB=y
```

#### 1.2.2 Partition Layout

| Partition | Image | Description |
|-----------|-------|-------------|
| `loader` | `Miniloader.bin` | first-stage loader |
| `uboot_a` | `uboot.img` | primary second-stage bootloader; includes `trust.img` for secure boot |
| `uboot_b` | `uboot.img` | backup of `uboot_a` |
| `misc` | `misc.img` | boot parameters, A/B state, and temporary encryption key storage |
| `boot_a` | `boot.img` | kernel + dtb for `system_a` |
| `boot_b` | `boot.img` | kernel + dtb for `system_b` |
| `system_a` | `rootfs.img` | encrypted read-only root filesystem |
| `system_b` | `rootfs.img` | encrypted read-only root filesystem |
| `userdata` | `userdata.img` | writable data partition |

#### 1.2.3 Upgrade, Rollback, and Repair

**1. Upgrade flow**

- write the new images such as `system_b`, `boot_b`, and `uboot_b` into the inactive slot
- call `updateEngine --image_url=./update.img --update --reboot`
- update the boot flag in `misc`
- reboot and let the pre-loader select the next boot slot
- if boot succeeds, the new slot becomes active
- if boot fails, roll back automatically

**2. Rollback flow**

- if the new slot fails to boot, the pre-loader or kernel detects the failure
- the boot marker is restored to the previous slot
- the device reboots into the known-good system
- rollback can also be triggered manually through the relevant tooling

**3. Automatic repair**

- when one slot is marked failed, the device switches to the healthy slot
- after the healthy slot runs stably, the failed slot is repaired from the healthy image
- both slots return to a good state

### 1.3 Unified Upgrade Interface

NAOS provides `upgrade-system` as a unified upgrade command:

```bash
upgrade-system [options]

Options:
  -p, --path <image_path>  path to the image file, default /userdata/update.img
  -r, --reboot             reboot after upgrade
  -t, --timeout <seconds>  timeout in seconds
```

**Example**:

```bash
upgrade-system -p /tmp/custom_update.img -r
```

**Workflow**:

1. upload the update package to the device
2. run `upgrade-system`
3. let the tool invoke `updateEngine`
4. reboot automatically if requested

### 1.4 Offline Upgrade

**Method**:

- firmware is protected through certificate-based packaging
- inserting a USB drive triggers the upgrade automatically

For detailed operating steps, see the **USB upgrade** section in the [Build Guide](../user-guide/build-guide.md).

### 1.5 OTA Upgrade

NAOS uses HawkBit together with the custom upgrade interface. For setup details, see [Cloud Environment Setup](../user-guide/cloud-environment-setup.md).

---

## 2. Factory Test Interface and Automated Test Support

### 2.1 Goal

Provide a **standardized, automated, and interactive factory test flow** for manufacturing, hardware verification, and diagnostics.

### 2.2 Design and Implementation

#### 2.2.1 Approach

- use an existing Qt-based GUI as the test interface
- boot the test image from a USB drive
- support building a dedicated factory-test image

#### 2.2.2 Entry Conditions

**Hardware trigger**:

- insert the factory-test USB drive
- hold the recovery signal low or press the recovery button
- once the condition is detected, the device enters factory-test mode automatically

This logic is implemented in the ramdisk init script `init_dm_sample`. The current implementation also checks whether `/mnt/etc/factory` exists on the USB filesystem. You can adjust the detection logic as needed.

**Test flow**:

1. detect factory-test conditions
2. load the test partition image from the USB drive
3. start the Qt test application
4. run automated hardware verification
5. show test results and allow operator interaction

---

## 3. Unattended Runtime: Watchdog and Panic Recovery

### 3.1 Goal

Ensure the system can **detect hangs, kernel crashes, and service failures automatically** and recover without manual intervention in long-running unattended deployments.

### 3.2 Implementation

#### 3.2.1 Kernel Watchdog Configuration

Enable the Rockchip hardware watchdog in DTS:

```dts
&wdt {
    status = "okay";
};
```

This exposes the watchdog interface through `/dev/watchdog`.

#### 3.2.2 User-Space Watchdog

NAOS uses the BusyBox-integrated `watchdog` process to feed the hardware watchdog periodically.

**Enable it through OpenRC**:

```bash
rc-update add watchdog default
```

**How it works**:

1. the watchdog daemon writes regularly to `/dev/watchdog`
2. if the system hangs or the daemon exits unexpectedly, feeding stops
3. the hardware watchdog resets the device

#### 3.2.3 Kernel Panic Recovery

**Device tree bootargs**:

```dts
&chosen {
    bootargs = "earlycon=uart8250,mmio32,0xfeb50000 console=ttyFIQ0 irqchip.gicv3_pseudo_nmi=0 panic=3 rcupdate.rcu_expedited=1 rcu_nocbs=all";
};
```

**Sysctl configuration**:

Create `/etc/sysctl.d/panic.conf` in the rootfs:

```config
kernel.panic = 3
```

`panic=3` means the system reboots automatically 3 seconds after a kernel crash.

#### 3.2.4 Validation

1. ensure the watchdog DTS node is enabled and panic parameters are present
2. install and enable the watchdog service:

```bash
rc-update add watchdog default
rc-service watchdog start
```

3. test recovery:

- stop the watchdog process intentionally and verify automatic reboot
- trigger a kernel panic, for example with `echo c > /proc/sysrq-trigger`, and verify reboot after 3 seconds

---

## 4. Log Preservation

### 4.1 Regular Logs

System logs and custom script logs are written into `/var/log` for persistent storage.

**Log categories**:

- system logs collected by syslog
- application logs
- service logs

**Log management**:

- log rotation should be enabled to avoid uncontrolled growth
- logs can be used for field diagnostics and failure analysis

### 4.2 Preserving `dmesg`, Especially Crash Logs

#### 4.2.1 Goal

Preserve kernel `dmesg` output, especially the messages generated before a kernel crash, so post-mortem diagnostics remain possible.

#### 4.2.2 Design and Implementation

**Kernel configuration**:

```config
CONFIG_PSTORE=y
CONFIG_PSTORE_CONSOLE=y
CONFIG_PSTORE_RAM=y
```

**How it works**:

1. **save on crash**

- when the kernel crashes, `panic=3` leaves enough time to save `dmesg` into a reserved RAM area

2. **restore on next boot**

- on the next boot, the kernel reads the preserved data and exposes it under `/sys/fs/pstore`

3. **archive it**

- a custom script such as `save-dmesg.sh` copies the preserved logs into `/var/log`

**Flow**:

```text
kernel crash -> panic=3 -> dmesg saved in RAM -> reboot
system boots -> pstore restores logs -> /sys/fs/pstore -> save-dmesg.sh -> /var/log
```

**Benefits**:

- capture the final log messages before a crash
- no external debugger required
- support repeated crash archiving

---

## 5. Reliability Summary

### 5.1 Multi-Layer Protection

| Layer | Implementation | Goal |
|-------|----------------|------|
| **Upgrade protection** | A/B slots + rollback + repair | prevent upgrade failure from bricking the system |
| **Runtime protection** | hardware watchdog + user-space watchdog | recover from hangs automatically |
| **Crash protection** | kernel panic auto-reboot | recover from kernel failures |
| **Log protection** | `pstore` + log archive | preserve diagnostics |

### 5.2 Reliability Metrics

- **availability**: A/B slot design with rollback keeps upgrade success near production-grade expectations
- **recovery time**: reboot within seconds after panic or watchdog timeout
- **diagnostics**: persistent logging supports root-cause analysis

### 5.3 Typical Use Cases

- industrial control devices
- edge computing devices
- smart display devices
- IoT gateways
