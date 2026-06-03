#!/bin/sh

# Log file location
LOG_FILE="/var/log/usb_unmount.log"

# Log function to log messages to both console and log file
log_message() {
    local MESSAGE="$1"
    echo "$MESSAGE" | tee -a "$LOG_FILE"
}

# Get the device name (e.g., /dev/sda1)
DEVICE=$1

# Find the mount point for the device
MOUNT_POINT=$(mount | grep "$DEVICE" | awk '{print $3}')

log_message "Starting to process device $DEVICE for unmount"

# If the device is mounted, proceed with unmounting
if [ -n "$MOUNT_POINT" ]; then
    log_message "Unmounting device $DEVICE from $MOUNT_POINT"
    
    # Perform unmounting
    umount "$MOUNT_POINT"
    
    if [ $? -eq 0 ]; then
        log_message "Successfully unmounted $DEVICE"

        # After unmounting, check if the mount directory is empty, and remove it if it is
        if [ -d "$MOUNT_POINT" ] && [ ! "$(ls -A "$MOUNT_POINT")" ]; then
            log_message "Mount directory is empty. Removing directory: $MOUNT_POINT"
            rmdir "$MOUNT_POINT"
            if [ $? -eq 0 ]; then
                log_message "Successfully removed mount directory: $MOUNT_POINT"
            else
                log_message "Failed to remove mount directory: $MOUNT_POINT. It may not be empty."
            fi
        else
            log_message "Mount directory is not empty. Skipping directory removal."
        fi
    else
        log_message "Failed to unmount $DEVICE"
    fi
else
    log_message "Device $DEVICE is not mounted."
fi

log_message "Process completed for $DEVICE"
