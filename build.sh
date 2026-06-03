#!/bin/bash

set -euo pipefail


usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -t, --target <name>     Build target: uboot|kernel|alpine|all|rootfs|fit-boot|sign-boot|update"
    echo "  -b, --board <name>      Specify board name"
    echo "  -p, --package <name>    Specify package name"
    echo "  -h, --help              Show this help message"
    echo "  Other arguments will be passed to build commands"
    echo ""
    echo "Examples:"
    echo "  $0  --target kernel --board mixtile-core3588e --package true"
    echo "  $0  -t all  -b mixtile-core3588e -p true "
    echo "  $0  --target all --board mixtile-core3588e"
    exit 0
}


while [[ $# -gt 0 ]]; do
    case $1 in
      	-t|--target)
            TARGET="$2"
            shift 2
            ;;
        -h|--help)
	    usage
            ;;
        -b|--board)
            BOARD="$2"
            shift 2
            ;;
        -p|--package)
            PACKAGE="$2"
            shift 2
            ;;
        --*|-*)
#            EXTRA_OPTS="$EXTRA_OPTS $1"
	    usage
            shift
            ;;
        *)
#            EXTRA_OPTS="$EXTRA_OPTS $1"
	    usage
            shift
            ;;
    esac
done


export TOP_DIR=$(dirname $(realpath $0))
echo "TOP_DIR: $TOP_DIR"
BUILD_DIR="$TOP_DIR/build"
export OUTPUT_DIR=$BUILD_DIR/output
mkdir -p $BUILD_DIR $OUTPUT_DIR > /dev/null 2>&1

export BOARD=${BOARD:-mixtile-core3588e}
echo "Building for board: $BOARD"
TARGET=${TARGET:-all}
PACKAGE=${PACKAGE:-false}

function build_uboot() {
    echo "Building U-Boot for $BOARD..."
    pushd $BUILD_DIR
    bash $TOP_DIR/scripts/build_uboot.sh $PACKAGE "$@" 
    popd
}

function build_fit_boot() {
    echo "Building Fit Boot for $BOARD..."
    BOOT_ITS="$TOP_DIR/packages/configs/boot.its"
    pushd $BUILD_DIR/kernel
    cp ${BOOT_ITS} boot.its
    sed -i "s/input-devicetree/$BOARD/g" boot.its
    ../rkbin/tools/mkimage -f boot.its -E -p 0x800 boot.img
    cp boot.img ${OUTPUT_DIR}
    popd
}

function build_sign_boot() {
    echo "Building Sign Boot for $BOARD..."
    cp ${OUTPUT_DIR}/boot.img ${BUILD_DIR}/uboot
    pushd ${BUILD_DIR}/uboot
    if [[ "$BOARD" == *mixtile-vision1* ]]; then
    	build_uboot --spl-new --boot_img boot.img --burn-key-hash
    else
	build_uboot --spl-new --boot_img boot.img
    fi
    cp ${BUILD_DIR}/uboot/boot.img ${OUTPUT_DIR}/boot.img
    if [[ "$PACKAGE" == true ]]; then
	echo "Package kernel"
	#cp ${OUTPUT_DIR}/boot.img /cache
	#upload
    fi
    popd
}

function build_kernel() {
    echo "Building Kernel for $BOARD..."
    pushd $BUILD_DIR
    bash $TOP_DIR/scripts/build_kernel.sh
    popd
}

function build_alpine() {
    echo "Building Alpine Linux for $BOARD..."
    pushd $BUILD_DIR
    if [ -f "$TOP_DIR/scripts/build_alpinefs_$BOARD.sh" ]; then
        bash "$TOP_DIR/scripts/build_alpinefs_$BOARD.sh" "$PACKAGE"
    else
	echo "Not found custom config for $BOARD, build base config"
        bash "$TOP_DIR/scripts/build_alpinefs_base.sh" "$PACKAGE"
    fi

    popd
}

function build_rootfs() {
    echo "Building rootfs for $BOARD..."
    pushd $BUILD_DIR
    bash $TOP_DIR/scripts/build_rootfs.sh
    popd
}

function build_factory() {
    echo "Building Factory Linux for $BOARD..."
    pushd $BUILD_DIR
    bash $TOP_DIR/scripts/build_factory.sh $PACKAGE
    popd
}



function build_ramdisk() {
    echo "Building Ramdisk for $BOARD..."
    pushd $BUILD_DIR
    bash $TOP_DIR/scripts/build_ramdisk.sh
    popd
}

function build_encryption() {
    echo "Building encryption disk for $BOARD..."
    pushd $BUILD_DIR
    bash $TOP_DIR/scripts/build_encryption.sh
    popd
}



function build_update_image() {
    echo "Building Image for $BOARD..."
    pushd $BUILD_DIR
    bash $TOP_DIR/scripts/build_update.sh
    popd
}

function build_update_raw() {
    echo "Building Image for $BOARD..."
    pushd $BUILD_DIR
    bash $TOP_DIR/scripts/build_raw.sh
    popd
}

function build_packages() {
    echo "Building All for $BOARD..."
    PACKAGE=true
    build_uboot --spl-new
    build_kernel
    build_ramdisk
    build_fit_boot
    build_sign_boot
    build_alpine 
}

function build_all() {
    echo "Building All for $BOARD..."
    build_uboot --spl-new
    build_kernel
    build_ramdisk
    build_fit_boot
    build_sign_boot
    build_alpine
    build_rootfs 
    build_encryption
    build_update_image
}

case "$TARGET" in
    uboot)
        time build_uboot --spl-new
        ;;
    kernel)
        time build_kernel
        ;;
    ramdisk)
        time build_ramdisk
        ;;
    fit-boot)
        time build_fit_boot
        ;;
    sign-boot)
        time build_sign_boot
        ;;
    encryption)
        time build_encryption
        ;;
    alpine)
        time build_alpine
        ;;
    factory)
        time build_factory
        ;;
    rootfs)
        time build_rootfs
        ;;
    update)
        time build_update_image
        ;;
    raw)
        time build_update_raw
        ;;
    all)
        time build_all
        ;;
    packages)
        time build_packages
        ;;

esac

unset BOARD
