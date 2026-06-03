#!/bin/sh

max_attempts=50
retry_interval=10

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a /var/log/cpugov.log
}

log "Starting CPU Governor configuration service"
sleep 3

for attempt in $(seq 1 $max_attempts); do
    log "Attempt $attempt of $max_attempts"

    # Set CPU governor to performance mode
    echo performance | tee $(find /sys/ -name *governor) /dev/null || true

    # Verify the configuration
    log "Verification result:"
    find /sys -name *governor | xargs cat | while read line; do
        log "  $line"
    done

    # Check if execution was successful
    performance_count=$(find /sys -name *governor | xargs cat | grep -c "performance" || true)

    if [ "$performance_count" -ge 6 ]; then
        log "✓ Success: $performance_count CPU governors set to performance mode"
        exit 0
    else
        log "✗ Failed: Only $performance_count CPU governors set to performance mode (minimum 6 required)"

        if [ $attempt -lt $max_attempts ]; then
            log "Waiting $retry_interval seconds before retry..."
            sleep $retry_interval
        else
            log "Maximum retry attempts ($max_attempts) reached, configuration failed"
            exit 1
        fi
    fi
done
