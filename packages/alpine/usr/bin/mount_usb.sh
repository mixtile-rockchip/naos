#!/bin/sh

LOG_FILE="/var/log/usb_mount.log"

log_message() {
    MESSAGE="$1"
    echo "$MESSAGE" | tee -a "$LOG_FILE"
}

DEVICE=$1
MOUNT_PARENT_DIR="/mnt/usb"

PUB_KEY="/etc/upgrade/public.pem"
AES_KEY=$(cat /etc/upgrade/aes.key)

log_message "Processing device $DEVICE"

[ -d "$MOUNT_PARENT_DIR" ] || mkdir -p "$MOUNT_PARENT_DIR"

DEVICE_UUID=$(lsblk -o UUID -n "$DEVICE")

if [ -z "$DEVICE_UUID" ]; then
    log_message "UUID not found"
    exit 1
fi

MOUNT_DIR="$MOUNT_PARENT_DIR/$DEVICE_UUID"
mkdir -p "$MOUNT_DIR"

if ! mount -o ro,nosuid,nodev,noexec "$DEVICE" "$MOUNT_DIR"; then
    log_message "Mount failed"
    exit 1
fi

UPDATE_DIR="$MOUNT_DIR/update"

# Check update directory
if [ ! -d "$UPDATE_DIR" ]; then
    log_message "update directory not found"
    umount "$MOUNT_DIR"
    exit 0
fi

# Check required files BEFORE copying
if [ ! -f "$UPDATE_DIR/firmware.enc" ] || \
   [ ! -f "$UPDATE_DIR/firmware.sig" ] || \
   [ ! -f "$UPDATE_DIR/iv.bin" ]; then
    log_message "Required files missing in update directory"
    umount "$MOUNT_DIR"
    exit 1
fi

log_message "Update package verified on USB"

# Now copy
rm -rf /root/update
cp -r "$UPDATE_DIR" /root/

umount "$MOUNT_DIR"

cd /root/update || exit 1

log_message "Verifying signature"

openssl dgst -sha256 \
    -verify "$PUB_KEY" \
    -signature firmware.sig \
    firmware.enc

if [ $? -ne 0 ]; then
    log_message "Signature verification failed"
    rm -rf /root/update
    exit 1
fi

log_message "Decrypting firmware"

IV_HEX=$(xxd -p iv.bin | tr -d '\n')

openssl enc -d -aes-256-cbc \
    -in firmware.enc \
    -out /root/update.img \
    -K $AES_KEY \
    -iv $IV_HEX \
    -nosalt

if [ $? -ne 0 ]; then
    log_message "Decryption failed"
    exit 1
fi

cd /root || exit 1
rm -rf /root/update

log_message "Starting system upgrade"

upgrade-system -p ./update.img -r

RET=$?

if [ $RET -ne 0 ]; then
    log_message "upgrade-system failed with code $RET"
    exit 1
fi

exit 0
