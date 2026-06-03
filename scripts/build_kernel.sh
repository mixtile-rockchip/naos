#! /bin/bash

set -euo pipefail

KERNEL_DIR="$TOP_DIR/build/kernel"
#MODULE_DIR="$TOP_DIR/build/_module"
KERNEL_CONFIG_DIR="$TOP_DIR/board/$BOARD/kernel"
KERNEL_RESOURCE_DIR="$TOP_DIR/resource"

# Default Kernel Version
KERNEL_VERSION=${KERNEL_VERSION:-6.1}

# Use associative arrays to store versions, repositories and branches
declare -A REPOS=(
    [6.1]="https://github.com/mixtile-rockchip/mixtile-sdk-rk-kernel.git"
)
declare -A BRANCHES=(
    [6.1]="rk3588-linux-6.1-rkr6"
)

# Check if KERNEL_VERSION is supported
if [[ -z "${REPOS[$KERNEL_VERSION]}" || -z "${BRANCHES[$KERNEL_VERSION]}" ]]; then
    echo "Error: Unsupported KERNEL_VERSION: $KERNEL_VERSION"
    exit 1
fi

# Get corresponding repository and branch
REPO=${REPOS[$KERNEL_VERSION]}
BRANCH=${BRANCHES[$KERNEL_VERSION]}

#mkdir -p $MODULE_DIR

if [ ! -d "$KERNEL_DIR" ]; then
    git clone --depth=1 $REPO -b $BRANCH $KERNEL_DIR
fi

pushd $KERNEL_DIR

if [ -d $KERNEL_CONFIG_DIR/$KERNEL_VERSION ]; then
    cp $KERNEL_CONFIG_DIR/$KERNEL_VERSION/${BOARD}.dts $KERNEL_DIR/arch/arm64/boot/dts/rockchip/
    cp $KERNEL_CONFIG_DIR/$KERNEL_VERSION/${BOARD}_defconfig $KERNEL_DIR/arch/arm64/configs/
fi

cp $KERNEL_RESOURCE_DIR/picture/logo* .

export ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu-
time make ${BOARD}_defconfig
#mkdir -p build/drivers/gpu/arm/valhall/
#cp drivers/gpu/arm/valhall/mali_csffw.bin build/drivers/gpu/arm/valhall/
time make -j$(nproc) Image
time make rockchip/${BOARD}.dtb
time make -j$(nproc) ${BOARD}.img
#time make headers_install INSTALL_HDR_PATH=$KERNEL_DIR/header
#time make -j$(nproc) modules
#time make -j$(nproc) modules_install INSTALL_MOD_PATH=$MODULE_DIR

cp $KERNEL_DIR/arch/arm64/boot/Image $OUTPUT_DIR
cp $KERNEL_DIR/arch/arm64/boot/dts/rockchip/${BOARD}.dtb $OUTPUT_DIR
cp $KERNEL_DIR/resource.img ${OUTPUT_DIR}

pushd
