#!/bin/ash

# set -euxo pipefail
set -e

main() {
	if [ ! -e "/etc/init.d/litespeed" ]; then
		intro;
		repo;
		upgrade;
		openlite;
		acf;
		appsinstall;
		ftpinstall;
	fi;
	if [ ! -e "/usr/bin/mariadbd" ]; then
		sqlinstall;
		mysql_secure;
		dbdumpset;
	fi;
	if [ ! -e "/usr/share/webapps/adminer" ]; then
		adminer;
	fi;
	newuser;
}

intro() {
	# ================================== Introduction ================================================
	# =================================== Вступление ================================================= 
	echo -e "\033[35m--------------------------------------------- 
	\rEN              Installing webserver         |
	\rEN               with openlitespeed.         |
	\r---------------------------------------------	
	\r---------------------------------------------
	\rRU              Установка вебсервера         |
	\rRU                 с openlitespeed.          |
	\r--------------------------------------------- \e[0m";
	echo ' ';
}

repo() {
	# ================================ Adding repositories ===========================================
	# ============================== Добавление репозиториев =========================================
	sed -i 's/#http/http/g' /etc/apk/repositories;
	
	echo -e "\033[35m---------------------------------------------
	\rEN        1. Update apk repositories         |
	\r---------------------------------------------
	\r---------------------------------------------
	\rRU        1. Обновление репозиториев         |
	\r--------------------------------------------- \e[0m";
	apk update;
}

upgrade() {
	echo -e "\033[35m--------------------------------------------- 
	\rEN            2. Upgrade system              |
	\r---------------------------------------------
	\r---------------------------------------------
	\rRU            2. Апгрейд системы             |
	\r--------------------------------------------- \e[0m";
	apk upgrade;
}

openlite() {
	echo -e "\033[35m--------------------------------------------- 
	\rEN           3. Install openlitespeed        |
	\r--------------------------------------------- 
	\r---------------------------------------------
	\rRU          3. Установка openlitespeed       |
	\r--------------------------------------------- \e[0m";
		
	apk add litespeed
	apk add libidn;
	
	if [ ! -e "/var/lib/litespeed/admin/conf/webadmin.crt" ]; then
	#generate key for webadmin
    COMMNAME=$(hostname -s); echo $COMMNAME
    SSL_COUNTRY=CC
    csr="webadmin.csr"
    key="webadmin.key"
    cert="webadmin.crt"
	
	MYIP=$(ip addr show eth0 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)
    openssl req -subj "/CN=${COMMNAME}/O=webadmin/C=${SSL_COUNTRY}/extendedKeyUsage=1.3.6.1.5.5.7.3.1/subjectAltName=DNS.1=${MYIP}/" -new -newkey rsa:2048 -sha256 -days 1460 -nodes -x509 -keyout /etc/litespeed/admin/${key} -out /etc/litespeed/admin/${cert}
	webadmin_password;
	fi

	rm /var/lib/litespeed/admin/misc/php.ini;
	rc-service litespeed restart
	rc-update add litespeed
}

webadmin_password(){
	echo -e "\033[32m--------------------------------------------- 
	\rEN     Enter OLS admin name and password.    |
	\r---------------------------------------------
	\r---------------------------------------------
	\rRU     Введите имя и пароль для OLS admin.   |
	\r--------------------------------------------- \e[0m";	
	/var/lib/litespeed/admin/misc/admpass.sh;
	rc-service litespeed restart;
}

# ========================= Install Alpine Configuration Framawork ====================================================
# ========================= Установка Alpine Configuration Framawork ==================================================
acf() {
	if [ ! -e '/etc/acf/' ]; then
		echo -e "\033[35m--------------------------------------------- 
		\rEN 4.Install Alpine Configuration Framework  |
		\r---------------------------------------------
		\r---------------------------------------------
		\rRU 4.Установка Alpine Configuration Framework|
		\r--------------------------------------------- \e[0m";	
		setup-acf;
		sed -i 's/443/7082/g' /etc/mini_httpd/mini_httpd.conf;
		/etc/init.d/mini_httpd restart;
	fi;
}

#======================== Install required php extensions and memcached ===============================================
#========================Установка необходимых расширений php и memcached =============================================
appsinstall() {            
	if [ ! -e '/etc/init.d/memcached' ]; then
		echo -e "\033[35m--------------------------------------------- 
		\rEN     5. Install required php extensions    |
		\rEN               and memcached               |
		\r---------------------------------------------
		\r---------------------------------------------
		\rRU  5. Установка необходимых расширений php  |
		\rRU                и memcached                |
		\r--------------------------------------------- \e[0m";	
		
		apk add memcached bind-tools openssh libidn mc fail2ban libstdc++;
		rc-service memcached start;
		rc-update add memcached;
		# pkill lsphp;
		rc-service  fail2ban start;
		rc-update add fail2ban;
	fi;
}

# ======================= Install proftpd =============================================================================
# ======================= Установка proftpd ===========================================================================
ftpinstall() {
	if [ ! -e '/etc/proftpd' ]; then
		mkdir -p .config;
		mkdir -p .config/lftp;
		echo -e "\033[35m--------------------------------------------- 
		\rEN            6. Install proftpd             |
		\r---------------------------------------------
		\r---------------------------------------------
		\rRU           6. Установка proftpd            |
		\r--------------------------------------------- \e[0m";		
		apk add proftpd;
		rc-service proftpd start;
		rc-update add proftpd;
		sed -i 's/#DefaultRoot ~/DefaultRoot     ~ !adm/g'  /etc/proftpd/proftpd.conf;
		sed -i '/command/ a \*/5	*	*	*	*	run-parts /etc/periodic/5min' /etc/crontabs/root;
	fi;
}

# ============================ Install mariadb =======================================================================
# ============================ Установка mariadb =====================================================================
sqlinstall() {
	if [ ! -e "/usr/bin/mariadbd" ]; then
		echo -e "\033[35m--------------------------------------------- 
		\rEN         7. Install mariadb                |
		\r---------------------------------------------
		\r---------------------------------------------
		\rRU        7. Установка mariadb               |
		\r--------------------------------------------- \e[0m";	
		apk add mariadb mariadb-client;
		rc-update add mariadb;
		/etc/init.d/mariadb setup;
		rc-service mariadb start;
	fi;
}	
# =========================== mysql secure settings ==================================================================
# ======================= Настройки безопасности mariadb =============================================================
mysql_secure(){
	echo -e "\033[32m--------------------------------------------- 
	\rEN       Enter new root password mysql.      |
	\r---------------------------------------------
	\r---------------------------------------------
	\rRU    Введите новый пароль root для mysql.   |
	\r--------------------------------------------- \e[0m";		
	read -sp 'Root password: ' rpass;
	echo ' ';
	read -sp 'Retype password: ' rpass1;
	if [ $rpass == $rpass1 ]; then
		echo -e "\ny\ny\n$rpass\n$rpass\ny\ny\ny\ny" | mysql_secure_installation;
		else
		echo -e "\033[31m--------------------------------------------- 
		\rEN      Passwords don't match. Start again.  |
		\r---------------------------------------------
		\r---------------------------------------------
		\rRU     Пароли не совпадают. Начните заново.  |
		\r--------------------------------------------- \e[0m";			
		mysql_secure;
	fi;
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
}

# ============================ Install adminer ======================================================================
# ============================ Установка adminer ====================================================================
adminer() {
	if [ ! -e "/usr/share/webapps/adminer" ]; then
		echo -e "\033[35m--------------------------------------------- 
		\rEN       8. Install adminer               |
		\r---------------------------------------------
		\r---------------------------------------------
		\rRU      8. Установка adminer              |
		\r--------------------------------------------- \e[0m";	
		# apk add phpmyadmin;
		mkdir -p /usr/share/webapps
		mkdir -p /usr/share/webapps/adminer
		wget https://github.com/vrana/adminer/releases/download/v4.8.1/adminer-4.8.1.php -O /usr/share/webapps/adminer/index.php
		wget https://raw.githubusercontent.com/pappu687/adminer-theme/master/adminer.css -O /usr/share/webapps/adminer/adminer.css
		cat >> /var/lib/litespeed/conf/httpd_config.conf << EOF
virtualhost adminer {
			vhRoot                  /usr/share/webapps/adminer
			configFile              \$SERVER_ROOT/conf/vhosts/\$VH_NAME/vhconf.conf
			allowSymbolLink         1
			enableScript            1
			restrained              1
			setUIDMode              0
			}
			listener adminer {
			address                 *:7081
			secure                  1
			keyFile                 \$SERVER_ROOT/admin/conf/webadmin.key
			certFile                \$SERVER_ROOT/admin/conf/webadmin.crt
			map                     adminer *
			}
			listener HTTP {
			address                 *:80
			secure                  0
			}
			listener HTTPS {
			address                 *:443
			secure                  1
			}
EOF
		mkdir -p '/var/lib/litespeed/conf/vhosts/adminer';
		cat > /var/lib/litespeed/conf/vhosts/adminer/vhconf.conf << EOF
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
	chown -R litespeed:litespeed /var/lib/litespeed/conf/vhosts/adminer;
	fi;
	rc-service litespeed restart;
}


# ======================================= Adding new user ======================================================
# ================================ Добавление нового пользователя ==============================================
newuser() {
	echo -e "\033[32m--------------------------------------------- 
	\rEN   10. Create a user, owner of your sites. |
	\rEN          One word in latin letters.       |
	\r--------------------------------------------- 
	\r--------------------------------------------- 
	\rRU          10. Создайте пользователя,       |
	\rRU            владельца ваших сайтов.        |
	\rRU        Одно слово латинскими буквами.     |
	\r--------------------------------------------- \e[0m";		
	read -p 'User name: ' username;
	if [ -e /home/$username ]; then
		echo -e "\033[32m-------------------------------------------- 
		\rEN   \e[0m\033[31m          User already exists!    \e[0m\033[32m      |
		\rEN       Do you want to create a new user    |
		\rEN           or continue with this?          |
		\rEN        Continue with this: enter 1,       |
		\rEN            Create new: enter 2            |
		\r---------------------------------------------
		\r---------------------------------------------
		\rRU \e[0m\033[31m        Такой пользователь уже есть! \e[0m\033[32m     |
		\rRU      Хотите создать нового пользователя   |
		\rRU            или продолжить с этим?         |
		\rRU        Продолжить с этим: введите 1,      |
		\rRU          Создать нового: введите 2        |
		\r--------------------------------------------- \e[0m";		
		read -p 'Continue 1 or Create 2: ' userselect;
		if [ $userselect == 1 ]; then
			newsite;
			elif [ $userselect == 2 ]; then
			newuser;
		fi;
		else
		echo -e "\033[32m--------------------------------------------- 
		\rEN             Enter user password.          |
		\r---------------------------------------------
		\r---------------------------------------------
		\rRU        Введите пароль пользователя.       |
		\r--------------------------------------------- \e[0m";	
		read -p 'User password:   ' userpassword;
		read -p 'Retype password: ' userpassword1;
		if [ $userpassword == $userpassword1 ]; then
			adduser -D --shell /bin/ash $username
			echo $username:$userpassword | chpasswd $username:$userpassword > /dev/null;
			mkdir /home/$username/backups;
			mkdir /home/$username/www;
			chown -R $username:$username /home/$username;
			newsite;
			else
			echo -e "\033[31m--------------------------------------------- 
			\rEN    Passwords don't match. Start again.    |
			\r---------------------------------------------
			\r---------------------------------------------
			\rRU    Пароли не совпадают. Начните заново.   |
			\r--------------------------------------------- \e[0m";	
			newuser;
		fi;
		newsite;
	fi;
}


# ================================= Create new site ========================================================
# ============================= Создание нового сайта ======================================================
newsite() {
	echo -e "\033[32m--------------------------------------------- 
	\rEN        11. Enter the name of the site     |
	\rEN             you want to create.           |
	\rEN            Example: mysite.com            |
	\r---------------------------------------------
	\r---------------------------------------------
	\rRU           11. Введите имя сайта,          |
	\rRU          который Вы хотите создать.       |
	\rRU             Например: mysite.ru           |
	\r--------------------------------------------- \e[0m";		
	read -p 'Site name: ' sitename;
	sitename=$(echo "$sitename" | idn);
	if [ -e /home/$username/www/$sitename ]; then 
		echo -e "\033[32m--------------------------------------------- 
		\rEN   \e[0m\033[31m       Site $sitename already exists!  \e[0m\033[32m
		\rEN            Do you want to install        
		\rEN         certificate Let's Encrypt? (1)
		\rEN            or create a new site? (2)
		\r---------------------------------------------
		\r---------------------------------------------
		\rRU     \e[0m\033[31m       Сайт $sitename уже есть! \e[0m\033[32m 
		\rRU  Установить для $sitename сертификат Let's Encrypt (1) 
		\rRU         или создать новый сайт? (2)       
		\r--------------------------------------------- \e[0m";
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
		echo -e "\033[32m--------------------------------------------- 
		\rEN   \e[0m\033[31m         Select php version\e[0m\033[32m
		\rEN            Variants: 7 8 81 82        
		\r---------------------------------------------
		\r---------------------------------------------
		\rRU     \e[0m\033[31m       Выберите версию php \e[0m\033[32m 
		\rRU            Варианты: 7 8 81 82       
		\r--------------------------------------------- \e[0m";
		read -p "Select php version :" phpver;
		if [ ! -e /usr/bin/lsphp$phpver ]; then
		apk add php$phpver-litespeed php$phpver-xml php$phpver-fileinfo php$phpver-ftp php$phpver-curl php$phpver-intl php$phpver-bcmath php$phpver-gd;
		apk add php$phpver-mbstring php$phpver-session php$phpver-json php$phpver-iconv php$phpver-zip php$phpver-opcache;
		apk add php$phpver-sockets php$phpver-posix php$phpver-mysqli php$phpver-openssl php$phpver-simplexml php$phpver-zip;
		apk add php$phpver-pecl-memcached  php$phpver-pecl-memcache;
		addbuttons;
		fi
		addsite;
	fi;
}

# =============================== Certificate Let's Encrypt install =======================================
# ============================= Установка сертификата Let's Encrypt =======================================
certinstall() {
	if [ $(dig $sitename +short) ] && [ $(wget -qO- eth0.me) == $(dig $sitename +short) ]; then
		newcert;
		else 
		echo -e "\033[32m--------------------------------------------- 
		\rEN         DNS $sitename not resolve
		\rEN     check dns your domain registrator
		\r---------------------------------------------
		\r---------------------------------------------
		\rRU       DNS для $sitename не найдены
		\rRU           проверьте записи dns 
		\rRU       у регистратора вашего домена
		\r--------------------------------------------- \e[0m";
	fi;
	exit
}

# ================================ Create site directory and settings =========================================
# =============================  Создание дирректории и настроек сайта ========================================
addsite() {
	cat >> /var/lib/litespeed/conf/httpd_config.conf <<EOF
virtualhost $sitename {
		vhRoot                  /home/$username/www/$sitename
		configFile              \$SERVER_ROOT/conf/vhosts/\$VH_NAME/vhconf.conf
		allowSymbolLink         1
		enableScript            1
		restrained              1
		setUIDMode              2
		}
EOF
	mkdir -p /var/lib/litespeed/conf/vhosts/$sitename;
	cat > /var/lib/litespeed/conf/vhosts/$sitename/vhconf.conf <<EOF
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

		scripthandler  {
		add                     lsapi:lsphp$phpver php
		}

		extprocessor lsphp$phpver {
		type                    lsapi
		address                 UDS://tmp/lshttpd/lsphp$phpver.sock
		maxConns                35
		initTimeout             60
		retryTimeout            0
		respBuffer              0
		autoStart               2
		path                    /usr/bin/lsphp$phpver
		}
EOF
	
	echo -e "\033[32m--------------------------------------------- 
	\rEN       select InstansCMS version           |
	\rEN      for install (2.15.2 default )        |       
	\rEN     or n for not install InstantCMS       |
	\r---------------------------------------------
	\r---------------------------------------------
	\rRU        Выберите версию InstantCMS         | 
	\rRU    для установки (по умолчанию 2.15.2)    |
	\rRU              или нажмите n,               |
	\rRU     чтобы не устанавливать InstantCMS     |
	\r--------------------------------------------- \e[0m";
	
	read -p "Version InstansCMS [2.15.2]: " instantselect
	instantselect=${instantselect:-2.15.2}
	if [ "$instantselect" == "n" ]; then
		makeblanksite;
		else
		makerealsite;
	fi;
	phpinstall;
	rc-service litespeed restart
}

# ========================== Create blank folder for site ========================================
# ======================== Создание пустой папки для сайта =======================================
makeblanksite() {
	chown -R litespeed:litespeed /var/lib/litespeed/conf/vhosts/$sitename;
	mkdir "/home/$username/www/$sitename";
	chown -R $username:$username /home/$username/www/$sitename;
	sed -i '/*:80$/ a \'"map                     $sitename $sitename"'' /var/lib/litespeed/conf/httpd_config.conf;
	addbase
}

# =========================== Create site with InstantCMS ========================================
# =========================== Создание сайта с InstantCMS ========================================
makerealsite() {
	chown -R litespeed:litespeed /var/lib/litespeed/conf/vhosts/$sitename;
	sed -i '/*:80$/ a \'"map                     $sitename $sitename"'' /var/lib/litespeed/conf/httpd_config.conf;
	cd "/home/$username/www";
	wget https://github.com/instantsoft/icms2/archive/refs/tags/$instantselect.zip;
	unzip $instantselect.zip > /dev/null;
	mv icms2-$instantselect $sitename;
	rm $instantselect.zip;
	chown -R $username:$username /home/$username/www/$sitename;
	cd ~;
	echo -e "\033[35m--------------------------------------------- 
	\rEN Downloaded and extracted InstantCMS $instantselect
	\r---------------------------------------------
	\r---------------------------------------------
	\rRU   Скачан и распакован InstantCMS $instantselect
	\r--------------------------------------------- \e[0m";	
	rc-service litespeed restart
	if [ ! -e ".$username" ]; then
	touch ".$username";
	fi
	echo Site: "$sitename" >> .$username;
	echo User: "$username" >> .$username;
	echo Password: "$userpassword" >> .$username;
	mkdir /home/$username/backups/$sitename;
	chown $username:$username /home/$username/backups/$sitename;
	addbase;
}

# =============================== Creating mysql user and database for this site ==========================
# ============================= Создание пользователя mysql и базы данных для сайта =======================
addbase() {
	if echo "SELECT COUNT(*) FROM mysql.user WHERE user = '$username';" | mariadb | grep 1 &> /dev/null ; then
		echo "Mysqluser $username exsists"
		else 
		mariadb -e "CREATE USER ${username}@'%' IDENTIFIED BY '${userpassword}';"
		echo "Mysqluser $username created "
	fi;
	base=$(echo "$sitename" | sed 's/\./_/g' );
	base=$(echo "$base" | sed 's/xn--//g' );
	if echo "SHOW DATABASES" | mariadb | grep ${base} &> /dev/null ; then
		echo "Database $base exists"
		else
		mariadb -e "CREATE DATABASE ${base} /*\!40100 DEFAULT CHARACTER SET utf8 */;"	
		mariadb -e "GRANT ALL PRIVILEGES ON ${base}.* TO '${username}'@'%';"
		mariadb -e "FLUSH PRIVILEGES;";
		echo -e "\033[35m--------------------------------------------- 
		\rEN            Site $sitename was created.
		\rEN            Database ${base} was created.                  
		\r---------------------------------------------
		\r---------------------------------------------
		\rRU            Сайт $sitename создан.
		\rRU            База данных ${base} создана.                 
		\r--------------------------------------------- \e[0m";	
		touch .$username
		echo Database: $base >> .$username;
	fi;
	backupsettings;
}

# ======================================= Installing Let's Encrypt certificate =======================================
# ======================================= Установка сертификата Let's Encrypt ======================================== 
newcert() {
	if [ $(dig $sitename +short) ] && [ $(wget -qO- eth0.me) == $(dig $sitename +short) ]; then
		echo -e "\033[32m--------------------------------------------- 
		\rEN             Enter your email              |
		\rEN               for notices.                |
		\r---------------------------------------------
		\r---------------------------------------------
		\rRU            Введите ваш email              | 
		\rRU             для уведомлений.              |
		\r--------------------------------------------- \e[0m";
		read -p 'Enter your email: ' mail;
		apk add certbot;
		apk add py3-pip;
		python3 -m pip install certifi
		rc-service litespeed stop;
		certbot certonly --standalone --preferred-challenges http -d $sitename -m $mail;
		rc-service litespeed start;
		sed -i '/*:443/a  \'"  map                     $sitename $sitename"'' /var/lib/litespeed/conf/httpd_config.conf;
		cat > /var/lib/litespeed/conf/vhosts/$sitename/vhconf.conf << EOF
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
			rules                   <<<END_rules
			rewriteCond %{HTTPS} !on
			rewriteCond %{HTTP:X-Forwarded-Proto} !https
			rewriteRule ^(.*)$ https://%{SERVER_NAME}%{REQUEST_URI} [R,L]
		END_rules
		
		}
		
		vhssl  {
		keyFile                 /etc/letsencrypt/live/$sitename/privkey.pem
		certFile                /etc/letsencrypt/live/$sitename/fullchain.pem
		}
EOF
	else
	echo -e "\033[32m--------------------------------------------- 
	\rEN         DNS $sitename not resolve
	\rEN     check dns your domain registrator
	\r---------------------------------------------
	\r---------------------------------------------
	\rRU       DNS для $sitename не найдены
	\rRU           проверьте записи dns 
	\rRU       у регистратора вашего домена
	\r--------------------------------------------- \e[0m";
	fi;
	exit
}

# ================================ Add settings for ftp connection ==================================================
# ====================== Добавление настроек соединения с ftp сервером для бэкапов ==================================
backupsettings() {
	echo -e "\033[32m--------------------------------------------- 
		\rEN    12. Where will you store your backups?       |
		\rEN    FTP server? 1 Yandex disk? 2 Locally? 3      |
		\r---------------------------------------------
		\r---------------------------------------------
		\rRU 12.Где Вы будете хранить ваши резерввные копии? |
		\rRU    Ftp сервер? 1 Яндекс-диск? 2 Локально? 3     |
		\r--------------------------------------------- \e[0m";
		read -p 'FTP server? 1 Yandex disk? 2 Locally? 3: ' ftpselect;
		if [[ $ftpselect == 1 ]]; then 
			backupftp;
			elif [[ $ftpselect == 2 ]]; then
			backupyandex;
			else 
			backuplocal;
		fi;
	addbuttons;	
	resume;
}

backuplocal() {
	echo -e "\033[33m--------------------------------------------- 
	\rEN  Then your backups will saving in 
	\rEN  /home/${username}/backups/$sitename.   
	\r---------------------------------------------
	\r---------------------------------------------
	\rRU  Тогда ваши бэкапы будут сохраняться в 
	\rRU  /home/${username}/backups/$sitename. 
	\r--------------------------------------------- \e[0m";	
	if [ ! -e "/etc/periodic/5min" ]; then
		mkdir /etc/periodic/5min;
	fi;
	echo "#!/bin/sh" > /etc/periodic/5min/$base;
	echo "/usr/bin/php /home/$username/www/$sitename/cron.php $sitename > /dev/null" >> /etc/periodic/5min/$base;
	chmod 0755 /etc/periodic/5min/$base;
	
	cat > /etc/periodic/daily/$base'_backups' <<EOF
#!/bin/sh
		tar -czvf /home/$username/backups/$sitename/$sitename-\$(date '+%d%m%y_%H:%M').tar.gz /home/$username/www/$sitename
		
		mysqldump $base | gzip > /home/$username/backups/$sitename/$base-\$(date '+%d%m%y_%H:%M').sql.gz
		
		find /home/$username/backups/$sitename -type f -mmin +16 -exec rm -rf {} \;
EOF
	chmod 0755 /etc/periodic/daily/$base'_backups';
	resume;
}


backupyandex() {
	echo -e "\033[32m--------------------------------------------- 
	\rEN           Enter your yandex login.        |
	\r---------------------------------------------
	\r---------------------------------------------
	\rRU        Введите ваш логин на яндексе       |
	\r--------------------------------------------- \e[0m";
	read -p 'ya_login: ' ya_login;
	echo -e "\033[32m--------------------------------------------- 
	\rEN         Enter your yandex password.       |
	\r---------------------------------------------
	\r---------------------------------------------
	\rRU       Введите ваш пароль на яндексе       |
	\r--------------------------------------------- \e[0m";
	read -p 'ya_pass: ' ya_pass;
	apk add davfs2;
	mkdir  -p /media/yadisk;
	echo "/media/yadisk $ya_login $ya_pass" >> /etc/davfs2/secrets;
	if [ ! -e "/etc/periodic/5min" ]; then
		mkdir /etc/periodic/5min;
	fi;
	echo "#!/bin/sh" > /etc/periodic/5min/$base;
	echo "/usr/bin/php /home/$username/www/$sitename/cron.php $sitename > /dev/null" >> /etc/periodic/5min/$base;
	chmod 0755 /etc/periodic/5min/$base;
	
	cat > /etc/periodic/daily/$base'_backups' <<EOF
#!/bin/sh
		mount /media/yadisk;
		cd /media/yadisk;
		if [ ! -e "$base"_backups ]; then
		mkdir "$base"_backups;
		fi;
		
		tar -czvf /home/$username/backups/$sitename/$sitename-$(date '+%d%m%y_%H:%M').tar.gz /home/$username/www/$sitename
		
		mysqldump alp_tes | gzip > /home/$username/backups/$sitename/$base-$(date '+%d%m%y_%H:%M').sql.gz
		
		mv /home/$username/backups/$sitename/* /media/yadisk/$base_backups
		
	find /media/yadisk/"$base"_backups -type f -mmin +10 -exec rm -rf {} \;
	
	cd ~;
	
	umount /media/yadisk;
EOF
chmod 0755 /etc/periodic/daily/$base'_backups';
resume;
}

backupftp() {
	if [ ! -e "/root/.netrc" ]; then
	echo -e "\033[32m--------------------------------------------- 
	\rEN      Enter ftp backup server address.     |
	\rEN    (You should already have ftp server.)  |
	\r---------------------------------------------
	\r---------------------------------------------
	\rRU        Введите адрес ftp сервера          |
	\rRU        для резервного копирования.        |
	\rRU       (Вы должны иметь уже готовый        |
	\rRU         ftp сервер для бэкапов.)          |
	\r--------------------------------------------- \e[0m";
	read -p 'ftp server: ' ftp_server;
	echo -e "\033[32m--------------------------------------------- 
	\rEN      Enter ftp backup server user name.   |
	\r---------------------------------------------
	\r---------------------------------------------
	\rRU         Введите имя пользователя          |
	\rRU   ftp сервера для резервного копирования. |
	\r--------------------------------------------- \e[0m";
	read -p 'ftp user: ' ftp_user;
	echo -e "\033[32m--------------------------------------------- 
	\rEN   Enter ftp backup server user password.  |
	\r---------------------------------------------
	\r---------------------------------------------
	\rRU       Введите пароль пользователя         |
	\rRU  ftp сервера для резервного копирования.  |
	\r--------------------------------------------- \e[0m";
	read -p 'ftp password: ' ftp_password;
	echo -e machine $ftp_server > /root/.netrc;
	echo -e login $ftp_user >> /root/.netrc;
	echo -e password $ftp_password >> /root/.netrc;
	chmod 0600 /root/.netrc;
	fi;
	if [ ! -e "/etc/periodic/5min" ]; then
		mkdir /etc/periodic/5min;
	fi;
	echo "#!/bin/sh" > /etc/periodic/5min/$base;
	echo "/usr/bin/php /home/$username/www/$sitename/cron.php $sitename > /dev/null" >> /etc/periodic/5min/$base;
	chmod 0755 /etc/periodic/5min/$base;
	apk add curlftpfs;
	mkdir /media/ftp;
	tz=$(date +"%z");
	tz=${tz//0/};
	shift=$(( $tz * 60 ));
	deltime=$((1440 - $shift));
	cat > /etc/periodic/daily/$base'_backups' <<EOF
#!/bin/sh
modprobe fuse;
curlftpfs ftp://${ftp_server} /media/ftp;
cd /media/ftp;
if [ ! -e ${base}_backups ]; then
	mkdir ${base}_backups;
fi;
		
tar -czvf /media/ftp/${base}_backups/$sitename-\$(date '+%d%m%y_%H:%M').tar.gz /home/$username/www/$sitename
		
mysqldump $base | gzip > /media/ftp/${base}_backups/${base}-\$(date '+%d%m%y_%H:%M').sql.gz
		
find /media/ftp/${base}_backups -type f -mmin +${deltime} -exec rm -rf {} \;
	
cd ~;
	
umount /media/ftp;
EOF
	chmod 0755 /etc/periodic/daily/$base'_backups';
	moddir=$(echo /lib/modules/`uname -r`);
	insmod $moddir/kernel/fs/fuse/fuse.ko;
	insmod $moddir/kernel/fs/fuse/virtiofs.ko;
	resume;
}

# ================  Adding buttons to Openliteserver admin panel and show resume ======================================
# ================  Добавление кнопок в админпанель openliteserver и вывод резюме =====================================
addbuttons() {
	rc-service litespeed restart;
	butt=",'pma' => array(\n \
	'title' => 'Adminer',\n \
	'url' => 'https://$sitename:7081',\n \
	'url_target' => '_blank',\n \
	'icon' => 'fa-database'),\n \
	'acf' => array(\n \
	'title' => 'ACF',\n \
	'url_target' => '_blank',\n \
	'url' => 'https://$sitename:7082',\n \
	'icon' => 'fa-cogs')";
	
	if grep 'Adminer' /var/lib/litespeed/admin/html.open/view/inc/configui.php > /dev/null; then
		continue;
		else 
		sed -i '105a '"$butt"'' /var/lib/litespeed/admin/html.open/view/inc/configui.php;
	fi;
}

resume() {	
	
	touch .lastuser
	echo "username=$username" > .lastuser
	echo "sitename=$sitename" >> .lastuser
	echo "userpassword=$userpassword" >> .lastuser
	echo "base=$base" >> .lastuser
	if [ $ftpselect == 2 ]; then
	echo "ya_login=$ya_login;" >> .lastuser;
	echo "ya_pass=$ya_pass;" >> .lastuser;
	fi
	if [ $ftpselect == 1 ]; then
	echo "ftp_server=$ftp_server;" >> .lastuser;
	echo "ftp_user=$ftp_user;" >> .lastuser;
	echo "ftp_password=$ftp_password;" >> .lastuser;
	fi
	rc-service litespeed restart;
	echo -e "\033[32m--------------------------------------------- 
	\rEN   Openlitespeed, php, mysql, adminer,        
	\rEN   rainloop, Alpine Configuration Framework (ACF) 
	\rEN   and InstantCMS is installed!         
	\rEN   Your site          \033[35m http://$sitename\033[32m
	\rEN   Database name:     \033[35m $base\033[32m
	\rEN   Database user:     \033[35m $username\033[32m
	\rEN   Database password: \033[35m $userpassword\033[32m
	\rEN   Backups folder:    \033[35m /home/${username}/backups/$sitename\033[32m
	\rEN   ftp user           \033[35m $username\033[32m
	\rEN   ftp password       \033[35m $userpassword\033[32m
	\rEN   OLS webadminpanel  \033[35m https://$sitename:7080\033[32m
	\rEN   Adminer address \033[35m https://$sitename:7081\033[32m
	\rEN   ACF                \033[35m https://$sitename:7082\033[32m
	\r---------------------------------------------
	\r---------------------------------------------
	\rRU   Openlitespeed, php, mysql, adminer,        
	\rRU   rainloop, Alpine Configuration Framework (ACF) 
	\rRU   и InstantCMS установлены!        
	\rRU   Ваш сайт           \033[35m http://$sitename\033[32m
	\rRU   Имя базы данных:   \033[35m $base\033[32m
	\rRU   Пользователь базы: \033[35m $username\033[32m
	\rRU   Пароль базы:       \033[35m $userpassword\033[32m
	\rRU   Папка бэкапов:     \033[35m /home/${username}/backups/$sitename\033[32m
	\rRU   Пользователь ftp   \033[35m $username\033[32m
	\rRU   Пароль ftp         \033[35m $userpassword\033[32m
	\rRU   OLS webadminpanel  \033[35m https://$sitename:7080\033[32m
	\rRU   Адрес adminer   \033[35m https://$sitename:7081\033[32m
	\rRU   ACF                \033[35m https://$sitename:7082\033[32m
	\r---------------------------------------------\e[0m";
	exit;
}

#================== Remove user with his folders and databases (ondemand rmuser [username]) ====================
#================== Удаление пользователя с его папками и базами данных (по запросу rmuser [username]) =========
rmuser() {
	if id "$udel" >/dev/null 2>&1; then
	configs=$(ls /home/$username/www)
	for sitedel in $configs; do
	rm -rf /etc/litespeed/vhosts/$sitedel
	
	sed -i "/virtualhost $sitedel {/,/}/d" /etc/litespeed/httpd_config.conf
	sed -i -r "s/map\s*$sitedel\s*$sitedel//g" /etc/litespeed/httpd_config.conf 
	
	done
	deluser --remove-home "$udel" >> /dev/null;
	fi
	bases=$(echo "SELECT CONCAT('DROP DATABASE IF EXISTS ', Db, ';') FROM mysql.db WHERE User = '$udel' GROUP BY Db" | mariadb -B | sed -e 1d )
	echo  $bases | mariadb
	echo "DROP USER IF EXISTS $udel@'localhost'" | mariadb;
	echo "DROP USER IF EXISTS $udel@'%'" | mariadb;
	echo "User $udel removed"
}

if [ -n "${1+set}" ]
	then
	if [ $1 == 'rmuser' ]; then
		udel="$2"
	fi;
	if [ -e ".lastuser" ]; then
		. '.lastuser';
	fi;
	$1
	else
	if [ -e ".lastuser" ]; then
		. '.lastuser';
	fi;
	main
fi;
