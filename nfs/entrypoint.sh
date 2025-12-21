#!/usr/bin/env bash

#exit on error, unset variable, pipeline fail
set -euo pipefail

#allow mount to web-node from NFS 
cat <<EOF > /etc/exports
/exports/shared web-node(rw,sync,no_subtree_check,root_squash,anonuid=1001,anongid=1001)
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
rpc.mountd -F &

echo "Starting nfs daemon in foreground"
exec rpc.nfsd -F -V 4 8

