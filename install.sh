#!/bin/bash
#################################
# Default Instalation Debian
#
# by Rohman (me@nurohman.com)
#################################


echo "
#################################
# Welcome 
# 
# Default VM Instalation
# Version 1.0
#################################
"
if [ /etc/debian_version ]; then
debian=$(grep "VERSION=" /etc/os-release |awk -F= {'print $2'}|sed s/\"//g |sed s/[0-9]//g | sed s/\)$//g |sed s/\(//g)
fi

updaterepo(){

apt-get install -y --force-yes apt-transport-https curl vim && apt-get remove -y --force-yes nano
echo "syntax on" > ~/.vimrc

if [ ! -f "/etc/apt/sources.list.d/nginx.list" ]; then
echo "deb http://nginx.org/packages/mainline/debian/$debian nginx" >> /etc/apt/sources.list.d/nginx.list
echo "deb-src http://nginx.org/packages/mainline/debian/$debian nginx" >> /etc/apt/sources.list.d/nginx.list
wget -O nginx.gpg https://nginx.org/keys/nginx_signing.key
apt-key add nginx.gpg && rm -rf nginx.gpg
fi 

if [ ! -f "/etc/apt/sources.list.d/php.list" ]; then
echo "deb https://packages.sury.org/php/$debian main" >> /etc/apt/sources.list.d/php.list
wget -O php.gpg https://packages.sury.org/php/apt.gpg
apt-key add php.gpg && rm -rf php.gpg
fi

apt-get -y --force-yes install software-properties-common
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 0xcbcb082a1bb943db
add-apt-repository 'deb [arch=amd64,i386,ppc64el] http://download.nus.edu.sg/mirror/mariadb/repo/10.1/debian jessie main'

apt-get update -y --force-yes && apt-get upgrade -y --force-yes
}

########################################
# Default page
# usage: 
# default_page [username] [domain name]
########################################
default_page(){
	echo "<!DOCTYPE html><html><head><title>Hellcome to $2</title><style>body{ color: #333; padding:150px;} h1{ font-size:50px; } </style></head><body><h1>Hellcome to $2</h1><p>This is default page. if you are administrator please delete this page.</p></body></html>" > /home/$1/public_html/default.html
	echo "<!DOCTYPE html><html><head><title>Server crash</title><style>body{ color: #333; padding:150px;} h1{ font-size:50px; } </style></head><body><h1>Opss server crash</h1><p>Currently server crash because unknown reason with code 50x, please contact administrator.</p></body></html>" > /home/$1/50x.html
	echo "<!DOCTYPE html><html><head><title>Not Found</title><style>body{ color: #333; padding:150px;} h1{ font-size:50px; } </style></head><body><h1>404 Not Found</h1><p>Hah... we can't find your request please use search form or ask administrator to fix this issue.</p></body></html>" > /home/$1/400.html
}

########################################
# Nginx config
# usage: 
# nginx_server [config file ] [server name] [username]
########################################
nginx_conf(){
	if [ ! -d "/home/$3" ]; then 
		mkdir /home/$3
	fi
	mkdir /home/$3/{public_html,etc}
	mkdir /home/$3/etc/{php,nginx}
	default_page $3	$2
	chown -R $3:$3 /home/$3
	
	if [ -f "$1" ]; then 
		rm -rf $1
	fi
	
	echo "server {" > $1
	echo "	listen 80;" >> $1
	echo "	server_name $2;" >> $1
	echo "	client_max_body_size 2M;" >> $1
	echo "	sendfile off;" >> $1
	echo "	root /home/$3/public_html;" >> $1
	echo "	index default.html index.html maintenance.html maintenance.php index.php;" >> $1
	
	#echo "	location / {" >> $1
	#echo "	}" >> $1
	
	echo "	error_page 500 502 503 504	/50x.html;" >> $1
	echo "	error_page 400	/400.html;" >> $1
	echo "	location = 50x.html {" >> $1
	echo "		root /home/$3;" >> $1
	echo "	}" >> $1		
	
	echo "	location ~ \.php$ {" >> $1
	echo "		try_files \$uri = 404;" >> $1
	echo "		fastcgi_pass	unix:/run/php/$3.sock;" >> $1
	echo "		fastcgi_index	index.php;" >> $1
	echo "		fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;" >> $1
	echo "		include fastcgi_params;" >> $1
	echo "	}" >> $1
	
	echo "	include $3/etc/nginx/*.conf;" >> $1
	echo "}" >> $1	
}

############################################
# PHP FPM Conf
# Usage
# php_conf [username]
############################################
php_conf(){
	path="/etc/php/7.1/fpm/pool.d/$1.conf"
	
	if [ -f "$path" ]; then 
		rm -rf $path
	fi
	
	echo "[$1]" >> $path
	echo "user = $1" >> $path
	echo "group = $1" >> $path
	echo "listen = /run/php/$1.sock" >> $path
	echo "listen.owner = nginx" >> $path
	echo "listen.group = nginx" >> $path
	echo "listen.mode = 0750" >> $path
	echo "pm = dynamic" >> $path
	echo "pm.max_children = 5" >> $path
	echo "pm.start_servers = 2" >> $path
	echo "pm.min_spare_servers = 1" >> $path
	echo "pm.max_spare_servers = 3"	 >> $path
}

install_nginx(){
	apt-get install -y --force-yes nginx php7.1-bz2 php7.1-bcmath php7.1-curl php7.1-fpm php7.1-gd php7.1-imap php7.1-interbase php7.1-intl php7.1-json \
	php7.1-mbstring php7.1-mcrypt php7.1-mysql php7.1-sqlite3 php7.1-xml php7.1-xmlrpc php7.1-zip mariadb-server mariadb-client curl
	
	rm -rf /etc/nginx/conf.d/default.conf
	nginx_conf /etc/nginx/conf.d/default.conf localhost nginx
	php_conf nginx
	default_page nginx localhost
	mv /etc/php/7.1/fpm/pool.d/www.conf /etc/php/7.1/fpm/pool.d/www.conf.default
	systemctl restart nginx && systemctl restart php7.1-fpm
	choices
}

install_nodejs(){
	apt-get install -y --force-yes curl sudo
	curl -sL https://deb.nodesource.com/setup_7.x | sudo -E bash -
	apt-get install -y --force-yes nodejs
	choices
}

install_php(){
	apt-get install -y --force-yes php7.1-bz2 php7.1-bcmath php7.1-curl php7.1-fpm php7.1-gd php7.1-imap php7.1-interbase php7.1-intl php7.1-json \
	php7.1-mbstring php7.1-mcrypt php7.1-mysql php7.1-sqlite3 php7.1-xml php7.1-xmlrpc php7.1-zip
	
	php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
	php -r "if (hash_file('SHA384', 'composer-setup.php') === '55d6ead61b29c7bdee5cccfb50076874187bd9f21f65d8991d46ec5cc90518f447387fb9f76ebae1fbbacf329e583e30') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
	php composer-setup.php --install-dir=/bin/ --filename=composer
	php -r "unlink('composer-setup.php');"
	
	choices
}

install_wordpress(){
	echo "Install wordpress"
	url="https://wordpress.org/latest.tar.gz"	
	latest=$(curl -sI $url | grep -o -E 'filename=.*$' | sed -e 's/filename=//' | sed 's/\r$//')
	path="/home/$1/public_html/"	
	current=""
	
	if [ -f "WordPress.txt" ]; then 
		current=$(cat WordPress.txt)
	fi
	
	if [ "$latest" != "$current" ] || [ ! -f "$current" ]; then
		rm -rf $current
		wget -O $latest $url
		echo $latest > WordPress.txt		
	fi
	
	read -p "WordPress path [$path]" wpath
	tar -xvf $latest
	
	if [ -z "$wpath" ]; then 
		mv -f wordpress/* $path
		chown -R $1:$1 $path
	else 
		mv -f wordpress/* $wpath
		chown -R $1:$1 $wpath
	fi
	rm -rf wordpress	
	echo "Install WordPress finished"
	choices
}


setup_config(){
	echo "	###############################
			# Setup configs
			###############################"
	read -p "Enter username: " username
	read -p "Enter domain name: " domain
	
	if [ -z "$(getent passwd $1)" ]; then 
		echo "User exists...."
	else 
		useradd -m -d /home/$username -s /usr/sbin/nologin $username
	fi
		
	nginx_conf /etc/nginx/conf.d/$username.conf $domain $username
	php_conf $username
	systemctl reload nginx && systemctl reload php7.1-fpm	
	
	
#	read -p "Instal default error page? [Y/n]: " install
#	if [ "$install" == "n" ]; then 
#		choices
#	else 
#		echo "Install default page"
#	fi 
	
}

#########################################
# Vagran config 
#########################################
vagrant_conf(){
	apt-get install -y sudo build-essential module-assistant
	if [ -z "$(getent passwd vagrant)" ]; then 
		useradd -m -d /home/vagrant vagrant
		passwd vagrant
	fi 
	
	if [ ! -f "/etc/sudoers.d/vagrant" ]; then 	
		echo "vagrant ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/vagrant 
	fi
	
	if [ ! -d "/home/vagrant/.ssh" ]; then 
		mkdir /home/vagrant/.ssh
	fi
	
	if [ ! -f "/home/vagrant/.ssh/authorized_keys" ]; then 
		wget -O /home/vagrant/.ssh/authorized_keys https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant.pub
		chown -R vagrant:vagrant /home/vagrant 
	fi	
}

testconfig(){
	rm -rf /etc/nginx/conf.d/default.conf 	
	nginx_conf /etc/nginx/conf.d/default.conf localhost nginx
	php_conf nginx
	mv /etc/php/7.1/fpm/pool.d/www.conf /etc/php/7.1/fpm/pool.d/www.conf.default
	systemctl restart nginx && systemctl restart php7.1-fpm
	echo "<?php phpinfo(); ?>" > /home/nginx/public_html/index.php
	chown nginx:nginx /home/nginx/public_html/index.php
}

choices(){
echo "
Please select your instalation
1. Install repostory for nginx, php, mariadb 
2. Nginx + PHP 7.1 + MariaDB
3. NodeJS
4. PHP 7.1 + Composer
5. Install / Update wordpress
6. Add new virtualhost
7. Setup vagrant user
#. Exit
"
read -p "Select your choice [#]: " choice 

case "$choice" in 
	1) 	echo "Installing repostory"		
		updaterepo
		choices
		;;
		
	2)	echo "Install nginx + php7.1 + mariadb"
		install_nginx
		;;
		
	3)	echo "Install NodeJs"
		install_nodejs
		;;
		
	4)	echo "Install PHP + Composer"
		install_php
		;;
		
	5)	echo "Install wordpress"
		read -p "Please enter username: " user
		install_wordpress $user
		;;
		
	6)	echo "Setup new virtual host"
		setup_config
		;;
		
	7) echo "Setup vagrant user"
		vagrant_conf
		choices
		;;
	99) echo "Test"		
		testconfig
		;;
		
	*)	echo "######################################
# Thank you 
######################################"
esac
}

choices