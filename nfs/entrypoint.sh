#!/usr/bin/env bash

#exit on error, unset variable, pipeline fail
set -euo pipefail

# Handle shutdown signals gracefully

cleanup() {

    echo "Shutting down NFS server..."

    exportfs -ua

    kill $(cat /run/nfs/rpc.statd.pid 2>/dev/null) 2>/dev/null || true

    killall rpc.mountd 2>/dev/null || true

    killall rpc.nfsd 2>/dev/null || true

    rpcbind -w -k 2>/dev/null || true

    exit 0

}

trap cleanup SIGTERM SIGINT

#allow mount to web-node from NFS
# fsid=0 makes this the NFSv4 pseudo-root (required for NFSv4 clients)
cat <<EOF > /etc/exports
/exports/shared *(rw,sync,no_subtree_check,root_squash,fsid=0,anonuid=1001,anongid=1001)
EOF

# Required runtime directories (not created automatically in containers)
mkdir -p /run/nfs
mkdir -p /var/lib/nfs/rpc_pipefs

echo "starting rpcbind"
rpcbind -w

echo "Exporting file system"
exportfs -rv

echo "Starting mount daemon in background"
rpc.mountd 

echo "Starting nfs daemon"
rpc.nfsd -V 4 8

echo "NFS server is running"

# Keep the container alive and provide a way to check if NFS is healthy
# This replaces the debugging 'sleep 86400' with a proper idle loop
while true; do
    # Verify NFS is still exporting - if not, exit so container restarts
    if ! exportfs -s | grep -q "/exports/shared"; then
        echo "ERROR: NFS export disappeared, exiting"
        exit 1
    fi
    sleep 60
done