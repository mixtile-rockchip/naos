# Security and Compliance Design

## 1. Secure Boot: Protecting Firmware and the Boot Chain

### 1.1 Goal

Ensure the **integrity and authenticity of firmware components such as SPL, U-Boot, and the kernel** during boot so that attackers cannot flash unauthorized or tampered boot software.

### 1.2 Design Principle

NAOS uses the **RK3588 secure boot mechanism** based on **FIT image signing plus an OTP-stored public key hash** to establish a **chain of trust**.

#### 1.2.1 Boot Sequence

**1. MaskROM**

- runs first after power-on
- loads the **SPL**
- reads the pre-burned **public key hash** from **OTP**
- verifies the **SPL image signature**

**2. SPL**

- initializes hardware and loads **`uboot.img`**
- verifies the U-Boot signature using the public key or key hash

**3. U-Boot**

- can further verify the **kernel image**, **device tree**, and optionally filesystem images
- continues the signature-based chain of trust for later stages

According to the SDK documentation, RK3588 secure boot is based on FIT plus OTP verification.

### 1.3 Implementation Steps

#### 1.3.1 Enable Secure Boot Options in U-Boot

Add or confirm the following options in the board defconfig:

```config
CONFIG_OPTEE_CLIENT=y
CONFIG_OPTEE_V2=y
CONFIG_OPTEE_ALWAYS_USE_SECURITY_PARTITION=y
CONFIG_FIT_SIGNATURE=y
CONFIG_SPL_FIT_SIGNATURE=y
```

#### 1.3.2 Generate a Key Pair

Use Rockchip's `rk_sign_tool` to generate an RSA or ECC signing key pair:

- **private key**: used to sign firmware such as `boot.img`, `uboot.img`, and `loader.bin`
- **public key**: its hash is written into OTP in production

#### 1.3.3 Burn the Public Key Hash into OTP

- use `rk_sign_tool` or Rockchip secure programming tools
- write the public key hash into the OTP area
- OTP is one-time programmable, so validate the key carefully before mass production

#### 1.3.4 Sign the Firmware

Example:

```bash
./make.sh rv1126 --spl-new --boot_img boot.img
```

In `build.sh`, the related build step is:

`build_uboot --spl-new --boot_img boot.img #--burn-key-hash`

By default, key burning is disabled. If you need secure boot with OTP programming during startup, uncomment `--burn-key-hash`.

**Signed artifacts**:

- `boot.img`
- `uboot.img`
- `loader.bin`

**Signing process**:

1. sign the firmware image with the private key
2. embed signature metadata into the FIT image
3. verify against the OTP public key hash during boot

**Reference**: `Rockchip_Developer_Guide_Linux_Secure_Boot_CN.pdf`

---

## 2. Full-Disk Protection: Securing Data and System Storage

### 2.1 Goal

Protect **user data, system images, and configuration files** stored on the device against disclosure after loss or physical access.

### 2.2 Design Principle

NAOS uses **Linux Device Mapper encryption and integrity layers (`dm-crypt` + `dm-verity`)** for partition-level protection:

- **encryption**: encrypt target partitions with `dm-crypt`
- **decryption**: unlock them at boot using keys stored in a secure area
- **integrity**: validate disk data with `dm-verity`
- **key storage**: keep encryption keys inside **RPMB** to resist physical extraction

### 2.3 Implementation Steps

#### 2.3.1 Enable Required Kernel Options

```config
CONFIG_BLK_DEV_DM=y
CONFIG_DM_CRYPT=y
CONFIG_BLK_DEV_CRYPTOLOOP=y
CONFIG_DM_VERITY=y
```

#### 2.3.2 Build the Encrypted Filesystem

- use SDK-provided tools or scripts to generate the encrypted initramfs or data partition image
- mount it through the `dm-verity` and `dm-crypt` stack

#### 2.3.3 Key Management

**Key lifecycle**:

1. **first boot**

- generate a random encryption key
- use it to encrypt the user-data partition
- temporarily store the key in the `misc` partition

2. **key migration**

- move the key from `misc` into the **RPMB partition**
- RPMB is hardware protected against unauthorized reads and tampering

3. **key cleanup**

- erase the temporary key from `misc` after migration succeeds

4. **later boots**

- read the key from RPMB
- decrypt the encrypted partition
- mount the filesystem

#### 2.3.4 Decrypt During Boot

- modify boot scripts, for example in initramfs, so that target partitions are decrypted before mounting the root or user-data filesystem
- mount the decrypted block device afterwards

**Reference**: `Rockchip_Developer_Guide_Linux_Secure_Boot_CN.pdf`

---

## 3. Compliance: UART and SSH Access Restrictions

### 3.1 Goal

Restrict external access interfaces such as **UART and SSH** so that only authorized users and devices can connect and debug the system.

### 3.2 Implementation

#### 3.2.1 UART Access Control

**Security measures**:

- disable serial login services such as `getty`
- remove `tty` and `console` entries from `/etc/inittab`
- preserve only the required debug UART, such as `ttyFIQ0`, in `/etc/securetty`

**Security outcome**:

- prevents unauthorized serial access
- reduces the exposed attack surface
- preserves a limited debug path for recovery and diagnostics

#### 3.2.2 SSH Remote Debugging Hardening

**Tool choice**:

NAOS uses **OpenSSH** because it supports a complete CA-based certificate authentication model suitable for enterprise-grade access control.

**Security measures**:

- disable password login and require certificates
- centralize identity management through a CA
- support certificate lifetime control and expiry

**Configuration steps**:

**Step 1: sign a user certificate**

```bash
ssh-keygen -s ssh_ca_key \
    -I "dev-cert-001" \
    -n root \
    -V "always:+3650d" \
    ~/path-to/user_public_key.pub
```

Parameters:

- `-I`: certificate identifier for auditing
- `-n root`: allowed login user
- `-V "always:+3650d"`: certificate lifetime

Generated file: `user_public_key-cert.pub`

**Step 2: deploy the certificate to the client**

```bash
~/.ssh/user_private_key
~/.ssh/user_public_key-cert.pub
```

Once deployed with the matching private key, the client can log in without a password.

**Notes**:

- keep the CA private key offline and protected
- adjust the certificate validity period according to policy
- different users can receive different certificates and permissions
- regular SSH keys can be upgraded into CA-signed certificates for centralized management

---

## 4. Security Architecture Summary

### 4.1 Security Layers

| Layer | Implementation | Protection Goal |
|-------|----------------|-----------------|
| **Hardware** | Secure Boot with FIT + OTP | Prevent tampered firmware and protect the boot chain |
| **Storage** | Full-disk protection with `dm-verity` and `dm-crypt` | Protect data at rest |
| **Access** | UART and SSH access control with certificate authentication | Prevent unauthorized access |

### 4.2 Key Management

| Key Type | Storage Location | Protection Mechanism |
|----------|------------------|----------------------|
| Secure boot public key hash | OTP | hardware protected and immutable |
| Filesystem encryption key | RPMB | protected eMMC secure region |
| SSH CA private key | secure development storage | offline storage and strict access control |

### 4.3 Compliance Objectives

- firmware integrity
- encrypted storage
- restricted access
- certificate-based identity verification
