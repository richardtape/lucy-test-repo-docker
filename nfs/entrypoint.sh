#!/usr/bin/env bash
set -e

# Ganesha needs rpcbind
echo "Starting rpcbind..."
rpcbind || echo "Failed to start rpcbind"

# Prepare runtime directories if needed
mkdir -p /run/rpcbind /var/run/rpcbind

# Sync loop in background
# ============================================================================
# SYNC STRATEGY
# ============================================================================
# We use a dual approach for reliable file synchronization:
#
# 1. EVENT-DRIVEN: inotifywait detects file changes and triggers immediate sync
# 2. POLLING FALLBACK: Short timeout ensures changes are caught even if events
#    are missed (common with Docker bind mounts on macOS)
#
# Key improvements:
# - Use --checksum with rsync to detect content-only changes (not just mtime)
# - Watch for close_write event (file fully saved) in addition to modify
# - Short 0.5s timeout for responsive polling fallback
# - Continuous monitoring mode (-m) to avoid event gaps
# ============================================================================
echo "Starting sync loop..."
(
    # Ensure destination directory exists
    mkdir -p /exports/shared

    # Initial sync on startup
    if [ -d "/staging/shared" ]; then
        rsync -a --checksum --delete /staging/shared/ /exports/shared/
        echo "Initial sync complete"
    fi

    # Function to perform sync
    do_sync() {
        if [ -d "/staging/shared" ]; then
            # --checksum: Compare file contents, not just size/mtime
            # --delete: Remove files in destination that are gone in source
            # -a: Archive mode (preserves permissions, times, etc.)
            rsync -a --checksum --delete /staging/shared/ /exports/shared/
        fi
    }

    # Use continuous monitoring mode with timeout fallback
    # This approach handles both:
    # - Fast event-driven updates when inotify works
    # - Polling fallback when events are missed (macOS/Docker)
    while true; do
        # Wait for file system events with short timeout
        # -r: recursive
        # -e: events to watch
        #   - close_write: file was closed after writing (most reliable for saves)
        #   - create: new file created
        #   - delete: file deleted
        #   - moved_to: file moved/renamed into directory
        #   - modify: file modified (catches in-place edits)
        # -t 0.5: timeout 0.5 seconds (polling fallback for macOS)
        # -q: quiet mode (less output)
        #
        # We use a short timeout because Docker bind mounts on macOS
        # don't reliably propagate inotify events.
        if inotifywait -r -q -e close_write,create,delete,moved_to,modify -t 1 /staging/shared 2>/dev/null; then
            # Event detected - sync immediately
            do_sync
        else
            # Timeout or error - still sync (polling fallback)
            do_sync
        fi

        # Small delay to prevent CPU spinning if inotifywait fails repeatedly
        sleep 0.1
    done
) &

echo "Starting NFS-Ganesha..."
# -F: Foreground
# -L STDOUT: Log to stdout
# -f: Config file
exec /usr/bin/ganesha.nfsd -F -L STDOUT -f /etc/ganesha/ganesha.conf