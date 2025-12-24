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
# With fsid=0 on the export, NFSv4 clients mount the pseudo-root with "/"
echo "Mounting NFS share nfs:/ -> /www_data/www"
# NFSv4 mount options:
# - nfsvers=4: Use NFSv4 (doesn't need mountd/portmapper)
# - soft,timeo=50,retrans=2: Don't hang forever on network issues
# - nolock: Skip NLM locking (avoid nlockmgr port issues in containers)
# - proto=tcp,port=2049: Explicitly use TCP on port 2049
MOUNT_OPTS="nfsvers=4,soft,timeo=50,retrans=2,nolock,proto=tcp,port=2049"
echo "Using mount options: $MOUNT_OPTS"
if timeout 30 mount -t nfs4 -o "$MOUNT_OPTS" nfs:/ /www_data/www; then
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