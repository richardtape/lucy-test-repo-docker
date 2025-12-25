#!/usr/bin/env bash
#exit on error, unset variable, pipeline fail
set -euo pipefail

# Static NFS server IP (configured in docker-compose.yml)
NFS_IP="172.28.0.10"

# Wait for NFS server to be ready (port 2049 must be open)
echo "Waiting for NFS server at $NFS_IP:2049 to be ready..."
until nc -z "$NFS_IP" 2049; do
    echo "NFS server not ready yet..."
    sleep 1
done
echo "NFS server port is open"

# Give NFS server a moment to fully initialize its exports
sleep 2
echo "Using NFS server IP: $NFS_IP"

# Create mount point
echo "Creating mount point at /www_data/www"
mkdir -p /www_data/www

# Mount NFS share (mirrors production /etc/fstab mount)
echo "Mounting NFS share $NFS_IP:/ -> /www_data/www"

# Check if NFS kernel modules are available
echo "Checking NFS kernel support..."
cat /proc/filesystems | grep nfs || echo "WARNING: NFS not in /proc/filesystems"
lsmod | grep nfs || echo "Note: NFS modules not listed (may be built-in)"

# Try verbose mount to see what's happening
echo "Attempting mount with verbose output..."
MOUNT_OPTS="nfsvers=4,soft,timeo=50,retrans=2,nolock,proto=tcp,port=2049"
echo "Using mount options: $MOUNT_OPTS"

# Run mount with timeout using IP address
# Run mount with timeout using IP address
# We mount /shared because ganesha.conf uses Pseudo = /shared
echo "Running: mount -v -t nfs4 -o $MOUNT_OPTS $NFS_IP:/shared /www_data/www"
if timeout 30 mount -v -t nfs4 -o "$MOUNT_OPTS" "$NFS_IP":/shared /www_data/www; then
    MOUNT_SUCCESS=true
else
    MOUNT_EXIT_CODE=$?
    echo "Mount exited with code: $MOUNT_EXIT_CODE"
    MOUNT_SUCCESS=false
fi

if [ "$MOUNT_SUCCESS" = "true" ]; then
    echo "NFS mount successful"
else
    echo "ERROR: NFS mount failed!"
    echo ""
    echo "=== Diagnostics ==="
    echo "rpcinfo output:"
    rpcinfo -p nfs 2>&1 || echo "rpcinfo failed"
    echo ""
    echo "Trying showmount:"
    showmount -e nfs 2>&1 || echo "showmount failed"
    echo ""
    echo "Checking dmesg for NFS errors:"
    dmesg | tail -20 2>&1 || echo "dmesg not available"
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

# Wait for socket to be created
echo "Waiting for PHP-FPM socket..."
while [ ! -S /run/php-fpm/www.sock ]; do
    sleep 0.5
done
echo "PHP-FPM socket created"

# Fix permissions on the socket so Apache (user websvc) can read/write to it
chown websvc:webgrp /run/php-fpm/www.sock
chmod 0660 /run/php-fpm/www.sock

#runs apache in forground as main container process (PID1)
echo "Starting Apache"
exec /usr/sbin/httpd -D FOREGROUND