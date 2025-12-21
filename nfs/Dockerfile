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

# Copy entrypoint script and make it executable 
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh


# Expose NFS-related ports
EXPOSE 2049

#run entrypoint.sh
ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]
