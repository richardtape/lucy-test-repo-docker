FROM rockylinux/rockylinux:9

# Clean DNF cache to avoid module metadata corruption issues
RUN dnf clean all && rm -rf /var/cache/dnf

#Install Apache, PHP, PHP extensions, enable HTTPS, be able to generate SLL certs; clean cache 
#Pin PHP version to 8.2;
RUN dnf -y module reset php \
&& dnf -y module enable php:8.2 \
&& dnf -y install \
    httpd \
    mod_ssl \
    php \
    php-fpm \
    php-cli \
    php-common \
    php-mysqlnd \
    php-json \
    php-curl \
    php-mbstring \
    php-openssl \
    php-zip \
    php-xml \
    php-gd \
    php-intl \
    php-exif \
    php-opcache \
    php-fileinfo \
    php-dom \
    php-simplexml \
    php-iconv \
    nfs-utils \
    nmap-ncat \
    && dnf clean all

#create same user and group as nfs
RUN groupadd -g 1001 webgrp \
&& useradd  -u 1001 -g 1001 -M -s /sbin/nologin websvc

#Creates /run/php-fpm directory needed for php-fpm as it is not automatically created by the container
RUN mkdir -p /run/php-fpm

# Copy entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

#HTTP and HTTPS
EXPOSE 80 443

# Use entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]