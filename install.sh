#!/bin/sh

# Annotation
# Аннотация 
echo -e "\033[36;40m--------------------------------------------- 
EN            Installing webserver on        |
EN       Alpine Linux with onenlitespeed.    |
---------------------------------------------	
---------------------------------------------
RU            Установка вебсервера на        |
RU         Alpine Linux с openlitespeed.     |
--------------------------------------------- \e[0m";
echo ' ';

# Adding repositories
# Добавление репозиториев
sed -i 's/#http/http/g' /etc/apk/repositories;

echo -e "\033[36;40m---------------------------------------------
EN          Update apk repositories          |
---------------------------------------------
---------------------------------------------
RU          Обновление репозиториев          |
--------------------------------------------- \e[0m";
apk update;

echo -e "\033[36;40m--------------------------------------------- 
EN               Upgrade system              |
---------------------------------------------
---------------------------------------------
RU               Апгрейд системы             |
--------------------------------------------- \e[0m";
apk upgrade;

if [ ! -e "/etc/litespeed" ]; then
echo -e "\033[36;40m--------------------------------------------- 
EN       Install openlitespeed and php7      |
--------------------------------------------- 
---------------------------------------------
RU       Установка openlitespeed и php7      |
--------------------------------------------- \e[0m";
	apk add litespeed;
	rc-update add litespeed;
	rc-service litespeed start;
fi;

if [ ! -e '/etc/acf/' ]; then
echo -e "\033[36;40m--------------------------------------------- 
EN   Install Alpine Configuration Framework  |
---------------------------------------------
---------------------------------------------
RU  Установка Alpine Configuration Framework |
--------------------------------------------- \e[0m";	
setup-acf;
sed -i 's/443/4444/g' /etc/mini_httpd/mini_httpd.conf;
/etc/init.d/mini_httpd restart;
fi;

if [ ! -e '/etc/init.d/memcached' ]; then
echo -e "\033[36;40m--------------------------------------------- 
EN        Install required php extensions    |
EN               and memcached               |
---------------------------------------------
---------------------------------------------
RU     Установка необходимых расширений php  |
RU                и memcached                |
--------------------------------------------- \e[0m";		
apk add php7-xml php7-fileinfo php7-ftp php7-curl php7-pdo php7-pdo_mysql php7-pdo_sqlite php7-intl php7-memcache php7-memcached;
apk add php7-dom php7-exif php7-ldap php7-opcache php7-pecl-imagick php7-openssl php7-simplexml php7-json php7-iconv memcached;
rc-service memcached start;
rc-update add memcached;
pkill lsphp;
fi;

if [ ! -e '/root/.config/lftp/rc' ]; then
mkdir /root/.config;
mkdir /root/.config/lftp;
echo -e "\033[36;40m--------------------------------------------- 
EN       Install lftp and proftpd            |
---------------------------------------------
---------------------------------------------
RU       Установка lftp и proftpd            |
--------------------------------------------- \e[0m";		
apk add lftp proftpd;
rc-service proftpd start;
rc-update add proftpd;
sed -i 's/#DefaultRoot ~/DefaultRoot     ~ !adm/g'  /etc/proftpd/proftpd.conf;
sed -i '/command/ a \*/5	*	*	*	*	run-parts /etc/periodic/5min' /etc/crontabs/root;
fi;

if [ ! -e "/usr/bin/mariadbd" ]; then
echo -e "\033[36;40m--------------------------------------------- 
EN            Install mariadb                |
---------------------------------------------
---------------------------------------------
RU           Установка mariadb               |
--------------------------------------------- \e[0m";	
apk add mariadb mariadb-client;
rc-update add mariadb;
/etc/init.d/mariadb setup;
rc-service mariadb start;
	
# mysql secure settings
# Настройки безопасности mariadb
mysql_secure(){
echo -e "\033[32;40m--------------------------------------------- 
EN       Enter new root password mysql.      |
---------------------------------------------
---------------------------------------------
RU    Введите новый пароль root для mysql.   |
--------------------------------------------- \e[0m";		
read -sp 'Root password: ' rpass;
echo ' ';
read -sp 'Retype password: ' rpass1;
if [ $rpass == $rpass1 ]; then
echo -e "\ny\ny\n$rpass\n$rpass\ny\ny\ny\ny" | mysql_secure_installation;
else
echo -e "\033[31;40m--------------------------------------------- 
EN      Passwords don't match. Start again.  |
---------------------------------------------
---------------------------------------------
RU     Пароли не совпадают. Начните заново.  |
--------------------------------------------- \e[0m";			
mysql_secure;
fi;
}	
mysql_secure;
fi;

# Add settings for mysqldump
# Добавление настроек для резервного копирования базы данных сайта
if [ ! -e "/root/.my.cnf" ]; then 
	echo -e [mysqldump]  > /root/.my.cnf;
	echo -e user=$username  >> /root/.my.cnf;
	echo -e password=$userpassword >> /root/.my.cnf
	chmod 0600 /root/.my.cnf
fi 

if [ ! -e "/usr/share/webapps/phpmyadmin" ]; then
echo -e "\033[36;40m--------------------------------------------- 
EN          Install phpmyadmin               |
---------------------------------------------
---------------------------------------------
RU         Установка phpmyadmin              |
--------------------------------------------- \e[0m";	
apk add phpmyadmin;
cat >> /etc/litespeed/httpd_config.conf << EOF
virtualhost phpmyadmin {
  vhRoot                  /usr/share/webapps/phpmyadmin
  configFile              conf/vhosts/phpmyadmin/vhconf.conf
  allowSymbolLink         1
  enableScript            1
  restrained              1
  setUIDMode              0
}
listener phpmyadmin {
  address                 *:7777
  secure                  0
  map                     phpmyadmin *
}
EOF
mkdir '/etc/litespeed/vhosts/phpmyadmin';
cat > /etc/litespeed/vhosts/phpmyadmin/vhconf.conf << EOF
docRoot                   \$VH_ROOT
enableGzip                1
index  {
useServer               0
indexFiles              index.php
autoIndex               1
}
EOF
chown -R litespeed:litespeed /etc/litespeed/vhosts/phpmyadmin;
fi;

# Installing webmail
# Установка почты
if [ ! -e "/usr/share/webapps/rainloop" ]; then
echo -e "\033[36;40m--------------------------------------------- 
EN          Install rainloop-webmail         |
---------------------------------------------
---------------------------------------------
RU         Установка rainloop-webmail        |
--------------------------------------------- \e[0m";	
mkdir /usr/share/webapps/rainloop;
cd /usr/share/webapps/rainloop;
wget http://www.rainloop.net/repository/webmail/rainloop-community-latest.zip;
unzip rainloop-community-latest.zip > /dev/null;
rm rainloop-community-latest.zip;
cd ~;
chown -R litespeed:litespeed /usr/share/webapps/rainloop/*;
apk add dovecot;
rc-service dovecot start;
rc-update add dovecot;
apk add exim;
rc-service exim start;
rc-update add exim;
cat >> /etc/litespeed/httpd_config.conf << EOF
virtualhost rainloop {
  vhRoot                  /usr/share/webapps/rainloop
  configFile              conf/vhosts/rainloop/vhconf.conf
  allowSymbolLink         1
  enableScript            1
  restrained              1
  setUIDMode              0
}
listener rainloop {
  address                 *:9999
  secure                  0
  map                     rainloop *
}

listener HTTP {
  address                 *:80
  secure                  0
}
EOF
mkdir /etc/litespeed/vhosts/rainloop;
cat > /etc/litespeed/vhosts/rainloop/vhconf.conf << EOF
docRoot                   \$VH_ROOT
enableGzip                1
index  {
useServer               0
indexFiles              index.php
autoIndex               1
}
EOF

chown -R litespeed:litespeed /etc/litespeed/vhosts/rainloop;
rc-service litespeed restart;
fi;

# Off ssl checking for ftp connection
# Отключение проверки сертификата ssl для ftp соединения с сервером бэкапов
if [ ! -e "/root/.config/lftp/rc" ]; then 
	echo -e "set ssl:verify-certificate no" > /root/.config/lftp/rc
	chmod 0600 /root/.config/lftp/rc;
fi;	

# Create new user and site
# Создание нового пользователя и сайта
addsite() {
echo -e "\033[32;40m--------------------------------------------- 
EN          Enter the name of the site       |
EN             you want to create.           |
EN            Example: mysite.com            |
---------------------------------------------
---------------------------------------------
RU              Введите имя сайта,           |
RU          который Вы хотите создать.       |
RU             Например: mysite.ru           |
--------------------------------------------- \e[0m";		
read -p 'Site name: ' sitename;
if [ -e /home/$username/$sitename ]; then 
echo -e "\033[32;40m--------------------------------------------- 
EN   \e[0m\033[31;40m         Site already exists!   \e[0m\033[32;40m        |
EN             Create a new site!            |
---------------------------------------------
---------------------------------------------
RU     \e[0m\033[31;40m       Такой сайт уже есть! \e[0m\033[32;40m          |
RU            Создайте новый сайт!           |
--------------------------------------------- \e[0m";
addsite;
fi;
chown -R $username:$username /home/$username;

cat >> /etc/litespeed/httpd_config.conf <<EOF
virtualhost $sitename {
vhRoot                  /home/$username/$sitename
configFile              conf/vhosts/$sitename/vhconf.conf
allowSymbolLink         1
enableScript            1
restrained              1
setUIDMode              2
}
EOF
mkdir /etc/litespeed/vhosts/$sitename;
cat > /etc/litespeed/vhosts/$sitename/vhconf.conf <<EOF
docRoot                   \$VH_ROOT
enableGzip                1

index  {
useServer               0
indexFiles              index.php
autoIndex               1
}
		
rewrite  {
enable                  1
autoLoadHtaccess        1
}
EOF

chown -R litespeed:litespeed /etc/litespeed/vhosts/$sitename;
sed -i '/*:80$/ a \'"map                     $sitename $sitename"'' /etc/litespeed/httpd_config.conf;
cd /home/$username;
wget https://github.com/instantsoft/icms2/archive/refs/heads/master.zip;
unzip master.zip > /dev/null;
mv icms2-master $sitename;
rm master.zip;
chown -R $username:$username /home/$username/$sitename;
cd ~;
echo -e "\033[36;40m--------------------------------------------- 
EN Downloaded and extracted latest InstantCMS|
---------------------------------------------
---------------------------------------------
RU   Скачан и распакован свежий InstantCMS   |
--------------------------------------------- \e[0m";	
rc-service litespeed restart
echo Site: $sitename > /root/.$username;
echo User: $username >> /root/.$username;
echo Password: $userpassword >> /root/.$username;
mkdir /home/$username/backups/$sitename;
chown $username:$username /home/$username/backups/$sitename;
}

user_add() {
echo -e "\033[32;40m--------------------------------------------- 
EN      Create a user, owner of your sites.  |
EN          One word in latin letters.       |
--------------------------------------------- 
--------------------------------------------- 
RU            Создайте пользователя,         |
RU            владельца ваших сайтов.        |
RU        Одно слово латинскими буквами.     |
--------------------------------------------- \e[0m";		
read -p 'User name: ' username;
if [ -e /home/$username ]; then
echo -e "\033[32;40m-------------------------------------------- 
EN   \e[0m\033[31;40m           User already exists!   \e[0m\033[32;40m      |
EN       Do you want to create a new user    |
EN           or continue with this?          |
EN        Continue with this: enter 1,       |
EN            Create new: enter 2            |
---------------------------------------------
---------------------------------------------
RU \e[0m\033[31;40m        Такой пользователь уже есть! \e[0m\033[32;40m     |
RU      Хотите создать нового пользователя   |
RU            или продолжить с этим?         |
RU        Продолжить с этим: введите 1,      |
RU          Создать нового: введите 2        |
--------------------------------------------- \e[0m";		
read -p 'Continue 1 or Create 2: ' userchoice;
if [ $userchoice == 1 ]; then
addsite;
elif [ $userchoice == 2 ]; then
user_add;
fi;
else
echo -e "\033[32;40m--------------------------------------------- 
EN             Enter user password.          |
---------------------------------------------
---------------------------------------------
RU        Введите пароль пользователя.       |
--------------------------------------------- \e[0m";	
read -p 'User password:   ' userpassword;
read -p 'Retype password: ' userpassword1;
if [ $userpassword == $userpassword1 ]; then
adduser -D --shell /bin/ash $username
echo $username:$userpassword | chpasswd $username:$userpassword > /dev/null;
mkdir /home/$username/backups;
chown -R $username:$username /home/$username/backups;
addsite;
else
echo -e "\033[31;40m--------------------------------------------- 
EN    Passwords don't match. Start again.    |
---------------------------------------------
---------------------------------------------
RU    Пароли не совпадают. Начните заново.   |
--------------------------------------------- \e[0m";	
user_add;
fi;
fi;
}
user_add;

# Creating mysql user and database for this site
# Создание пользователя mysql и базы данных для сайта
usersearch=`mysql  -e "SELECT user FROM mysql.user WHERE user = '$username'" | grep $username`;
if [ $usersearch == $username ]; then
continue;
else
mysql -e "CREATE USER ${username}@localhost IDENTIFIED BY '${userpassword}';"
fi;
base=${sitename/./_};
dbsearch=`mysql  -e "SHOW DATABASES" | grep ${base}`;
if [ ${dbsearch}!=${base} ]; then
mysql -e "CREATE DATABASE ${base} /*\!40100 DEFAULT CHARACTER SET utf8 */;"	
mysql -e "GRANT ALL PRIVILEGES ON ${base}.* TO '${username}'@'localhost';"
mysql -e "FLUSH PRIVILEGES;";
echo -e "\033[36;40m--------------------------------------------- 
EN            Site $sitename was created.
EN            Database ${base} was created.                  
---------------------------------------------
---------------------------------------------
RU            Сайт $sitename создан.
RU            База данных ${base} создана.                 
--------------------------------------------- \e[0m";	
echo Database: $base >> /root/.$username;
fi;

# Add settings for ftp connection 
# Добавление настроек соединения с ftp сервером для бэкапов
if [ ! -e "/root/.netrc" ]; then
echo -e "\033[32;40m--------------------------------------------- 
EN        Have you ftp backup server?        |
---------------------------------------------
---------------------------------------------
RU    У Вас уже есть ftp сервер для бэкапов? |
--------------------------------------------- \e[0m";
read -p 'Yes y or No n: ' ftpchoice;
if [[ $ftpchoice != y* ]]; then 
echo -e "\033[33;40m--------------------------------------------- 
EN  Then your backups will saving in 
EN  /home/${username}/backups/$sitename.   
---------------------------------------------
---------------------------------------------
RU  Тогда ваши бэкапы будут сохраняться в 
RU  /home/${username}/backups/$sitename. 
--------------------------------------------- \e[0m";	
else
echo -e "\033[32;40m--------------------------------------------- 
EN      Enter ftp backup server address.     |
EN (You should already have this ftp server.)|
---------------------------------------------
---------------------------------------------
RU           Введите адрес ftp сервера       |
RU           для резервного копирования.     |
RU         (Вы должны иметь уже готовый      |
RU            ftp сервер для бэкапов.)       |
--------------------------------------------- \e[0m";
read -p 'ftp server: ' ftp_server;
echo -e "\033[32;40m--------------------------------------------- 
EN      Enter ftp backup server user name.   |
---------------------------------------------
---------------------------------------------
RU         Введите имя пользователя          |
RU   ftp сервера для резервного копирования. |
--------------------------------------------- \e[0m";
read -p 'ftp user: ' ftp_user;
echo -e "\033[32;40m--------------------------------------------- 
EN   Enter ftp backup server user password.  |
---------------------------------------------
---------------------------------------------
RU       Введите пароль пользователя         |
RU  ftp сервера для резервного копирования.  |
--------------------------------------------- \e[0m";
read -p 'ftp password: ' ftp_password;
echo -e machine $ftp_server > /root/.netrc;
echo -e login $ftp_user >> /root/.netrc;
echo -e password $ftp_password >> /root/.netrc;
chmod 0600 /root/.netrc;
fi;
fi;

mkdir /etc/periodic/5min;
echo "#!/bin/sh" > /etc/periodic/5min/$base;
echo "/usr/bin/php /home/$username/$sitename/cron.php $sitename > /dev/null" >> /etc/periodic/5min/$base;
chmod 0755 /etc/periodic/5min/$base;

cat > /etc/periodic/daily/$base <<EOF
#!/bin/sh
tar -cjvf /home/$username/backups/$sitename/$sitename-\$(date '+%d%m%y_%H:%M').tar.bz2 /home/$username/$sitename

mysqldump $base | bzip2 > /home/$username/backups/$sitename/$base-\$(date '+%d%m%y_%H:%M').sql.bz2

find /home/$username/backups/$sitename -type f -mmin +16 -exec rm -rf {} \;

#lftp -f /home/alp/backup.ftp
EOF
chmod 0755 /etc/periodic/daily/$base;

# Adding buttons to Openliteserver admin panel
# Добавление кнопок в админпанель openliteserver
butt=",'pma' => array(\n \
'title' => 'Phpmyadmin',\n \
'url' => 'http://$sitename:7777',\n \
'url_target' => '_blank',\n \
'icon' => 'fa-database'),\n \
'rc' => array(\n \
'title' => 'Webmail rainloop',\n \
'url_target' => '_blank',\n \
'url' => 'http://$sitename:9999',\n \
'icon' => 'fa-envelope-o'),\n \
'acf' => array(\n \
'title' => 'ACF',\n \
'url_target' => '_blank',\n \
'url' => 'https://$sitename:4444',\n \
'icon' => 'fa-cogs')";

sed -i '89a '"$butt"'' /var/lib/litespeed/admin/html.open/view/inc/configui.php;

echo -e "\033[32;40m--------------------------------------------- 
EN   Openlitespeed, php, mysql, phpmyadmin,        
EN   rainloop and InstantCMS is installed!         
EN   Your site          \033[36;40m http://$sitename\033[32;40m
EN   Database name:     \033[36;40m $base\033[32;40m
EN   Database user:     \033[36;40m $username\033[32;40m
EN   Database password: \033[36;40m $userpassword\033[32;40m
EN   Backups folder:    \033[36;40m /home/${username}/backups/$sitename\033[32;40m
EN   ftp user           \033[36;40m $username\033[32;40m
En   ftp password       \033[36;40m $userpassword\033[32;40m
EN   OLS webadminpanel  \033[36;40m http://$sitename:7080\033[32;40m
EN   Phpmyadmin address \033[36;40m http://$sitename:7777\033[32;40m
EN   Rainloop address   \033[36;40m http://$sitename:9999\033[32;40m
EN   Alpine Configuration Framework \033[36;40m https://$sitename:4444\033[32;40m
---------------------------------------------
---------------------------------------------
RU   Openlitespeed, php, mysql, phpmyadmin,        
RU   rainloop и InstantCMS установлены!        
RU   Ваш сайт           \033[36;40m http://$sitename\033[32;40m
RU   Имя базы данных:   \033[36;40m $base\033[32;40m
RU   Пользователь базы: \033[36;40m $username\033[32;40m
RU   Пароль базы:       \033[36;40m $userpassword\033[32;40m
RU   Папка бэкапов:     \033[36;40m /home/${username}/backups/$sitename\033[32;40m
RU   Пользователь ftp   \033[36;40m $username\033[32;40m
RU   Пароль ftp         \033[36;40m $userpassword\033[32;40m
RU   OLS webadminpanel  \033[36;40m http://$sitename:7080\033[32;40m
RU   Адрес phpmyadmin   \033[36;40m http://$sitename:7777\033[32;40m
RU   Адрес rainloop     \033[36;40m http://$sitename:9999\033[32;40m
RU   Alpine Configuration Framework  \033[36;40m https://$sitename:4444\033[32;40m
---------------------------------------------\e[0m";



