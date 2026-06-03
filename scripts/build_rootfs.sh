#!/bin/bash

set -xeo pipefail

source $TOP_DIR/scripts/tools.sh

# File system
ROOTFS_IMG="rootfs.img"
BLOCK_SIZE=512
PAD_SIZE=$((50 * 1024 * 2 * BLOCK_SIZE))
BOOT_PAD_SIZE=$((50 * 1024 * 2 * BLOCK_SIZE))
ROOTFS_PAD_SIZE=$((10 * 1024 * 2 * BLOCK_SIZE))

# Create rootfs image
SOURCE_SIZE=$(sudo du -sb alpine | cut -f1)
OVERHEAD_SIZE=$((SOURCE_SIZE / 20))  # 5% overhead for filesystem metadata
ROOTFS_IMG_SIZE=$((SOURCE_SIZE + OVERHEAD_SIZE + ROOTFS_PAD_SIZE))
echo "Source size: $((SOURCE_SIZE / 1024 / 1024))MB"
echo "Image size: $((ROOTFS_IMG_SIZE / 1024 / 1024))MB"
fallocate -l $ROOTFS_IMG_SIZE $ROOTFS_IMG
sudo mke2fs -t ext4 -d "$TOP_DIR/build/alpine" -F "$ROOTFS_IMG" "$((ROOTFS_IMG_SIZE / 1024))K"
ln -sf ../${ROOTFS_IMG} ${OUTPUT_DIR}/rootfs.img

# show image size
ls -lh ${ROOTFS_IMG}

