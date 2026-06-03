#!/bin/sh
# updateAB.sh - Replacement for updateAB OpenRC service

COMMAND="/usr/bin/updateEngine"
COMMAND_ARGS="--misc=now"
LOGFILE="/var/log/updateAB.log"
LOG_DIR="/var/log"
MISC_DEVICE="/dev/block/by-name/misc"
MAX_WAIT=10

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOGFILE"
}

# 1. Create log directory
log "Creating log directory..."
mkdir -p "$LOG_DIR"
if [ $? -ne 0 ]; then
    log "Error: Cannot create log directory $LOG_DIR"
    exit 1
fi

# 2. Wait for misc device to appear
log "Waiting for $MISC_DEVICE to appear..."
for i in $(seq 1 $MAX_WAIT); do
    if [ -e "$MISC_DEVICE" ]; then
        log "$MISC_DEVICE found (waited ${i} seconds)"
        break
    fi
    
    if [ $i -eq $MAX_WAIT ]; then
        log "Error: Timeout, $MISC_DEVICE not found"
        exit 1
    fi
    
    log "Waiting... (${i}/${MAX_WAIT})"
    sleep 1
done

# 3. Check if command exists
if [ ! -x "$COMMAND" ]; then
    log "Error: Command $COMMAND does not exist or is not executable"
    exit 1
fi

# 4. Execute command
log "Starting: $COMMAND $COMMAND_ARGS"
log "----------------------------------------"

# Execute and log output
if "$COMMAND" $COMMAND_ARGS >> "$LOGFILE" 2>&1; then
    log "Execution successful"
    log "Exit code: 0"
    exit 0
else
    EXIT_CODE=$?
    log "Execution failed"
    log "Exit code: $EXIT_CODE"
    exit $EXIT_CODE
fi
