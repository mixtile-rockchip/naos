#! /bin/bash

set -euo pipefail

source $TOP_DIR/scripts/apply_patch.sh

RKBIN_DIR="$TOP_DIR/build/rkbin"
UBOOT_DIR="$TOP_DIR/build/uboot"
UBOOT_CONFIG_DIR="$TOP_DIR/board/$BOARD/uboot"
RKBIN_COMMIT_ID="a2a0b89b6c8c612dca5ed9ed8a68db8a07f68bc0"
UBOOT_COMMIT_ID="e4f8862aeeb2eebb6ceda3d6819d58303966dd73"
KEY_DIR="$TOP_DIR/packages/keys"
PACKAGE=$1
shift

if [ ! -d "$RKBIN_DIR" ]; then
    git clone --depth=1 https://github.com/mixtile-rockchip/rkbin.git -b master $RKBIN_DIR
    pushd $RKBIN_DIR
    git fetch --depth 1 origin $RKBIN_COMMIT_ID
    git checkout $RKBIN_COMMIT_ID
    popd
fi

if [ ! -d "$UBOOT_DIR" ]; then
    git clone --depth=1 https://github.com/mixtile-rockchip/u-boot.git -b next-dev $UBOOT_DIR
    pushd $UBOOT_DIR
    git fetch --depth 1 origin $UBOOT_COMMIT_ID
    git checkout $UBOOT_COMMIT_ID
    popd
fi

pushd $UBOOT_DIR


if [ -d $UBOOT_CONFIG_DIR ]; then
	cp $UBOOT_CONFIG_DIR/${BOARD}.dts $UBOOT_DIR/arch/arm/dts/
	cp $UBOOT_CONFIG_DIR/${BOARD}_defconfig $UBOOT_DIR/configs/
	sed -i '/^[[:space:]]*CROSS_COMPILE_ARM64=\$(cd /s/.*/CROSS_COMPILE_ARM64="aarch64-linux-gnu-"/' $UBOOT_DIR/make.sh
fi
# add key
cp -r ${KEY_DIR} ${UBOOT_DIR}

time bash make.sh ${BOARD} "$@"

loader_file=$(ls *loader*.bin 2>/dev/null | head -n1)
if [ -z "${loader_file}" ]; then
    echo "error: no find  *loader* file" >&2
    exit 1
fi

cp "../uboot/${loader_file}" "${OUTPUT_DIR}/MiniLoaderAll.bin" && \
echo "created: ${OUTPUT_DIR}/MiniLoaderAll.bin -> ../uboot/${loader_file}"

cp ../uboot/uboot.img ${OUTPUT_DIR}/uboot.img
echo "created: ${OUTPUT_DIR}/uboot.img -> ../uboot/uboot.img"
if [[ "$PACKAGE" == true && $# -gt 1 ]]; then
  echo "Package loader"
 # cp ${OUTPUT_DIR}/{MiniLoaderAll.bin,uboot.img} /cache
  #upload
fi
popd
