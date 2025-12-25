#!/usr/bin/env bash

#exit on error, unset variable, pipeline fail
set -euo pipefail

# Handle shutdown signals gracefully
cleanup() {
    echo "Shutting down NFS server..."
    exportfs -ua
    killall rpc.mountd 2>/dev/null || true
    killall rpc.nfsd 2>/dev/null || true
    killall nfsdcld 2>/dev/null || true
    killall rpc.idmapd 2>/dev/null || true
    rpcbind -w -k 2>/dev/null || true
    umount /var/lib/nfs/rpc_pipefs 2>/dev/null || true
    umount /proc/fs/nfsd 2>/dev/null || true
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
mkdir -p /var/lib/nfs/nfsdcld

# Why we mount rpc_pipefs:
# rpc_pipefs is a kernel pseudo-filesystem used by the NFSv4 kernel server to communicate 
# with user-space daemons like 'rpc.idmapd' and 'nfsdcld'. 
# Standard Docker containers do not mount this by default, so we must do it manually 
# here in the privileged entrypoint. Without this, daemons fail to start.
echo "Mounting rpc_pipefs..."
mount -t rpc_pipefs sunrpc /var/lib/nfs/rpc_pipefs || echo "WARNING: Failed to mount rpc_pipefs"

# Why we mount nfsd:
# This is the interface to the kernel NFS server. 'rpc.nfsd' uses this filesystem 
# to control the in-kernel NFS server. It is strictly required for the kernel-based NFS server to work.
echo "Mounting nfsd..."
mount -t nfsd nfsd /proc/fs/nfsd || echo "WARNING: Failed to mount nfsd"

echo "starting rpcbind"
rpcbind -w

# Why nfsdcld?
# NFSv4 requires stable storage to track clients across server restarts to handle the "Grace Period" correctly.
# If this daemon is missing, the server may refuse connections or hang for 90 seconds (grace period) 
# waiting for client reclaim info that will never come.
echo "starting nfsdcld (client tracking)"
nfsdcld || { echo "nfsdcld failed"; exit 1; }

echo "starting idmapd"
rpc.idmapd || { echo "rpc.idmapd failed"; exit 1; }

echo "Exporting file system"
exportfs -rv

echo "Starting mount daemon in background"
# Pin port to 20048
# We pin ports to ensure the firewall/Docker networking rules in 'docker-compose.yml' remain valid.
# By default, these use random high ports which makes container-to-container networking difficult.
rpc.mountd -p 20048 || { echo "rpc.mountd failed"; exit 1; }

echo "Starting nfs daemon"
# Enable NFSv4, disable NFSv3/UDP to be cleaner, though user config might need v3? 
# The log showed "program 100003 version 4" so v4 is desired.
rpc.nfsd -V 4 -N 3 8 || { echo "rpc.nfsd failed"; exit 1; }

echo "NFS server is running"

# Debug: Show listening ports
echo "--- Listening ports ---"
ss -tulpn || echo "ss failed"
echo "-----------------------"

# Keep the container alive and provide a way to check if NFS is healthy
# This replaces the debugging 'sleep 86400' with a proper idle loop
while true; do
    # Verify NFS is still exporting - if not, exit so container restarts
    if ! exportfs -s | grep -q "/exports/shared"; then
        echo "ERROR: NFS export disappeared, exiting"
        exit 1
    fi
    
    # Check processes
    if ! pidof rpc.mountd > /dev/null; then
         echo "ERROR: rpc.mountd is not running!"
         exit 1
    fi
    # rpc.nfsd is kernel threads, check simply via exit code of a command attempting to touch it?
    # or check kernel threads. In container ps might usually show them as [nfsd] if privileged?
    # Actually, user space process for nfsd might not exist after it hands off to kernel.
    # But checking if rpc.mountd and rpcbind are up is critical.

    sleep 60
done