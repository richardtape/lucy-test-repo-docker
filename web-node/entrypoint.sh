#!/usr/bin/env bash
#exit on error, unset variable, pipeline fail
set -euo pipefail

# Wait for NFS server to be ready (port 2049 must be open)
echo "Waiting for NFS server port to be ready..."
until nc -z nfs 2049; do
    echo "NFS server not ready yet..."
    sleep 1
done
echo "NFS server port is open"

# Give NFS server a moment to fully initialize its exports
sleep 2

# Resolve NFS hostname to IP for logging
NFS_IP=$(getent hosts nfs | awk '{print $1}')
echo "Resolved NFS server IP: $NFS_IP"

# Create mount point
echo "Creating mount point at /www_data/www"
mkdir -p /www_data/www

# Mount NFS share (mirrors production /etc/fstab mount)
echo "Mounting NFS share nfs:/exports/shared -> /www_data/www"
echo "Using mount options: nfsvers=4,soft,timeo=50,retrans=2"
if timeout 30 mount -t nfs4 -o nfsvers=4,soft,timeo=50,retrans=2 nfs:/exports/shared /www_data/www; then
    echo "NFS mount successful"
else
    echo "ERROR: NFS mount failed or timed out!"
    echo "Attempting to show mount diagnostics..."
    showmount -e nfs 2>&1 || echo "showmount failed"
    rpcinfo -p nfs 2>&1 || echo "rpcinfo failed"
    exit 1
fi

# Verify mount is working
if mountpoint -q /www_data/www; then
    echo "Verified: /www_data/www is a valid mount point"
else
    echo "ERROR: /www_data/www is not a valid mount point"
    exit 1
fi

echo "Starting PHP-FPM daemon in background"
php-fpm -D

#runs apache in forground as main container process (PID1)
echo "Starting Apache"
exec /usr/sbin/httpd -D FOREGROUND