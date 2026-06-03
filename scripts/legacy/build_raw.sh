#! /bin/bash

set -xeo pipefail

LINUX_PACK_FIRMWARE_TOOLS="${TOP_DIR}/tools/linux_pack_firmware"
LINUX_PACK_FIRMWARE_DIR="${TOP_DIR}/build/linux_pack_firmware"
PACKAGE_FILE_CONFIG="${TOP_DIR}/packages/configs/package-file"
PARAMETER_CONFIG="${TOP_DIR}/packages/configs/parameter_ab.txt"


cp -a ${LINUX_PACK_FIRMWARE_TOOLS}  ${LINUX_PACK_FIRMWARE_DIR}

REQUIRED_FILES=(
    "idblock.bin"
    "boot.img"
    "encrypted.img"
    "ramdisk.img"
    "uboot.img"
    "encrypted_userdata.img"
    "misc.img"
)

# Directories
TARGET_DIR="${LINUX_PACK_FIRMWARE_DIR}/Image"     # Replace with your actual target path

# Flag to indicate if any file is missing
MISSING=0

echo "Checking if all required files exist in $OUTPUT_DIR..."

for file in "${REQUIRED_FILES[@]}"; do
    if [[ ! -f "${OUTPUT_DIR}/${file}" ]]; then
        echo "❌ Missing file: ${file}"
        MISSING=1
    else
        echo "✅ Found file: ${file}"
    fi
done

# Return status based on check result
if [[ $MISSING -eq 1 ]]; then
    echo "⚠️ Some files are missing. Please check!"
    exit 1
else
    echo "🎉 All required files are present."

    echo "Copying files to $TARGET_DIR..."
    mkdir -p "$TARGET_DIR"
    for file in "${REQUIRED_FILES[@]}"; do
        sudo cp "${OUTPUT_DIR}/${file}" "${TARGET_DIR}/"
        echo "📁 Copied: ${file} → ${TARGET_DIR}/"
    done

    echo "✅ All files copied successfully."
fi

pushd ${LINUX_PACK_FIRMWARE_DIR}
cp ${PACKAGE_FILE_CONFIG} ${LINUX_PACK_FIRMWARE_DIR}/
cp ${PARAMETER_CONFIG} ${LINUX_PACK_FIRMWARE_DIR}/Image/parameter.txt
bash mkrawimg.sh

mv ${LINUX_PACK_FIRMWARE_DIR}/raw.img ${OUTPUT_DIR}

popd
