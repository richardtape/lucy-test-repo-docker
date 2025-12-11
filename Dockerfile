FROM rockylinux/rockylinux:9.3

#install Apache, enable HTTPS, be able to generate SLL certs; clean cache 
RUN dnf -y install httpd mod_ssl && dnf clean all

COPY www_data/ /var/www/html/

#HTTP and HTTPS
EXPOSE 80 443

CMD ["/usr/sbin/httpd", "-D", "FOREGROUND"]