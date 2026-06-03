# APK Package Build Example

This document uses the `drm-firefox` package as an example to show how to build an application APK for NAOS.

---

## 1. Get the Source Code

```bash
git clone https://github.com/mixtile-rockchip/aports.git
cd aports/drm-firefox
```

---

## 2. Prepare the Build Environment

### 2.1 Requirements

- **Architecture**: `aarch64` Alpine Linux
- **Tool**: `abuild`

### 2.2 Signing Keys

**Option 1: use an existing key**

Copy your existing signing key into the build environment.

**Option 2: generate a new key**

```bash
abuild-keygen -a
```

This generates the signing key pair used for APK signing and verification.

---

## 3. Build Steps

Run the following commands inside the `drm-firefox` directory:

```bash
abuild checksum
abuild -r
```

**Output**:

```text
../packages/$USER/aarch64/drm-firefox-0.1-r0.apk
```

---

## 4. Package Metadata

### 4.1 Example `APKBUILD`

```bash
pkgname=drm-firefox
pkgver=0.1
pkgrel=0
pkgdesc="support drm firefox for naos"
url="focalcrest.com"
arch="aarch64"
license="MIT"
options="!check"

depends="weston weston-backend-drm seatd font-dejavu firefox-esr font-wqy-zenhei"

source="start-firefox start-firefox-exec"

build() {
        :
}

check() {
        :
}

package() {
    install -Dm755 "$srcdir"/start-firefox "$pkgdir"/etc/init.d/start-firefox
    install -Dm755 "$srcdir"/start-firefox-exec "$pkgdir"/usr/bin/start-firefox
}

sha512sums="
4a9d8dce1851f0026e0c4b313a2a3e4c4fe5df3ebc379be527a868ce9009bd79a01d1e819210c8b0b5eb8698417c8396e6a38af804f4890922b697e00b930746  start-firefox
0dda0accfc9dca1b240a15ad05763ef68ca817704cdb2a8fa36d13934e9547f0b15354f272f23ac056571567bcb66ad15cb6906f15aac7b822457c642f5f91e9  start-firefox-exec
"
```

### 4.2 Field Description

- `pkgname`: package name
- `pkgver`: package version
- `pkgrel`: package release number, usually starting from `0`
- `pkgdesc`: package description
- `arch`: target architecture
- `depends`: dependencies automatically installed with the package
- `source`: files included in the package
- `sha512sums`: SHA-512 checksums for integrity verification

### 4.3 Dependencies

The `drm-firefox` package depends on:

- `weston`
- `weston-backend-drm`
- `seatd`
- `font-dejavu`
- `firefox-esr`
- `font-wqy-zenhei`

Adjust the `depends` field according to your application requirements.

---

## 5. Usage

Put the generated APK into the image generator's `packages/` directory. The image generator installs it automatically.

---

## 6. Auto-Start Configuration

### 6.1 Service Scripts

The package includes two scripts:

- `start-firefox`: installed to `/etc/init.d/start-firefox` as the OpenRC service script
- `start-firefox-exec`: installed to `/usr/bin/start-firefox` as the actual launch script

### 6.2 Enable Auto-Start

Run the following commands during image customization:

```bash
rc-update add start-firefox default
rc-update add seatd default
rc-update add udev default
rc-update add udev default
```

---

## 7. Develop a Custom APK Package

### 7.1 Create an `APKBUILD`

1. Create a package directory:

```bash
mkdir myapp
cd myapp
```

2. Create an `APKBUILD` file.

Use the `drm-firefox` example as a template and adjust:

- package name, version, and description
- dependencies
- source files
- installation rules

3. Prepare the source files in the package directory.

4. Generate checksums:

```bash
abuild checksum
```

### 7.2 Common Package Patterns

**Simple executable**:

```bash
package() {
    install -Dm755 "$srcdir"/myapp "$pkgdir"/usr/bin/myapp
}
```

**Application with a service**:

```bash
package() {
    install -Dm755 "$srcdir"/myapp "$pkgdir"/usr/bin/myapp
    install -Dm755 "$srcdir"/myapp.initd "$pkgdir"/etc/init.d/myapp
}
```

**Containerized application**:

```bash
package() {
    install -Dm644 "$srcdir"/myapp.docker "$pkgdir"/etc/myapp.tar
    install -Dm755 "$srcdir"/start-myapp.sh "$pkgdir"/usr/bin/start-myapp.sh
}
```

### 7.3 Notes

1. Use `install -Dm755` for executables and `install -Dm644` for regular files.
2. Follow the Linux filesystem hierarchy.
3. Declare all runtime dependencies in `depends`.
4. Create an OpenRC service script if the application must start automatically.

---

## 8. Debug and Test

### 8.1 Local Testing

```bash
sudo apk add --allow-untrusted drm-firefox-0.1-r0.apk
sudo rc-service start-firefox start
sudo rc-service start-firefox status
sudo rc-service start-firefox stop
```

### 8.2 Verify Installation

```bash
ls -l /etc/init.d/start-firefox
ls -l /usr/bin/start-firefox
rc-update show
```

---

## 9. References

### 9.1 Alpine Documentation

- **APKBUILD reference**:
  [https://wiki.alpinelinux.org/wiki/APKBUILD_Reference](https://wiki.alpinelinux.org/wiki/APKBUILD_Reference)
- **Create an Alpine package**:
  [https://wiki.alpinelinux.org/wiki/Creating_an_Alpine_package](https://wiki.alpinelinux.org/wiki/Creating_an_Alpine_package)

### 9.2 Alpine Boot and Init

For more details on OpenRC and Alpine boot flow:

- **OpenRC**:
  [https://wiki.alpinelinux.org/wiki/OpenRC](https://wiki.alpinelinux.org/wiki/OpenRC)
- **Alpine init system**:
  [https://wiki.alpinelinux.org/wiki/Alpine_Linux_init_system](https://wiki.alpinelinux.org/wiki/Alpine_Linux_init_system)

---

## 10. Summary

```text
1. Get the source -> 2. Prepare the environment -> 3. Create or modify APKBUILD -> 4. Build the APK -> 5. Test it -> 6. Upload it or install locally
```

Key points:

- build in an `aarch64` Alpine environment
- configure dependencies and source files correctly
- add OpenRC service scripts if auto-start is required
- follow Alpine packaging conventions
