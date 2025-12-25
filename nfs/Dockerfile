FROM rockylinux/rockylinux:9

# Clean DNF cache to avoid module metadata corruption issues
RUN dnf clean all && rm -rf /var/cache/dnf

# Install necessary packages including NFS-Ganesha (Rocky/CentOS Storage SIG)
# We enable 'crb' (Code Ready Builder) for dependencies, then epel, then storage SIG.
RUN dnf -y install 'dnf-command(config-manager)'
RUN dnf config-manager --set-enabled crb
RUN dnf -y install epel-release
RUN dnf -y install centos-release-nfs-ganesha
RUN dnf -y install nfs-ganesha nfs-ganesha-vfs rpcbind procps-ng iproute hostname rsync inotify-tools
RUN dnf clean all

# Setup exports directory
RUN mkdir -p /exports/shared
RUN chown -R 1001:1001 /exports/shared

# Copy Ganesha config
COPY ganesha.conf /etc/ganesha/ganesha.conf

# Copy entrypoint script and make it executable 
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose NFS-related ports
EXPOSE 111 2049 20048

#run entrypoint.sh
ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]
