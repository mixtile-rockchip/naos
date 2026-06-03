#!/bin/sh

MSG_OUTPUT=/var/log/link-path.log

DEBUG() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" > $MSG_OUTPUT
}

BLOCK_TYPE_SUPPORTED="mmcblk flash"

check_device_is_supported() {
    for i in $BLOCK_TYPE_SUPPORTED; do
        if echo $(basename $1) | grep -q "$i"; then
            echo $1
            return 0
        fi
    done
}

find_raw_partition() {
    local target=$1
    local target_dev=
    local partname=

    while true; do
        for dev in /sys/class/block/*; do
            target_dev=$(check_device_is_supported $dev)
            if [ ! -z "$target_dev" ]; then
                partname=$(grep PARTNAME $target_dev/uevent | sed "s#.*PARTNAME=##")
                if [ "$partname" = "$target" ]; then
                    echo "$(basename $target_dev)"
                    return 0
                fi
            fi
        done
    done
}

link_block() {                                                                                                                                                                                                                                       
    local block=$1                                                                                                                                                                                                                                   
    DEBUG "try to find $block"                                                                                                                                                                                                      
    BLOCK=$(find_raw_partition "$block")                                                                                                                                                                                                             
    ln -s /dev/$BLOCK /dev/block/by-name/$block                                                                                                                                                                                                      
}                                                                                                                                                                                                                                                    
                                                                                                                                                                                                                                                     
rm /dev/block/by-name/uboot_a                           
rm /dev/block/by-name/uboot_b                                         
rm /dev/block/by-name/boot_a                                                        
rm /dev/block/by-name/boot_b                        
rm /dev/block/by-name/system_a                    
rm /dev/block/by-name/system_b
rm /dev/block/by-name/misc
                   
link_block uboot_a 
link_block uboot_b        
link_block boot_a                  
link_block boot_b  
link_block system_a                
link_block system_b          
link_block misc                       

