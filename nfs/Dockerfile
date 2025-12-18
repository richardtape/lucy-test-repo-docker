FROM rockylinux/rockylinux:9.3

# Install NFS utilities
RUN dnf -y install \
    nfs-utils \
    rpcbind \
    && dnf clean all

# Create the shared service identity (match this in web-node too)
RUN groupadd -g 1001 webgrp \
 && useradd  -u 1001 -g 1001 -M -s /sbin/nologin websvc

# Create export directory
RUN mkdir -p /exports/shared
RUN chown -R 1001:1001 /exports/shared

# Copy NFS export rules
COPY exports/exports /etc/exports

# Expose NFS-related ports
EXPOSE 2049 111

# Start rpcbind + NFS server
CMD ["/bin/bash", "-lc", "\
mkdir -p /run/nfs && \
rpcbind -w && \
rpc.mountd -F & \
exportfs -rv && \
exec rpc.nfsd -F -V 4 8 \
"]
