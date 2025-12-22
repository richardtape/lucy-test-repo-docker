#!/usr/bin/env bash

#exit on error, unset variable, pipeline fail
set -euo pipefail

#allow mount to web-node from NFS 
cat <<EOF > /etc/exports
/exports/shared *(rw,sync,no_subtree_check,root_squash,anonuid=1001,anongid=1001)
# Add another in the future
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

echo "Starting nfs daemon in foreground"
rpc.nfsd -V 4 8

echo "NFS server is running"

sleep 86400