#! /bin/bash

set -xeo pipefail

LINUX_PACK_FIRMWARE_DIR="${TOP_DIR}/build/linux_pack_firmware"
pushd ${LINUX_PACK_FIRMWARE_DIR}
./programmer_image_tool -i update.img -t emmc
mv out_image.bin raw.img
mv ${LINUX_PACK_FIRMWARE_DIR}/raw.img ${OUTPUT_DIR}

popd
