#! /bin/bash

set -xeo pipefail

LINUX_SECURITYDM_TOOLS="${TOP_DIR}/tools/linux_securitydm"
LINUX_SECURITYDM_DIR="${TOP_DIR}/build/linux_securitydm"
INIT_CONFIG="${TOP_DIR}/packages/ramdisk/init_dm_sample"
LINUX_PACK_FIRMWARE_TOOLS="${TOP_DIR}/tools/linux_pack_firmware"
LINUX_PACK_FIRMWARE_DIR="${TOP_DIR}/build/linux_pack_firmware"

cp -aT ${LINUX_PACK_FIRMWARE_TOOLS} ${LINUX_PACK_FIRMWARE_DIR}
cp -aT ${LINUX_SECURITYDM_TOOLS} ${LINUX_SECURITYDM_DIR}
cp ${INIT_CONFIG} ${LINUX_SECURITYDM_DIR}


pushd ${LINUX_SECURITYDM_DIR}
sudo ./mkdm.sh -m ramdisk
./writeKey.sh
mv ${LINUX_SECURITYDM_DIR}/output/{ramdisk.img,misc.img} ${OUTPUT_DIR}


popd
