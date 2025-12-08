FROM rockylinux/rockylinux:9.3
RUN dnf -y install httpd
COPY www_data/ /var/www/html/
EXPOSE 80
CMD ["/usr/sbin/httpd", "-D", "FOREGROUND"]