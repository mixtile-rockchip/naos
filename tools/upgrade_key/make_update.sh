#!/bin/bash
# Usage: ./make_update.sh firmware.bin

set -e

FIRMWARE=$1
OUTDIR=update

if [ -z "$FIRMWARE" ]; then
    echo "Usage: $0 firmware.bin"
    exit 1
fi

mkdir -p "$OUTDIR"

AES_KEY=$(cat aes.key)

echo "[1] Generating 16-byte IV"
openssl rand -out "$OUTDIR/iv.bin" 16

IV_HEX=$(xxd -p "$OUTDIR/iv.bin" | tr -d '\n')

echo "[2] Encrypting with AES-256-CBC"

openssl enc -aes-256-cbc \
    -in "$FIRMWARE" \
    -out "$OUTDIR/firmware.enc" \
    -K "$AES_KEY" \
    -iv "$IV_HEX" \
    -nosalt

echo "[3] Generating RSA signature"

openssl dgst -sha256 \
    -sign private.pem \
    -out "$OUTDIR/firmware.sig" \
    "$OUTDIR/firmware.enc"

echo "✅ Update package successfully created"
echo "👉 Copy the 'update' folder to your upgrade USB drive."
