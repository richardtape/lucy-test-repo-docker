FROM rockylinux/rockylinux:9.3

#Install Apache, PHP, enable HTTPS, be able to generate SLL certs; clean cache 
RUN dnf -y install httpd mod_ssl php php-fpm php-cli php-common php-mysqlnd && dnf clean all

#Creates /run/php-fpm directory needed for php-fpm as it is not automatically created by the container
RUN mkdir -p /run/php-fpm

#Copy site content
COPY www_data/ /var/www/html/

#Allow HTTP redirects
COPY conf/apache/http-redirect.conf /etc/httpd/conf.d/

#Configure Apache to send PHP files to PHP-FPM via the default Unix socket
COPY conf/apache/php-fpm.conf /etc/httpd/conf.d/

#HTTP and HTTPS
EXPOSE 80 443

#run php-fpm in background, Apache as main container process in forground 
CMD ["/bin/bash", "-c", "php-fpm && exec /usr/sbin/httpd -D FOREGROUND"]