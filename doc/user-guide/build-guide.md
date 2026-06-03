# Build Guide

# NAOS Build Guide

## 1. Get the Source Code

```bash
git clone https://github.com/mixtile-rockchip/naos.git
cd naos
```

### 1.1 Project Structure

**Main directories**:

```text
build/
├── build.sh           # Main build script
├── board/             # Board-specific files (device tree, defconfig)
├── apk/               # APK packaging templates (APKBUILD)
├── packages/          # Build outputs and configuration files
│   ├── alpine/        # Alpine base system configuration
│   ├── alpine-extras/ # Alpine custom extension configuration
│   ├── configs/       # Partition config files (package-file, parameter.txt, etc.)
│   ├── keys/          # Secure boot keys
│   └── ramdisk/       # Ramdisk files
├── patch/             # Patch files
├── resource/          # Resource files
├── scripts/           # Build scripts
│   ├── apply_patch.sh
│   ├── build_alpinefs_base.sh
│   ├── build_alpinefs_mixtile-core3588e.sh
│   ├── build_encryption.sh
│   ├── build_factory.sh
│   ├── build_kernel.sh
│   ├── build_ramdisk.sh
│   ├── build_raw.sh
│   ├── build_rootfs.sh
│   ├── build_uboot.sh
│   ├── build_update.sh
│   └── tools.sh
├── tools/             # Build tools
│   ├── genkey/        # Key generation tool (rk_sign_tool)
│   ├── linux_pack_firmware/
│   ├── linux_securitydm/
│   └── upgrade_key/
├── misc-tools/        # Auxiliary tools
│   ├── alpine-build/  # Alpine build container
│   ├── alpine-repo/   # APK repository service (nginx, webhook)
│   ├── build-env/     # Build environment container
│   └── hawkbit/       # HawkBit OTA server configuration
├── .gitlab-ci.yml     # GitLab CI main config
└── .gitlab-ci/        # Board-specific CI config
    ├── core3588e-nano.yml
    ├── core3588e-v2-nano.yml
    ├── core3588e-tx.yml
```

**Directory description**:

- `board/`: device trees and configuration files organized by board
- `apk/`: APK packaging templates such as `ubootAPKBUILD` and `kernelAPKBUILD`
- `packages/`: system configuration, keys, partition configuration, and related assets
- `scripts/`: build scripts grouped by purpose
- `tools/`: helper tools used during the build process
- `misc-tools/`: Docker files and supporting services

**Notes**:

- The project includes GitLab CI configuration for automated builds.
- The existing GitLab CI files were written for an older GitLab CI version, so compatibility updates may be required.
- You can use another CI/CD platform such as GitHub Actions, Jenkins, or a newer GitLab CI deployment.
- Treat the included CI files as a reference implementation.

## 2. Build Modes

NAOS supports two build modes.

### Mode 1: Build a Full Image Directly

Recommended for quick validation and development.

**Best for**:

- quick testing
- development bring-up
- single-shot builds
- environments that do not need versioned package management

**Flow**:
Step 1 import device tree -> Step 2 replace secure boot keys -> Step 3 replace encryption key -> Step 4 build firmware

**Advantages**:

- one-step build flow
- no APK repository required
- fast feedback loop

**Output**: `build/output/update.img`

### Mode 2: Separated Build + APK Packaging

Recommended for production use.

**Best for**:

- production deployment
- versioned releases
- batch deployment
- image customization with reusable artifacts

**Flow**:

1. Step 1 import device tree
2. Step 2 replace secure boot keys
3. Step 3 replace encryption key
4. Step 4 build firmware with the `packages` target
5. Step 5 package APKs
6. Step 6 upload packages to the repository
7. Step 7 generate the final image with the image generator

**Reference**: See [Image Generator Guide](./image-generator-guide.md).

**Advantages**:

- no need to rebuild U-Boot, kernel, and rootfs every time
- supports installation of custom APK packages during image generation
- easier version management and batch deployment
- easier CI/CD integration

**Output**: versioned APK packages plus a final deployable image generated later

---

## 3. Detailed Steps

### Step 1: Import Device Tree and Configuration for a New Board

**File structure**:

```text
board/
└── mixtile-core3588e/
    ├── kernel/
    │   └── 6.1/
    │       ├── mixtile-core3588e_defconfig
    │       └── mixtile-core3588e.dts
    └── uboot/
        ├── mixtile-core3588e_defconfig
        └── mixtile-core3588e.dts
```

**Naming rules**:

- product directory: `mixtile-xxx`, for example `mixtile-core3588e`
- device tree file: `mixtile-xxx.dts`
- config file: `mixtile-xxx_defconfig`
- the `mixtile` prefix itself is not mandatory, but the prefixes must match exactly

**Required U-Boot configuration**:

```config
CONFIG_OPTEE_CLIENT=y
CONFIG_OPTEE_V2=y
CONFIG_OPTEE_ALWAYS_USE_SECURITY_PARTITION=y
CONFIG_FIT_SIGNATURE=y
CONFIG_SPL_FIT_SIGNATURE=y
CONFIG_SPL_AB=y
```

**Required kernel configuration**:

```config
CONFIG_BLK_DEV_DM=y
CONFIG_DM_CRYPT=y
CONFIG_BLK_DEV_CRYPTOLOOP=y
CONFIG_DM_VERITY=y
CONFIG_PSTORE=y
CONFIG_PSTORE_CONSOLE=y
CONFIG_PSTORE_RAM=y
```

**Note**: The kernel and filesystem are intentionally separated. NAOS does not rely on loadable kernel modules, and required drivers are compiled directly into the kernel.

**Optional watchdog configuration**:

Add the following node to the device tree:

```dts
&wdt {
    status = "okay";
};
```

### Step 2: Replace Keys

NAOS uses four categories of keys:

- secure boot keys
- filesystem encryption key
- SSH CA key
- USB offline upgrade keys

#### 2.1 Replace Secure Boot Keys

**Key directory**: `packages/keys/`

**Generate keys**:

```bash
cd tools/genkey
./rk_sign_tool cc --chip 3588
./rk_sign_tool kk --out .
mv private_key.pem dev.key
mv public_key.pem dev.pubkey
openssl req -batch -new -x509 -key dev.key -out dev.crt
cp dev.crt dev.key dev.pubkey ../../packages/keys/
```

**Important**:

- Keep `dev.crt`, `dev.key`, and `dev.pubkey` somewhere safe for future use.
- Replace all existing keys in `packages/keys/`.

#### 2.2 Replace the Filesystem Encryption Key

**Key file**: `tools/linux_securitydm/encrypted_key`

**Default format**:

```text
key=0d4ada86b407c87b43784e918763ecdd79cd685b014be1f73e915fdeffced4b9
```

**Generate a new key**:

```bash
openssl rand -hex 32
```

Replace the default value in the file with the generated key.

#### 2.3 Replace the SSH CA Public Key

**Target path**: `packages/alpine/etc/ssh/ssh_ca_key.pub`

Generate a CA key pair in a secure environment. `ed25519` is recommended:

```bash
ssh-keygen -t ed25519 -f ssh_ca_key -C "core3588e cert"
```

**Generated files**:

- `ssh_ca_key`: CA private key, keep it offline and protected
- `ssh_ca_key.pub`: CA public key, deploy it to the SSH server

Replace `packages/alpine/etc/ssh/ssh_ca_key.pub` with the generated public key.

For user certificate signing, see the SSH hardening section in [Security and Compliance Design](../detailed-design/security-and-compliance-design.md).

#### 2.4 Replace Offline Upgrade Keys

**Target path**: `packages/alpine/etc/upgrade`

**Generate and replace keys**:

```plain
cd tools/upgrade_key

# Generate RSA private key
openssl genpkey -algorithm RSA -out private.pem -pkeyopt rsa_keygen_bits:2048

# Export public key and deploy it to /etc/upgrade
openssl rsa -in private.pem -pubout -out public.pem

# Generate a 256-bit AES key and deploy it to /etc/upgrade
openssl rand -hex 32 > aes.key

cp aes.key public.pem ../../packages/alpine/etc/upgrade

# Keep private.pem in the current directory for later firmware encryption
```

### Step 3: Build Firmware

#### 3.1 Partition Layout

**Default partition table**:

| Partition | Image | Description |
|-----------|-------|-------------|
| `loader` | `Miniloader.bin` | First-stage loader |
| `uboot_a` | `uboot.img` | Second-stage bootloader, includes `trust.img` for secure boot and boots `boot_a` |
| `uboot_b` | `uboot.img` | Backup bootloader that boots `boot_b` |
| `misc` | `misc.img` | Boot parameters, A/B state, and temporary storage for encryption keys |
| `boot_a` | `boot.img` | kernel + dtb + ramdisk for `system_a` |
| `boot_b` | `boot.img` | kernel + dtb + ramdisk for `system_b` |
| `system_a` | `rootfs.img` | Encrypted read-only root filesystem |
| `system_b` | `rootfs.img` | Encrypted read-only root filesystem |
| `userdata` | `userdata.img` | Encrypted writable data partition |

**Partition configuration files**:

- `packages/configs/package-file`: physical partition layout
- `packages/configs/parameter_ab.txt`: logical partition sizes

Adjust size and layout as needed for your hardware.

#### 3.2 Build Command

**Show help**:

```bash
./build.sh -h
```

**Options**:

```text
Usage: ./build.sh [options]
Options:
  -t, --target <name>     Build target: uboot|kernel|alpine|all|rootfs|fit-boot|sign-boot|update|packages
  -b, --board <name>      Specify board name
  -p, --package <name>    Specify package name
  -h, --help              Show this help message
```

**Targets**:

- `uboot`: build U-Boot only
- `kernel`: build kernel only
- `alpine`: build rootfs content only
- `rootfs`: build the rootfs image
- `fit-boot`: generate a FIT boot image
- `sign-boot`: sign the boot image
- `update`: generate an update image
- `all`: build everything and generate the final image
- `packages`: build artifacts only, without generating the final image

#### 3.3 Build Modes

**Mode 1: build a full image directly**

```bash
./build.sh --target all --board mixtile-core3588e
```

**Mode 2: build artifacts only for later APK packaging**

```bash
./build.sh -t packages -b mixtile-core3588e
```

#### 3.4 Build in a Container

A containerized build is recommended because the build depends on many host packages.

**Use the prebuilt container**:

```bash
docker pull ghcr.io/mixtile-rockchip/ubuntu-build-env:latest
docker run --privileged -it \
    -v $PWD:/workspace \
    -v /dev:/dev \
    ghcr.io/mixtile-rockchip/ubuntu-build-env:latest
```

**Build the container locally**:

```bash
docker build -t ubuntu-22.04-build-env misc-tools/build-env/
docker run --privileged -it \
    -v $PWD:/workspace \
    -v /dev:/dev \
    ubuntu-22.04-build-env
```

**Container notes**:

- the container already includes the required toolchain and dependencies
- `--privileged` is required for device access
- the current workspace is mounted into `/workspace`

#### 3.5 Build Outputs

**Mode 1 output**:

- `build/output/update.img`: full flashable image

**Mode 2 output**:

- `build/output/MiniLoaderAll.bin`
- `build/output/uboot.img`
- `build/output/boot.img`
- `build/output/alpine-rootfs.tar.gz`
- `build/output/factory.img` (optional)

**Next step**:

- Mode 1: use `update.img` directly
- Mode 2: continue with Step 4 and Step 5

---

## 4. APK Packaging

### 4.1 Overview

This step packages built components such as U-Boot, kernel, and rootfs into Alpine APK packages for versioned distribution.

**Flow**:

```text
prepare build artifacts -> prepare Alpine build container -> configure APKBUILD template -> run abuild -> verify output -> upload to repository
```

### 4.2 Prepare Build Artifacts

Before packaging, make sure the build outputs exist in `build/output/`:

- `MiniLoaderAll.bin`
- `uboot.img`
- `boot.img`
- `alpine-rootfs.tar.gz`
- `factory.img` (optional)

### 4.3 Prepare the Alpine Build Container

**Use the prebuilt container**:

```bash
docker pull ghcr.io/mixtile-rockchip/alpine-build:latest
docker run -v $PWD/build:/home/builder/build \
           -v $PWD/apk:/home/builder/apk \
           -v $PWD/.abuild:/home/builder/.abuild \
           --name alpine-build -it ghcr.io/mixtile-rockchip/alpine-build:latest
```

**Build the container locally**:

```bash
docker build -t alpine-build misc-tools/alpine-build
docker run -v $PWD/build:/home/builder/build \
           -v $PWD/apk:/home/builder/apk \
           -v $PWD/.abuild:/home/builder/.abuild \
           --name alpine-build -it alpine-build
```

**Signing keys**:

- the default APK keys are under `.abuild`
- replace them with your own keys if needed
- the keys are used for signing and verification

### 4.4 Detailed Packaging Steps

#### 4.4.1 Package U-Boot

**Steps**:

1. Copy the template from `apk/ubootAPKBUILD` to `APKBUILD`.
2. Replace the version and board name if needed.

```bash
sed -i "s/pkgver=0.1/pkgver=$VERSION/" APKBUILD
sed -i "s/board/core3588e-nano/g" APKBUILD
```

3. Copy build artifacts:

```bash
cp build/output/MiniLoaderAll.bin .
cp build/output/uboot.img .
```

4. Configure signing keys:

```bash
cp -r .abuild/ /home/builder/
sudo cp .abuild/*.pub /etc/apk/keys/
```

5. Run packaging:

```bash
abuild checksum
abuild -r
```

**Full command sequence**:

```bash
cp apk/ubootAPKBUILD APKBUILD
cp build/output/MiniLoaderAll.bin .
cp build/output/uboot.img .
sudo cp .abuild/*.pub /etc/apk/keys/
abuild checksum
abuild -r
```

**Output**: `core3588e-nano-uboot-{VERSION}-r0.apk`

#### 4.4.2 Package the Kernel

```bash
cp apk/kernelAPKBUILD APKBUILD
cp build/output/boot.img .
sudo cp .abuild/*.pub /etc/apk/keys/
cp -r .abuild/ /home/builder/
abuild checksum
abuild -r
```

**Output**: `core3588e-nano-kernel-{VERSION}-r0.apk`

#### 4.4.3 Package RootFS

```bash
cp apk/rootfsAPKBUILD APKBUILD
cp build/output/alpine-rootfs.tar.gz .
sudo cp .abuild/*.pub /etc/apk/keys/
cp -r .abuild/ /home/builder/
abuild checksum
abuild -r
```

**Output**: `core3588e-nano-alpine-rootfs-{VERSION}-r0.apk`

#### 4.4.4 Package FactoryFS (Optional)

```bash
cp apk/factoryAPKBUILD APKBUILD
cp build/output/factory.img .
sudo cp .abuild/*.pub /etc/apk/keys/
cp -r .abuild/ /home/builder/
abuild checksum
abuild -r
```

**Output**: `factory-rootfs-{VERSION}-r0.apk`

### 4.5 Verify Packaging Results

Packaged APK files are typically stored in `packages/home/x86_64/`:

```bash
ls packages/home/x86_64/
```

**Example**:

```text
APKINDEX.tar.gz
alpine-rootfs-0.1-r0.apk
core3588e-kernel-0.1-r0.apk
core3588e-uboot-0.1-r0.apk
factory-rootfs-0.1-r0.apk
```

**Naming rule**:

- format: `{board}-{component}-{version}-r{release}.apk`
- example: `core3588e-nano-uboot-1.0.0-r0.apk`

### 4.6 Upload APKs to the Repository

#### 4.6.1 Install AWS CLI

```bash
sudo apk add aws-cli
```

#### 4.6.2 Configure Credentials

```bash
export AWS_ACCESS_KEY_ID=xxxxxx
export AWS_SECRET_ACCESS_KEY=xxxxx
```

#### 4.6.3 Upload Packages

**Upload U-Boot**:

```bash
aws s3api put-object \
    --bucket naos-update-bucket \
    --key "alpine-repo/x86_64/core3588e-nano-uboot-$VERSION-r0.apk" \
    --body core3588e-nano-uboot-$VERSION-r0.apk
```

**Upload kernel**:

```bash
aws s3api put-object \
    --bucket naos-update-bucket \
    --key "alpine-repo/x86_64/core3588e-nano-kernel-$VERSION-r0.apk" \
    --body core3588e-nano-kernel-$VERSION-r0.apk
```

**Upload rootfs**:

```bash
aws s3api put-object \
    --bucket naos-update-bucket \
    --key "alpine-repo/x86_64/core3588e-nano-alpine-rootfs-$VERSION-r0.apk" \
    --body core3588e-nano-alpine-rootfs-$VERSION-r0.apk
```

#### 4.6.4 Update the Repository Index

**Option 1: manually update on the repository server**

```bash
docker exec -w /data/alpine/x86_64 alpine-repo sh -c "apk index -o APKINDEX.tar.gz *.apk"
```

**Option 2: trigger webhook automatically**

```bash
curl -H "X-Webhook-Token:$AWS_ACCESS_KEY_ID" \
    http://3.85.89.239:8080/webhook/update/index
```

**Notes**:

- the webhook scripts are in `misc-tools/alpine-repo`
- after upload, the repository index can be refreshed automatically

### 4.7 Automated Packaging in CI/CD

In CI/CD, APK packaging is already structured into stages:

1. `build`: build U-Boot, kernel, and rootfs and cache artifacts
2. `apkbuild`: build U-Boot, kernel, and rootfs APKs in parallel
3. `upload`: upload APKs to S3 and trigger the repository index update

**CI/CD platform notes**:

- the repo includes GitLab CI config under `.gitlab-ci.yml` and `.gitlab-ci/`
- because the original configuration targets an older GitLab CI version, you may need to adapt it
- you can also port the logic to GitHub Actions, Jenkins, or another CI platform

**Config file locations**:

- main config: `.gitlab-ci.yml`
- board-specific configs under `.gitlab-ci/`
  - `core3588e-nano.yml`
  - `core3588e-v2-nano.yml`
  - `core3588e-tx.yml`

---

## 5. System Upgrade

### 5.1 Local Upgrade

**Option 1: web upload**

1. Upload the package to `/tmp/update.img` on the device.
2. Run:

```bash
upgrade-system -p /tmp/update.img -r
upgrade-system -p /tmp/update.img
```

**Option 2: USB upgrade**

**Steps**:

1. Make sure you have already replaced your own keys.
2. Put the upgrade firmware under `tools/upgrade_key` and run `./make_update.sh firmware_name`.
3. Copy the generated `update` directory to a USB drive and insert it into the device.

### 5.2 OTA Upgrade

For server-side deployment, see the HawkBit section in [Cloud Environment Setup](./cloud-environment-setup.md).

Configure the client side through `packages/alpine/etc/update-config.conf`.

---

## 6. Debugging

For image generation usage, see [Image Generator Guide](./image-generator-guide.md).

### 6.1 UART Debugging

By default, serial login is disabled. To re-enable it, edit `scripts/build_alpinefs.sh` and remove:

```bash
sed -i '/^tty/d'  "$ROOTFS_DIR/etc/inittab"
sed -i '/^console/d'  "$ROOTFS_DIR/etc/inittab"
```

After removal, serial login is allowed again.
