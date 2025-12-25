#!/usr/bin/env bash
set -e

# Ganesha needs rpcbind
echo "Starting rpcbind..."
rpcbind || echo "Failed to start rpcbind"

# Prepare runtime directories if needed
mkdir -p /run/rpcbind /var/run/rpcbind

# Sync loop in background
echo "Starting sync loop..."
(
    while true; do
        # Sync from staging (host bind mount) to export volume
        # --delete: remove files in destination that are gone in source
        # -a: archive mode (preserves permissions, times, etc - important since we chown'd /exports/shared in Dockerfile)
        # We start syncing specifically the 'shared' folder.
        # Ensure destination directory exists
        mkdir -p /exports/shared
        
        # We sync the CONTENTS of /staging/shared/ into /exports/shared/
        if [ -d "/staging/shared" ]; then
             rsync -a --delete /staging/shared/ /exports/shared/
        fi
        
        # Wait for changes in /staging/shared OR timeout after 1 second
        # -r: recursive
        # -e: events to watch
        # -t 1: timeout 1 second (safety net)
        # || true: prevent script exit on timeout (inotifywait returns 1 on timeout)
        inotifywait -r -e modify,create,delete,move -t 1 /staging/shared || true
    done
) &

echo "Starting NFS-Ganesha..."
# -F: Foreground
# -L STDOUT: Log to stdout
# -f: Config file
exec /usr/bin/ganesha.nfsd -F -L STDOUT -f /etc/ganesha/ganesha.conf