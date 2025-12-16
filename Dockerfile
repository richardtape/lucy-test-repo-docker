FROM rockylinux/rockylinux:9.3

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
    php-sodium \
    php-opcache \
    php-fileinfo \
    php-dom \
    php-simplexml \
    php-iconv \
    && dnf clean all

#Creates /run/php-fpm directory needed for php-fpm as it is not automatically created by the container
RUN mkdir -p /run/php-fpm

#Copy site content
COPY www_data/ /var/www/html/

#Allow custom Apache configs to be applied 
COPY conf/apache/apache-local.conf /etc/httpd/conf.d/

#load PHP runtime customization
COPY conf/php/99-php.ini /etc/php.d/

#HTTP and HTTPS
EXPOSE 80 443

#run php-fpm in background, Apache as main container process in forground 
CMD ["/bin/bash", "-c", "php-fpm && exec /usr/sbin/httpd -D FOREGROUND"]