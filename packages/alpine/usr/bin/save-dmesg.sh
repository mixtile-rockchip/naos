#!/bin/sh

LOGFILE="/var/log/dmesg_cp.log"
mkdir -p "$(dirname "$LOGFILE")"
exec >"$LOGFILE" 2>&1

SRC="/sys/fs/pstore/console-ramoops-0"
DST="/var/log/dmesg.log"

echo "$(date) : Start copy ramoops log."

if [ -f "$SRC" ]; then
    echo "$(date) : $SRC exists, copying..."
    cat "$SRC" >> "$DST"
    if [ $? -eq 0 ]; then
        echo "$(date) : Copy success: $SRC to $DST"
    else
        echo "$(date) : Copy failed: $SRC -> $DST"
    fi
else
    echo "$(date) : Source file does not exist: $SRC"
fi

echo "$(date) : Done."
