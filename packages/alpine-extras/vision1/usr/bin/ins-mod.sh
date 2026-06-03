#!/bin/sh

MODULE_DIR="/lib/mods"
LOG_FILE="/var/log/module-load.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

log "========== Start loading all kernel modules in $MODULE_DIR =========="

for MODULE_PATH in "$MODULE_DIR"/*.ko; do
    if [ ! -f "$MODULE_PATH" ]; then
        log "Skip: $MODULE_PATH does not exist"
        continue
    fi

    MODULE_NAME=$(basename "$MODULE_PATH" .ko)
    log "Loading module: $MODULE_NAME ($MODULE_PATH)"

    if lsmod | grep -q "^${MODULE_NAME} "; then
        log "WARNING: $MODULE_NAME already loaded, skipping"
        continue
    fi

    log "Executing: insmod $MODULE_PATH"
    if insmod "$MODULE_PATH" 2>&1 | tee -a "$LOG_FILE"; then
        log "SUCCESS: $MODULE_NAME loaded successfully"
        if lsmod | grep -q "^${MODULE_NAME} "; then
            log "VERIFIED: $MODULE_NAME is listed in lsmod"
        else
            log "WARNING: $MODULE_NAME not found in lsmod after loading"
        fi
    else
        log "ERROR: Failed to load $MODULE_NAME"
    fi

    log "--------------------------------------"
done

log "========== Module load process completed =========="
