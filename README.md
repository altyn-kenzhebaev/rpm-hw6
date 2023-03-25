# Управление пакетами. Дистрибьюция софта
Для выполнения этого действия требуется установить приложением git:
`git clone https://github.com/altyn-kenzhebaev/rpm-hw6.git`
В текущей директории появится папка с именем репозитория. В данном случае hw-1. Ознакомимся с содержимым:
```
cd rpm-hw6
ls -l
rpm_repo_create.sh
README.md
Vagrantfile
```
Здесь:
- README.md - файл с данным руководством
- Vagrantfile - файл описывающий виртуальную инфраструктуру для `Vagrant`
- rpm_repo_create.sh - файл-скрипт, создающий RPM и Docker
Запускаем ВМ:
```
vagrant up
```
### Создание своего RPM
Устанавливаем недостующие пакеты:
```
yum install -y wget rpmdevtools rpm-build createrepo yum-utils gcc podman-docker
```
Скачиваем RPM-пакет с исходным кодом, который хотим пересобрать:
```
wget https://nginx.org/packages/centos/8/SRPMS/nginx-1.22.1-1.el8.ngx.src.rpm
rpm -i nginx-1.*
```
Скачиваем библеотеку, с которой хотим пересобрать RPM-пакет:
```
wget https://www.openssl.org/source/openssl-1.1.1t.tar.gz
tar -xvf openssl-1.1.1t.tar.gz
```
Собираем пакет:
```
yum-builddep rpmbuild/SPECS/nginx.spec 
sed -i '/--with-ld-opt="%{WITH_LD_OPT}" \\/a\    --with-openssl=/root/openssl-1.1.1t \\' rpmbuild/SPECS/nginx.spec
rpmbuild -bb rpmbuild/SPECS/nginx.spec
```
Убеждаемся, что пакет собран:
```
[root@repo ~]# ls -l rpmbuild/RPMS/x86_64/
total 4624
-rw-r--r--. 1 root root 2262238 Mar 25 03:35 nginx-1.22.1-1.el9.ngx.x86_64.rpm
-rw-r--r--. 1 root root 2466541 Mar 25 03:35 nginx-debuginfo-1.22.1-1.el9.ngx.x86_64.rpm
[root@repo ~]# 
```
### Создание локального репозитория
Для этого потребуется установка веб-сервера, возьмем наш новособранный пакет:
```
yum localinstall -y rpmbuild/RPMS/x86_64/nginx-1.22.1-1.el9.ngx.x86_64.rpm 
sed -i '/index  index.html index.htm\;/a\        autoindex on\;' /etc/nginx/conf.d/default.conf
systemctl --now enable nginx
```
Разворачиваем собственный репозиторий:
```
mkdir /usr/share/nginx/html/repo
cp rpmbuild/RPMS/x86_64/nginx-1.22.1-1.el9.ngx.x86_64.rpm /usr/share/nginx/html/repo
createrepo /usr/share/nginx/html/repo/
```
Добавляем репозиторийв ОС:
```
cat >> /etc/yum.repos.d/otus.repo << EOF
[otus]
name=otus-linux
baseurl=http://localhost/repo/
gpgcheck=0
enabled=1
EOF
```
### Создание контейнера Docker
Копируем пересобранный RPM-пакет для создания контейнера:
```
cp rpmbuild/RPMS/x86_64/nginx-1.22.1-1.el9.ngx.x86_64.rpm /vagrant/nginx-image/files
```
Разбор Dockerfile:
```
FROM docker.io/almalinux/9-base:latest          #базовый образ
LABEL maintainer="altyn.kenzhebaev@gmail.com"   #Описание, в данныом случае автор
COPY files/nginx-1.22.1-1.el9.ngx.x86_64.rpm /tmp/  #копируем пересобранный RPM-пакет во временную папку
RUN dnf localinstall -y /tmp/nginx-1.22.1-1.el9.ngx.x86_64.rpm && rm -f /tmp/nginx-1.22.1-1.el9.ngx.x86_64.rpm  #Устанавливаем и удаляем пакет
COPY files/default.conf /etc/nginx/conf.d/default.conf  #Подстановка конфиг-файла веб-сервера
COPY files/index.html /usr/share/nginx/html/index.html  #Подстановка страницы приветствия
EXPOSE 80
CMD ["/usr/sbin/nginx", "-g", "daemon off;"]    #
```
Собираем контейнер:
```
docker build -t nginx:1.0 /vagrant/nginx-image
```
Запускаем и смотрим результат:
```
[root@repo ~]# docker run -d -p 9090:80 --name webserver localhost/nginx:1.0
[root@repo ~]# docker ps
CONTAINER ID  IMAGE                COMMAND               CREATED            STATUS                PORTS                 NAMES
2896af931c95  localhost/nginx:1.0  /usr/sbin/nginx -...  About an hour ago  Up About an hour ago  0.0.0.0:9090->80/tcp  webserver
[root@repo ~]# curl http://localhost:9090
<html>
  <head>
    <title>Dockerfile</title>
  </head>
  <body>
    <div class="container">
      <h1>My App</h1>
      <h2>This is my first app</h2>
      <p>Hello everyone, This is running via Docker container</p>
    </div>
  </body>
</html>
```