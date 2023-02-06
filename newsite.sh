#!/bin/ash
set -e

#REPOSITORIES
if grep "nginx" /etc/apk/repositories; then
continue
else
sed -i 's/#http/http/g' /etc/apk/repositories;
apk --allow-untrusted update
apk --allow-untrusted upgrade
fi

########################################################

#USER
read -p "Username: " username
read -p "Userpassword: " userpassword
read -p "Sitename: " sitename

if [ ! -e "/home/$username" ]; then
	
adduser -D --shell /bin/ash $username

mkdir /home/$username/www
mkdir /home/$username/www/$sitename

fi

#####################################################

#NGINX
if [ ! -e "/etc/nginx" ]; then
apk add --allow-untrusted openssl curl ca-certificates

printf "%s%s%s%s\n" \
    "@nginx " \
    "http://nginx.org/packages/mainline/alpine/v" \
    `egrep -o '^[0-9]+\.[0-9]+' /etc/alpine-release` \
    "/main" \
    | tee -a /etc/apk/repositories
	
curl -o /tmp/nginx_signing.rsa.pub https://nginx.org/keys/nginx_signing.rsa.pub

mv /tmp/nginx_signing.rsa.pub /etc/apk/keys/

apk add --allow-untrusted nginx@nginx

apk add --allow-untrusted nginx-module-image-filter@nginx nginx-module-njs@nginx

rc-service nginx restart
rc-update add nginx

fi

#####################################################

#PHP
apk add --allow-untrusted php82-fpm php82-gd php82-session php82-mbstring php82-fileinfo
apk add --allow-untrusted php82-mysqli php82-json php82-curl php82-ftp php82-zip
apk add --allow-untrusted php82-pecl-memcache php82-pecl-memcached

rc-update add php-fpm82 default

apk add --allow-untrusted memcached
rc-update add memcached default

######################################################

#MARIADB
if [ ! -e "/root/packages" ]; then
tar xvf /root/mariadb1100_apk.tar.gz
fi

if [ ! -e "/usr/bin/mariadbd" ]; then
	
cat <<EOT >> /etc/apk/repositories
/root/packages/ris

EOT

apk --allow-untrusted update

apk add --allow-untrusted mariadb mariadb-client

rc-update add mariadb;
/etc/init.d/mariadb setup;
rc-service mariadb start;

read -p "Mysql rootpassword: " rpass

echo -e "\ny\ny\n$rpass\n$rpass\ny\nn\ny\ny" | mysql_secure_installation;

fi

# usersearch=`mariadb  -e "SELECT user FROM mysql.user WHERE user = '$username'" | grep $username` > /dev/null;
# if [ -e || $usersearch $usersearch == $username ]; then
# continue;
# else
mariadb -e "CREATE USER '$username'@'%' IDENTIFIED BY '$userpassword';"
mariadb -e "CREATE DATABASE ${username} /*\!40100 DEFAULT CHARACTER SET utf8 */;"
mariadb -e "GRANT ALL PRIVILEGES ON $username.* TO '$username'@'%';"
mariadb -e "FLUSH PRIVILEGES;";

# fi
#######################################################################

#PHPMYADMIN
if [ ! -e "/home/$username/www/phpmyadmin/index.php" ]; then
	
sed -i 's/eth0 inet/eth0 inet4/' /etc/network/interfaces

/etc/init.d/networking restart

if [ ! -e /home/$username/www/phpmyadmin ]; then
	mkdir /home/$username/www/phpmyadmin
fi

curl -O https://files.phpmyadmin.net/phpMyAdmin/5.2.0/phpMyAdmin-5.2.0-all-languages.zip
mv phpMyAdmin-5.2.0-all-languages.zip /home/$username/www/phpMyAdmin-5.2.0-all-languages.zip
unzip /home/$username/www/phpMyAdmin-5.2.0-all-languages.zip -d /home/$username/www
mv -f /home/$username/www/phpMyAdmin-5.2.0-all-languages/* /home/$username/www/phpmyadmin

fi

###########################################################################

#HOSTS_NGINX
if [ -e /etc/nginx/conf.d/${sitename}.conf ]; then
	rm -f /etc/nginx/conf.d/${sitename}.conf
fi

if [ -e /etc/nginx/conf.d/phpmyadmin.conf ]; then
	rm -f /etc/nginx/conf.d/phpmyadmin.conf
fi

touch /etc/nginx/conf.d/${sitename}.conf

touch /etc/nginx/conf.d/phpmyadmin.conf

cat <<EOT >> /etc/nginx/conf.d/${sitename}.conf
server {
	listen 80 default_server;
	listen [::]:80 default_server;
	server_name  $sitename;
	root                    /home/$username/www/$sitename;
	index                   index.php index.html index.htm;
	client_max_body_size    32m;
	error_page              500 502 503 504  /50x.html;
	location = /50x.html {
		root              /var/lib/nginx/html;
	}
	location / {
        index index.php;
        try_files \$uri \$uri/ /index.php?\$args;
	}
	
    location ~ \.php$ {
        include /etc/nginx/fastcgi_params;
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param DOCUMENT_ROOT \$document_root;
	}
}

EOT

cat <<EOT >> /etc/nginx/conf.d/phpmyadmin.conf
server {
	listen 7081;
	listen [::]:7081;
	server_name  $sitename;
	root                    /home/$username/www/phpmyadmin;
	index                   index.php index.html index.htm;
	client_max_body_size    32m;
	error_page              500 502 503 504  /50x.html;
	location = /50x.html {
		root              /var/lib/nginx/html;
	}
	location / {
        index index.php;
        try_files \$uri \$uri/ /index.php?\$args;
	}
	
    location ~ \.php$ {
        include /etc/nginx/fastcgi_params;
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param DOCUMENT_ROOT \$document_root';
	}
}
EOT

chown -R ${username}:${username} /home/$username

rc-service nginx restart

#############################################################################

#SITE
wget https://github.com/instantsoft/icms2/archive/refs/heads/master.zip -O /home/$username/www/$sitename/master.zip
unzip /home/$username/www/$sitename/master.zip -d /home/$username/www/$sitename
chown -R ${username}:${username} /home/$username
mv -n /home/$username/www/$sitename/icms2-master/* /home/$username/www/$sitename > /dev/null

if grep 'AllowDinamicPropperties' /home/rek/www/reklife.ru/system/core/controller.php > /dev/null; then
	continue
	else
	echo 'controller'
	sed -i '/^class/i \#[AllowDynamicProperties] ' /home/rek/www/reklife.ru/system/core/controller.php
fi
if grep 'AllowDinamicPropperties' /home/rek/www/reklife.ru/system/core/user.php > /dev/null; then
	continue
	else
	echo 'user'
	sed -i '/^class/i \#[AllowDynamicProperties] ' /home/rek/www/reklife.ru/system/core/user.php
fi
if grep 'AllowDinamicPropperties' /home/rek/www/reklife.ru/system/core/formfield.php > /dev/null; then
	continue
	else
	echo 'formfield'
	sed -i '/^class/i \#[AllowDynamicProperties] ' /home/rek/www/reklife.ru/system/core/formfield.php
fi
if grep 'AllowDinamicPropperties' /home/rek/www/reklife.ru/system/core/widget.php > /dev/null; then
	continue
	else
	echo 'widget'
	sed -i '/^class/i \#[AllowDynamicProperties] ' /home/rek/www/reklife.ru/system/core/widget.php
fi

chown -R ${username}:${username} /home/$username

/etc/init.d/php-fpm82 restart

echo "SITE READY!"

##############################################################################



