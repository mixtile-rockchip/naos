#!/bin/sh

logdir="/var/log"
max_size=$((20*1024*1024))  # 20MB
keep_size=$((10*1024*1024)) # 10MB

for logfile in "$logdir"/*.log; do
  [ -f "$logfile" ] || continue
  filesize=$(stat -c %s "$logfile")
  if [ "$filesize" -gt "$max_size" ]; then
    tmpfile=$(mktemp)
    tail -c "$keep_size" "$logfile" > "$tmpfile"
    cat "$tmpfile" > "$logfile"
    rm -f "$tmpfile"
    echo "Trimmed $logfile from $filesize to $keep_size bytes."
  fi
done
