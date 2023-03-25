#!/bin/bash

yum install -y wget rpmdevtools rpm-build createrepo yum-utils gcc podman-docker

wget -O /root/nginx-1.22.1-1.el8.ngx.src.rpm  https://nginx.org/packages/centos/8/SRPMS/nginx-1.22.1-1.el8.ngx.src.rpm
rpm -i /root/nginx-1.22.1-1.el8.ngx.src.rpm

wget -O /root/openssl-1.1.1t.tar.gz https://www.openssl.org/source/openssl-1.1.1t.tar.gz
tar -xf /root/openssl-1.1.1t.tar.gz -C /root/

yum-builddep /root/rpmbuild/SPECS/nginx.spec -y
sed -i '/--with-ld-opt="%{WITH_LD_OPT}" \\/a\    --with-openssl=/root/openssl-1.1.1t \\' /root/rpmbuild/SPECS/nginx.spec
rpmbuild -bb /root/rpmbuild/SPECS/nginx.spec 

yum localinstall -y /root/rpmbuild/RPMS/x86_64/nginx-1.22.1-1.el9.ngx.x86_64.rpm 
sed -i '/index  index.html index.htm\;/a\        autoindex on\;' /etc/nginx/conf.d/default.conf
systemctl --now enable nginx

mkdir /usr/share/nginx/html/repo
cp /root/rpmbuild/RPMS/x86_64/nginx-1.22.1-1.el9.ngx.x86_64.rpm /usr/share/nginx/html/repo
createrepo /usr/share/nginx/html/repo/

cat >> /etc/yum.repos.d/otus.repo << EOF
[otus]
name=otus-linux
baseurl=http://localhost/repo/
gpgcheck=0
enabled=1
EOF

cp /root/rpmbuild/RPMS/x86_64/nginx-1.22.1-1.el9.ngx.x86_64.rpm /vagrant/nginx-image/files

docker build -t nginx:1.0 /vagrant/nginx-image

docker run -d -p 9090:80 --name webserver localhost/nginx:1.0