#! /bin/bash

set -euo pipefail

ROOTFS_PAK="factory.tar.gz"
ROOTFS_DIR="$TOP_DIR/build/factory"
PACKAGES_DIR="$TOP_DIR/packages/factory"


if [ ! -f "$ROOTFS_PAK" ]; then
    wget -O $ROOTFS_PAK https://dl-cdn.alpinelinux.org/alpine/v3.22/releases/aarch64/alpine-minirootfs-3.22.0-aarch64.tar.gz
    mkdir -p $ROOTFS_DIR
    tar -xvf $ROOTFS_PAK -C $ROOTFS_DIR
fi

sudo cp $PACKAGES_DIR/* $ROOTFS_DIR -a

sudo chroot $ROOTFS_DIR /bin/sh -c "apk update && \
                        apk add --no-cache alpine-base dhcpcd chrony acpid-openrc mesa-gles mesa-egl mesa-dri-gallium libdrm \
                        eudev usbutils util-linux iptables ip6tables dbus font-wqy-zenhei udev mtdev ttf-freefont fontconfig && \
                        rc-update add sysctl boot && \
                        rc-update add hostname boot && \
                        rc-update add chronyd boot && \
                        rc-update add acpid default && \
                        rc-update add dhcpcd default && \
			rc-update add udev sysinit  && \
			rc-update add udev boot   && \
                        rc-update add dbus default && \
                        rc-update add syslog boot"



# need open when officially released
sed -i '/^tty/d'  "$ROOTFS_DIR/etc/inittab"
sed -i '/^console/d'  "$ROOTFS_DIR/etc/inittab"
# needs to be closed when officially released
#sudo sed -i 's|^console::respawn:.*|console::respawn:/sbin/getty -n -l /bin/login 1500000 /dev/ttyFIQ0 vt100|' "$ROOTFS_DIR/etc/inittab"
echo ttyFIQ0 | sudo tee -a $ROOTFS_DIR/etc/securetty

cat << EOF | sudo chroot $ROOTFS_DIR /bin/sh
# set root passwd
echo "root:root" | chpasswd

chmod a+x /etc/init.d/start-qt /opt/main
rc-update add start-qt default

# factory flag
touch /etc/factory

# hostname
echo factory > /etc/hostname
sed -i 's/^\(127\.0\.0\.1\|\:\:1\)[[:space:]]\+localhost[[:space:]]\+.*$/\1\tlocalhost /' /etc/hosts
EOF

source $TOP_DIR/scripts/tools.sh

# File system
ROOTFS_IMG="factory.img"
BLOCK_SIZE=512
PAD_SIZE=$((50 * 1024 * 2 * BLOCK_SIZE))
BOOT_PAD_SIZE=$((50 * 1024 * 2 * BLOCK_SIZE))
ROOTFS_PAD_SIZE=$((10 * 1024 * 2 * BLOCK_SIZE))

# Create rootfs image
SOURCE_SIZE=$(sudo du -sb factory | cut -f1)
OVERHEAD_SIZE=$((SOURCE_SIZE / 10))  # 10% overhead for filesystem metadata
ROOTFS_IMG_SIZE=$((SOURCE_SIZE + OVERHEAD_SIZE + ROOTFS_PAD_SIZE))
echo "Source size: $((SOURCE_SIZE / 1024 / 1024))MB"
echo "Image size: $((ROOTFS_IMG_SIZE / 1024 / 1024))MB"
rm -f $ROOTFS_IMG
fallocate -l $ROOTFS_IMG_SIZE $ROOTFS_IMG
sudo mke2fs -t ext4 -d "$TOP_DIR/build/factory" -F "$ROOTFS_IMG" "$((ROOTFS_IMG_SIZE / 1024))K"


ln -sf ../${ROOTFS_IMG} ${OUTPUT_DIR}/factory.img

# show image size
ls -lh ${ROOTFS_IMG}

