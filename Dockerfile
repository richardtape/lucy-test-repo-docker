FROM rockylinux/rockylinux:9.3
RUN dnf -y install httpd
EXPOSE 80
CMD ["/usr/sbin/httpd", "-D", "FOREGROUND"]