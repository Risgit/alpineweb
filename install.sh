#!/bin/sh

main() {
# ================================== Introduction ================================================
# =================================== Вступление ================================================= 
echo -e "\033[36;40m--------------------------------------------- 
EN              Installing webserver         |
EN               with openlitespeed.         |
---------------------------------------------	
---------------------------------------------
RU              Установка вебсервера         |
RU                 с openlitespeed.          |
--------------------------------------------- \e[0m";
echo ' ';

# ================================ Adding repositories ===========================================
# ============================== Добавление репозиториев =========================================
sed -i 's/#http/http/g' /etc/apk/repositories;

echo -e "\033[36;40m---------------------------------------------
EN        1. Update apk repositories         |
---------------------------------------------
---------------------------------------------
RU        1. Обновление репозиториев         |
--------------------------------------------- \e[0m";
apk update;

echo -e "\033[36;40m--------------------------------------------- 
EN            2. Upgrade system              |
---------------------------------------------
---------------------------------------------
RU            2. Апгрейд системы             |
--------------------------------------------- \e[0m";
apk upgrade;

if [ ! -e "/etc/init.d/lsws" ]; then
echo -e "\033[36;40m--------------------------------------------- 
EN           3. Install openlitespeed        |
--------------------------------------------- 
---------------------------------------------
RU          3. Установка openlitespeed       |
--------------------------------------------- \e[0m";

# echo -e "\033[32;40m--------------------------------------------- 
# EN          select php version 7 or 8       |
# --------------------------------------------- 
# ---------------------------------------------
# RU         Выберите версию php 7 или 8      |
# --------------------------------------------- \e[0m";
# read -p 'php version 7 or 8: ' phpver;
# if [ $phpver == 8 ]; then
# phpver=8;
# else
# phpver=7;
# fi;
	# # apk add litespeed;
	# # rc-update add litespeed;
	# # rc-service litespeed start;
# fi;
phpver=7;
wget https://github.com/Risgit/alpineweb/raw/Risgit-openlite/lsws.tar.gz;
tar xvf lsws.tar.gz;
mv /root/lsws /usr/local/lsws;

cat > /etc/init.d/lsws << EOF
#!/sbin/openrc-run

description="LiteSpeed Web Server"

lshome=/usr/local/lsws

command=\$lshome/bin/lswsctrl
cfgfile=\$lshome/conf/httpd_config.conf
pidfile=/tmp/lshttpd/lshttpd.pid
required_files="\$cfgfile"

depend() {
	need net
	use dns netmount
}

start() {
	ebegin "Starting \$RC_SVCNAME"
	\$command start >/dev/null
	eend \$?
}

stop() {
	ebegin "Stopping \$RC_SVCNAME"
	\$command stop >/dev/null
	eend \$?
}

restart() {
	ebegin "Restarting \$RC_SVCNAME"
	\$command restart >/dev/null
	eend \$?
}
EOF

chmod 0755 /etc/init.d/lsws;

rc-update add lsws;
rc-service lsws start;

fi;
acf;
newuser
}

# ========================= Install Alpine Configuration Framawork ====================================================
# ========================= Установка Alpine Configuration Framawork ==================================================
acf() {
if [ ! -e '/etc/acf/' ]; then
echo -e "\033[36;40m--------------------------------------------- 
EN 4.Install Alpine Configuration Framework  |
---------------------------------------------
---------------------------------------------
RU 4.Установка Alpine Configuration Framework|
--------------------------------------------- \e[0m";	
setup-acf;
sed -i 's/443/7082/g' /etc/mini_httpd/mini_httpd.conf;
/etc/init.d/mini_httpd restart;
fi;
phpinstall;
}

#======================== Install required php extensions and memcached ===============================================
#========================Установка необходимых расширений php и memcached =============================================
phpinstall() {            
if [ ! -e '/etc/init.d/memcached' ]; then
echo -e "\033[36;40m--------------------------------------------- 
EN     5. Install required php extensions    |
EN               and memcached               |
---------------------------------------------
---------------------------------------------
RU  5. Установка необходимых расширений php  |
RU                и memcached                |
--------------------------------------------- \e[0m";		
apk add php$phpver-litespeed php$phpver-xml php$phpver-fileinfo php$phpver-ftp php$phpver-curl php$phpver-pdo_mysql php$phpver-pdo_sqlite php$phpver-intl;
apk add php$phpver-memcache php$phpver-memcached php$phpver-json php$phpver-iconv memcached php$phpver-zip php$phpver-pecl-memcache php$phpver-fileinfo;
apk add php$phpver-dom php$phpver-exif php$phpver-ldap php$phpver-opcache php$phpver-pecl-imagick php$phpver-openssl php$phpver-simplexml openssh;
apk add php$phpver-bcmath php$phpver-sockets php$phpver-posix php$phpver-gd php$phpver-mysqli php$phpver-curl php$phpver-pecl-memcached bind-tools;
rc-service memcached start;
rc-update add memcached;
pkill lsphp;
fi;
ftpinstall;
}

# ======================= Install lftp and proftpd ====================================================================
# ======================= Установка lftp и proftpd ====================================================================
ftpinstall() {
if [ ! -e '/root/.config/lftp/rc' ]; then
mkdir /root/.config;
mkdir /root/.config/lftp;
echo -e "\033[36;40m--------------------------------------------- 
EN     6. Install lftp and proftpd           |
---------------------------------------------
---------------------------------------------
RU     6. Установка lftp и proftpd           |
--------------------------------------------- \e[0m";		
apk add lftp proftpd;
rc-service proftpd start;
rc-update add proftpd;
sed -i 's/#DefaultRoot ~/DefaultRoot     ~ !adm/g'  /etc/proftpd/proftpd.conf;
sed -i '/command/ a \*/5	*	*	*	*	run-parts /etc/periodic/5min' /etc/crontabs/root;
fi;
dbinstall;
}

# ============================ Install mariadb =======================================================================
# ============================ Установка mariadb =====================================================================
dbinstall() {
if [ ! -e "/usr/bin/mariadbd" ]; then
echo -e "\033[36;40m--------------------------------------------- 
EN         7. Install mariadb                |
---------------------------------------------
---------------------------------------------
RU        7. Установка mariadb               |
--------------------------------------------- \e[0m";	
apk add mariadb mariadb-client;
rc-update add mariadb;
/etc/init.d/mariadb setup;
rc-service mariadb start;
mysql_secure;
fi;
}	
# =========================== mysql secure settings ==================================================================
# ======================= Настройки безопасности mariadb =============================================================
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
dbdumpset;
}

# =========================== Add settings for mysqldump ==============================================================
# ============= Добавление настроек для резервного копирования базы данных сайта ======================================
dbdumpset() {
if [ ! -e "/root/.my.cnf" ]; then 
	echo -e [mysqldump]  > /root/.my.cnf;
	echo -e user=$username  >> /root/.my.cnf;
	echo -e password=$userpassword >> /root/.my.cnf
	chmod 0600 /root/.my.cnf
fi;
phpadmin;
}

# ============================ Install phpmyadmin ======================================================================
# ============================ Установка phpmyadmin ====================================================================
phpadmin() {
if [ ! -e "/usr/share/webapps/phpmyadmin" ]; then
echo -e "\033[36;40m--------------------------------------------- 
EN       8. Install phpmyadmin               |
---------------------------------------------
---------------------------------------------
RU      8. Установка phpmyadmin              |
--------------------------------------------- \e[0m";	
apk add phpmyadmin;
cat >> /usr/local/lsws/conf/httpd_config.conf << EOF
virtualhost phpmyadmin {
  vhRoot                  /usr/share/webapps/phpmyadmin
  configFile              \$SERVER_ROOT/conf/vhosts/\$VH_NAME/vhconf.conf
  allowSymbolLink         1
  enableScript            1
  restrained              1
  setUIDMode              0
}
listener phpmyadmin {
  address                 *:7081
  secure                  1
  keyFile                 \$SERVER_ROOT/admin/conf/webadmin.key
  certFile                \$SERVER_ROOT/admin/conf/webadmin.crt
  map                     phpmyadmin *
}
EOF
mkdir '/usr/local/lsws/conf/vhosts/phpmyadmin';
cat > /usr/local/lsws/conf/vhosts/phpmyadmin/vhconf.conf << EOF
docRoot                   \$VH_ROOT
enableGzip                1

index  {
  useServer               0
  indexFiles              index.php
  autoIndex               1
}

rewrite  {
  rules                   <<<END_rules
rewriteCond %{HTTPS} !on
rewriteCond %{HTTP:X-Forwarded-Proto} !https
rewriteRule ^(.*)$ https://%{SERVER_NAME}%{REQUEST_URI} [R,L]
  END_rules


}
EOF
chown -R nobody:nobody /usr/local/lsws/conf/vhosts/phpmyadmin;
fi;
sslcheckoff;
}

# ================================ Off ssl checking for ftp connection ==========================================
# ================== Отключение проверки сертификата ssl для ftp соединения с сервером бэкапов ==================
sslcheckoff() {
if [ ! -e "/root/.config/lftp/rc" ]; then 
	echo -e "set ssl:verify-certificate no" > /root/.config/lftp/rc
	chmod 0600 /root/.config/lftp/rc;
fi;	
newuser;
}

# ======================================= Adding new user ======================================================
# ================================ Добавление нового пользователя ==============================================
newuser() {
echo -e "\033[32;40m--------------------------------------------- 
EN   10. Create a user, owner of your sites. |
EN          One word in latin letters.       |
--------------------------------------------- 
--------------------------------------------- 
RU          10. Создайте пользователя,       |
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
read -p 'Continue 1 or Create 2: ' userselect;
if [ $userselect == 1 ]; then
newsite;
elif [ $userselect == 2 ]; then
newuser;
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
newsite;
else
echo -e "\033[31;40m--------------------------------------------- 
EN    Passwords don't match. Start again.    |
---------------------------------------------
---------------------------------------------
RU    Пароли не совпадают. Начните заново.   |
--------------------------------------------- \e[0m";	
newuser;
fi;
fi;
newsite;
}


# ================================= Create new site ========================================================
# ============================= Создание нового сайта ======================================================
newsite() {
echo -e "\033[32;40m--------------------------------------------- 
EN        11. Enter the name of the site     |
EN             you want to create.           |
EN            Example: mysite.com            |
---------------------------------------------
---------------------------------------------
RU           11. Введите имя сайта,          |
RU          который Вы хотите создать.       |
RU             Например: mysite.ru           |
--------------------------------------------- \e[0m";		
read -p 'Site name: ' sitename;
if [ -e /home/$username/$sitename ]; then 
echo -e "\033[32;40m--------------------------------------------- 
EN   \e[0m\033[31;40m       Site $sitename already exists!  \e[0m\033[32;40m
EN            Do you want to install        
EN         certificate Let's Encrypt? (1)
EN            or create a new site? (2)
---------------------------------------------
---------------------------------------------
RU     \e[0m\033[31;40m       Сайт $sitename уже есть! \e[0m\033[32;40m 
RU  Установить для $sitename сертификат Let's Encrypt (1) 
RU         или создать новый сайт? (2)       
--------------------------------------------- \e[0m";
read -p "Let's Encrypt 1 or newsite 2 or exit n :" siteselect;
if [ $siteselect == 1 ]; then
certinstall;
elif [ $siteselect == 2 ]; then
newsite;
else
echo "Goodby!";
exit;
fi;
else 
addsite;
fi;
}

# =============================== Certificate Let's Encrypt install =======================================
# ============================= Установка сертификата Let's Encrypt =======================================
certinstall() {
if [ $(dig $sitename +short) ] && [ $(wget -qO- eth0.me) == $(dig $sitename +short) ]; then
echo -e "\033[32;40m--------------------------------------------- 
EN             Enter your email              |
EN               for notices.                |
---------------------------------------------
---------------------------------------------
RU            Введите ваш email              | 
RU             для уведомлений.              |
--------------------------------------------- \e[0m";

else 
echo -e "\033[32;40m--------------------------------------------- 
EN         DNS $sitename not resolve
EN     check dns your domain registrator
---------------------------------------------
---------------------------------------------
RU       DNS для $sitename не найдены
RU           проверьте записи dns 
RU       у регистратора вашего домена
--------------------------------------------- \e[0m";
fi;
echo "Goodby!";
exit
}

# ================================ Create site directory and settings =========================================
# =============================  Создание дирректории и настроек сайта ========================================
addsite() {
cat >> /usr/local/lsws/conf/httpd_config.conf <<EOF
virtualhost $sitename {
vhRoot                  /home/$username/$sitename
configFile              \$SERVER_ROOT/conf/vhosts/\$VH_NAME/vhconf.conf
allowSymbolLink         1
enableScript            1
restrained              1
setUIDMode              2
}
EOF
mkdir /usr/local/lsws/conf/vhosts/$sitename;
cat > /usr/local/lsws/conf/vhosts/$sitename/vhconf.conf <<EOF
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

echo -e "\033[32;40m--------------------------------------------- 
EN       select InstansCMS version           |
EN      for install (2.14.2 default )        |       
EN     or n for not install InstantCMS       |
---------------------------------------------
---------------------------------------------
RU        Выберите версию InstantCMS         | 
RU    для установки (по умолчанию 2.14.2)    |
RU              или нажмите n,               |
RU     чтобы не устанавливать InstantCMS     |
--------------------------------------------- \e[0m";

read -p "Version InstansCMS [2.14.2]: " instantselect
instantselect=${instantselect:-2.14.2}
if [ "$instantselect" == "n" ]; then
makeblankfolder;
else
makerealsite;
fi;
}

# ========================== Create blank folder for site ========================================
# ======================== Создание пустой папки для сайта =======================================
makeblankfolder() {
chown -R nobody:nobody /usr/local/lsws/conf/vhosts/$sitename;
mkdir "/home/$username/$sitename";
chown -R "$username:$username /home/$username";
sed -i '/*:80$/ a \'"map                     $sitename $sitename"'' /usr/local/lsws/conf/httpd_config.conf;
addbase
}

# =========================== Create site with InstantCMS ========================================
# =========================== Создание сайта с InstantCMS ========================================
makerealsite() {
chown -R nobody:nobody /usr/local/lsws/conf/vhosts/$sitename;
sed -i '/*:80$/ a \'"map                     $sitename $sitename"'' /usr/local/lsws/conf/httpd_config.conf;
cd "/home/$username";
wget https://github.com/instantsoft/icms2/archive/refs/tags/$instantselect.zip;
unzip $instantselect.zip > /dev/null;
mv icms2-$instantselect $sitename;
rm $instantselect.zip;
chown -R $username:$username /home/$username/$sitename;
cd ~;
echo -e "\033[36;40m--------------------------------------------- 
EN Downloaded and extracted InstantCMS $instantselect
---------------------------------------------
---------------------------------------------
RU   Скачан и распакован InstantCMS $instantselect
--------------------------------------------- \e[0m";	
rc-service lsws restart
echo Site: "$sitename" > /root/."$username";
echo User: "$username" >> /root/."$username";
echo Password: $userpassword >> /root/.$username;
mkdir /home/$username/backups/$sitename;
chown $username:$username /home/$username/backups/$sitename;
addbase;
}

# =============================== Creating mysql user and database for this site ==========================
# ============================= Создание пользователя mysql и базы данных для сайта =======================
addbase() {
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
ftpsettings;
}

# ======================================= Installing Let's Encrypt certificate =======================================
# ======================================= Установка сертификата Let's Encrypt ======================================== 
newcert() {
read -p 'Yes y or No n: ' certselect;
if [[ $certselect != y* ]] && [[ $certselect != Y* ]]; then 
echo ""
else 
echo -e "\033[32;40m--------------------------------------------- 
EN             Enter your email              |
EN               for notices.                |
---------------------------------------------
---------------------------------------------
RU            Введите ваш email              | 
RU             для уведомлений.              |
--------------------------------------------- \e[0m";
read -p 'Enter your email: ' mail;
apk add certbot;
service lsws stop;
certbot certonly --standalone --preferred-challenges http -d $sitename -m $mail;
service lsws start;
fi;
}

# ================================ Add settings for ftp connection ==================================================
# ====================== Добавление настроек соединения с ftp сервером для бэкапов ==================================
ftpsettings() {
if [ ! -e "/root/.netrc" ]; then
echo -e "\033[32;40m--------------------------------------------- 
EN    12. Have you ftp backup server?        |
---------------------------------------------
---------------------------------------------
RU 12.У Вас уже есть ftp сервер для бэкапов? |
--------------------------------------------- \e[0m";
read -p 'Yes y or No n: ' ftpselect;
if [[ $ftpselect != y* ]]; then 
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
EN    (You should already have ftp server.)  |
---------------------------------------------
---------------------------------------------
RU        Введите адрес ftp сервера          |
RU        для резервного копирования.        |
RU       (Вы должны иметь уже готовый        |
RU         ftp сервер для бэкапов.)          |
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
resume;
}


# ================  Adding buttons to Openliteserver admin panel and show resume ======================================
# ================  Добавление кнопок в админпанель openliteserver и вывод резюме =====================================
resume() {
butt=",'pma' => array(\n \
'title' => 'Phpmyadmin',\n \
'url' => 'https://$sitename:7081',\n \
'url_target' => '_blank',\n \
'icon' => 'fa-database'),\n \
'acf' => array(\n \
'title' => 'ACF',\n \
'url_target' => '_blank',\n \
'url' => 'https://$sitename:7082',\n \
'icon' => 'fa-cogs')";

sed -i '105a '"$butt"'' /usr/local/lsws/admin/html.open/view/inc/configui.php;

echo -e "\033[32;40m--------------------------------------------- 
EN   Openlitespeed, php, mysql, phpmyadmin,        
EN   rainloop, Alpine Configuration Framework (ACF) 
EN   and InstantCMS is installed!         
EN   Your site          \033[36;40m http://$sitename\033[32;40m
EN   Database name:     \033[36;40m $base\033[32;40m
EN   Database user:     \033[36;40m $username\033[32;40m
EN   Database password: \033[36;40m $userpassword\033[32;40m
EN   Backups folder:    \033[36;40m /home/${username}/backups/$sitename\033[32;40m
EN   ftp user           \033[36;40m $username\033[32;40m
En   ftp password       \033[36;40m $userpassword\033[32;40m
EN   OLS webadminpanel  \033[36;40m https://$sitename:7080\033[32;40m
EN   Phpmyadmin address \033[36;40m https://$sitename:7081\033[32;40m
EN   ACF                \033[36;40m https://$sitename:7082\033[32;40m
---------------------------------------------
---------------------------------------------
RU   Openlitespeed, php, mysql, phpmyadmin,        
RU   rainloop, Alpine Configuration Framework (ACF) 
RU   и InstantCMS установлены!        
RU   Ваш сайт           \033[36;40m http://$sitename\033[32;40m
RU   Имя базы данных:   \033[36;40m $base\033[32;40m
RU   Пользователь базы: \033[36;40m $username\033[32;40m
RU   Пароль базы:       \033[36;40m $userpassword\033[32;40m
RU   Папка бэкапов:     \033[36;40m /home/${username}/backups/$sitename\033[32;40m
RU   Пользователь ftp   \033[36;40m $username\033[32;40m
RU   Пароль ftp         \033[36;40m $userpassword\033[32;40m
RU   OLS webadminpanel  \033[36;40m https://$sitename:7080\033[32;40m
RU   Адрес phpmyadmin   \033[36;40m https://$sitename:7081\033[32;40m
RU   ACF                \033[36;40m https://$sitename:7082\033[32;40m
---------------------------------------------\e[0m";
exit;
}

rmuser() {
deluser --remove-home $2>>/dev/null;
}

if [ -n "$1" ]
then
if [ $1 == 'newsite' ]
then
newuser
fi;
$1
else
main
fi;


