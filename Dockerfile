FROM rockylinux/rockylinux:9.3

#Install Apache, PHP, enable HTTPS, be able to generate SLL certs; clean cache 
RUN dnf -y install httpd mod_ssl php php-fpm php-cli php-common php-mysqlnd && dnf clean all

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