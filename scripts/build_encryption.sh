#! /bin/bash

set -xeo pipefail

LINUX_SECURITYDM_TOOLS="${TOP_DIR}/tools/linux_securitydm"
LINUX_SECURITYDM_DIR="${TOP_DIR}/build/linux_securitydm"
LINUX_PACK_FIRMWARE_TOOLS="${TOP_DIR}/tools/linux_pack_firmware"
LINUX_PACK_FIRMWARE_DIR="${TOP_DIR}/build/linux_pack_firmware"

cp -aT ${LINUX_PACK_FIRMWARE_TOOLS} ${LINUX_PACK_FIRMWARE_DIR}
cp -aT ${LINUX_SECURITYDM_TOOLS} ${LINUX_SECURITYDM_DIR}


pushd ${LINUX_SECURITYDM_DIR}
sudo ./mkdm.sh -m fde-s -c config_userdata
sudo ./mkdm.sh -m fde-s -c config_rootfs


#cp ${LINUX_SECURITYDM_DIR}/output/{encrypted.img,encrypted_userdata.img,encrypted_factory.img} ${OUTPUT_DIR}
mv ${LINUX_SECURITYDM_DIR}/output/{encrypted.img,encrypted_userdata.img} ${OUTPUT_DIR}

popd
