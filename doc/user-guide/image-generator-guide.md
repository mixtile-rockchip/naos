# Image Generator Guide

## Source Code

```bash
git clone https://github.com/mixtile-rockchip/genimage-tools.git
```

## Repository Server Configuration

Before running the script, edit `genimage.sh` and replace `server_ip` in the `URL` variable with your own APK repository server address.

Example:

```bash
URL="http://server_ip/alpine/"
```

Replace it with something like:

```bash
URL="http://your_server_ip/alpine/"
```

## Encryption Key Configuration

Before generating images, replace the default key in `tools/encrypted_key` with the encryption key you already generated in the NAOS build guide.

Keep the image generator and the built system using the same encryption key.

Example:

```text
key=YOUR_EXISTING_HEX_KEY
```

## Environment Preparation

1. Ubuntu Linux x86_64 dependencies:

```plain
sudo apt install genext2fs qemu-user-static binfmt-support squashfs-tools f2fs-tools
```

2. Ubuntu Linux x86_64 minimal dependency set:

```plain
sudo apt install genext2fs squashfs-tools f2fs-tools
```

## Customization

### Generic Example

1. Put APK packages to be installed into the `packages` directory.

Attachment:

[drm-firefox-0.1-r0.apk](../resources/attachments/drm-firefox-0.1-r0.apk)

2. Add commands directly in the `commands` file if you need to customize the image, such as editing files or enabling startup tasks.

If you are using the test APK, add the following commands:

```plain
chmod a+x /etc/init.d/start-firefox /usr/bin/start-firefox
rc-update add seatd
rc-update add udev
rc-update add start-firefox
```

## Generate Images

Run `sudo ./genimage.sh --help` to view usage and supported image types.

```plain
adam@adam-lvm:~/work/genimage$ sudo ./genimage.sh --help
Usage: ./genimage.sh [OPTIONS] [UPDATE_TYPE]

Options:
  -v, --version VERSION    Set version (default: 0.0.1)
  -b, --board BOARD        Set board type (default: core3588e)
  -u, --update UPDATE      Set update type (default: image)
  -h, --help               Show this help message

For example: ./genimage.sh -b core3588e -u image -v 0.0.1
For example: ./genimage.sh --board core3588e --update image --version 0.0.1
Supported update types: image update
```

For example, to generate a `core3588e` image with version `0.0.1`:

```plain
sudo ./genimage.sh -b core3588e -u image -v 0.0.1
```

This generates `update.img` in the current directory. It can also be used for upgrading, but that is not recommended because the `misc` partition in the full image contains the filesystem decryption key.

To generate a standard OTA update package instead:

```plain
sudo ./genimage.sh -b core3588e -u update -v 0.0.1
```

## Public Device Trees

```plain
core3588e-nano             # core3588e v1.1.0 core board + Jetson Orin Nano baseboard
core3588e-tx               # core3588e v1.1.0 core board + Jetson TX baseboard
core3588e-v2-nano          # core3588e v2.0.0 core board + Jetson Orin Nano baseboard
```
