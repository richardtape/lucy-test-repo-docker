#!/usr/bin/env bash
#exit on error, unset variable, pipeline fail
set -euo pipefail

#wait until nfs is ready; if not sleep for 1 sec; all stdout and stderr go to /dev/null (blackhole)
echo "Waiting for the NFS Server to be ready"
until nc -z nfs 2049 
do
    echo "NFS Server not ready yet..."
    sleep 1
done
sleep 5
echo "NFS Server is ready"

# Resolve NFS IP once
NFS_IP=$(getent hosts nfs | awk '{print $1}')
echo "Resolved NFS IP: $NFS_IP"

echo "Creating mount point"
mkdir -p /www_data/www

echo "Mounting NFS shared directory"
#mount -t nfs4 "$NFS_IP:/exports/shared" /www_data/www
mount -t nfs4 nfs:/exports/shared /www_data/www

echo "Starting PHP-FPM daemon in background"
php-fpm -D

#runs apache in forground as main container process (PID1)
echo "Starting Apache"
exec /usr/sbin/httpd -D FOREGROUND