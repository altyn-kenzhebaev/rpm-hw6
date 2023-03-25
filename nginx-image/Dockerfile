FROM docker.io/almalinux/9-base:latest
LABEL maintainer="altyn.kenzhebaev@gmail.com" 
COPY files/nginx-1.22.1-1.el9.ngx.x86_64.rpm /tmp/
RUN dnf localinstall -y /tmp/nginx-1.22.1-1.el9.ngx.x86_64.rpm && rm -f /tmp/nginx-1.22.1-1.el9.ngx.x86_64.rpm
COPY files/default.conf /etc/nginx/conf.d/default.conf
COPY files/index.html /usr/share/nginx/html/index.html
EXPOSE 80
CMD ["/usr/sbin/nginx", "-g", "daemon off;"]