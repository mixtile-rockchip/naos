#!/bin/bash
set -e
source encrypted_key
MISC=blank-misc.img 
dd if="$MISC" of=output/misc.img bs=1k count=10
echo -en "\x40\x00" >> output/misc.img 
echo -n "$key" >> output/misc.img 
skip=$[10 * 1024 + 64 + 2]
dd if="$MISC" of=output/misc.img seek=$skip skip=$skip bs=1
