#!/bin/bash
#
# Script to quickly deploy a Stack designed with WordPress in mind that consists of Nginx -> Varnish -> Apache
# Use at your own risk
#Disclaimer:

echo -e "****WARNING****\n"
echo -e "This script is intended to be run on a new server (with nothing on it currently) and deploys the following stack for WordPress:\n"
echo -e "Nginx (for static content) -> Varnish (for whatever Nginx does not cache/serve) -> Apache (for PHP).\n"

echo -e "---The following Packages will be installed---\n"
echo -e " - Nginx"  
echo -e " - Varnish"  
echo -e " - Apache"  
echo -e " - PHP (and dependencies)"  
echo -e " - MySQL (if you opt for it)\n"

echo -e "Do you wish to proceed? (y/n)"
read PROCEED_ANSWER

if [ $PROCEED_ANSWER == 'n' ]; then
	echo "kthxbai!"
	exit
fi

#Can I haz OS?
if [ -f /etc/redhat-release ]; then
	echo "Redhat based system located"
	DISTRO="RedHat"
fi

if [[ `cat /etc/issue` == *"14"* ]]; then
	echo "Ubuntu 14 detected"
	DISTRO="Ubuntu14"
else
	if [ -f /etc/debian_version ]; then
		echo "Debian based System located"
		DISTRO="Debian"
	fi
fi

if [[ `cat /etc/issue | grep -i Amazon | awk {'print $1'}` == "Amazon" ]]; then
	echo "Amazon Linux (RHEL Based) system located"
	DISTRO="Amazon"
fi

####################
##   RHEL Based    #
####################

#Update Packages
if [[ "$DISTRO" == "RedHat" ]] || [[ "Amazon" ]]; then
	echo -e "Updating packages first..."
	sleep .5 
	yum update

	#Install packages
	echo -e "Installing pacakges now.."
	sleep .5
	yum install php php-mysql nginx httpd varnish mysql-client

	echo "Do you want to install MySQL on this server? (y/n)?"
	read MYSQL_ANSWER

	#Local MySQL?
	if [ $MYSQL_ANSWER == 'y' ]; then
        	echo "Installing MySQL Server..."
        	sleep .5
        	yum install mysql-server


	fi


	#Domain?
	echo -e "Would you like to configure a domain already? (y/n)"
	read DOMAIN_ANSWER

	if [ $DOMAIN_ANSWER == "n" ]; then 
   		echo -e "Ok. Moving on."
		else 
		echo -e "Domain name?:"
		read DOMAIN
	fi


	################### CONFIGURE APACHE ##########################
	echo -e "Configuring Apache...\n" 

	#Create VirtualHosts Directory & include it
	mkdir -p /var/www/vhosts/
	mkdir -p /etc/httpd/vhost.d/
	echo "Include vhost.d/*.conf" >> /etc/httpd/conf/httpd.conf

	#Make Apache Listen on 8080
	sed -i 's/80/8080/' /etc/httpd/conf/httpd.conf

	if [ -f /etc/httpd/ports.conf ]; then 
		sed -i 's/80/8080/' /etc/httpd/ports.conf
	fi

	#Set up domain
	if [ $DOMAIN_ANSWER = 'y' ]; then
		echo -e "Setting up your domain $DOMAIN in Apache...\n"
		wget https://raw.githubusercontent.com/drogomarks/bash_scripts/master/vhosts.sh &> /dev/null && bash vhosts.sh -d $DOMAIN -p 8080
	fi 

	service httpd restart

	echo -e "Done!"
	sleep 1

	################### CONFIGURE VARNISH #########################
	echo -e "Configuring Varnish...\n"

	sed -i 's/80/8081/g' /etc/sysconfig/varnish

	cp /etc/varnish/default.vcl /etc/varnish/default.vcl.orig

	wget https://raw.githubusercontent.com/drogomarks/bash_scripts/master/files/wordpress_default.vcl &> /dev/null && mv wordpress_default.vcl /etc/varnish/default.vcl

	service varnish restart
	echo -e "DONE!\n"
	sleep 1


	##################### CONFIGURE NGINX ########################
	echo -e "Configuring Nginx...\n"

	cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.orig

	wget https://raw.githubusercontent.com/drogomarks/bash_scripts/master/files/default_nginx.conf &> /dev/null && mv default_nginx.conf /etc/nginx/nginx.conf

	touch /etc/nginx/conf.d/global.deny

	wget https://raw.githubusercontent.com/drogomarks/bash_scripts/master/files/wpStack_nginx_vhost.conf &> /dev/null && mv wpStack_nginx_vhost.conf /etc/nginx/conf.d/default_template.conf

	#Set up domain 
	if [ $DOMAIN_ANSWER = 'y' ]; then
		cp /etc/nginx/conf.d/default_template.conf /etc/nginx/conf.d/$DOMAIN.conf
		sed -i "s/example.com/$DOMAIN/g" /etc/nginx/conf.d/$DOMAIN.conf
	fi

	service nginx restart 
	echo -e "DONE!\n"
	sleep 1

fi

####################
    Debian based   #
####################

#Update Packagesa
if [[ "$DISTRO" == "Debian" ]]; then
	echo -e "Updating packages first..."
	sleep .5 
	apt-get update

	#Install packages
	echo -e "Installing pacakges now.."
	sleep .5
	apt-get install php5 libapache2-mod-php5 php5-mcrypt php5-mysql nginx varnish mysql-client

	echo "Do you want to install MySQL on this server? (y/n)?"
	read MYSQL_ANSWER

		#Local MySQL?
	if [ $MYSQL_ANSWER == 'y' ]; then
        	echo "Installing MySQL Server..."
        	sleep .5
        	apt-get install mysql-server


	fi


	#Domain?
	echo -e "Would you like to configure a domain already? (y/n)"
	read DOMAIN_ANSWER

	if [ $DOMAIN_ANSWER == "n" ]; then 
   		echo -e "Ok. Moving on."
	else 
		echo -e "Domain name?:"
		read DOMAIN
	fi


	################### CONFIGURE APACHE ##########################
	echo -e "Configuring Apache...\n" 

	#Create VirtualHosts Directory & include it
	mkdir -p /var/www/vhosts/

	#Disabled any default sites enabled on port 80
	SITES_ENABLED=`a2query -s | awk {'print $1'}`
	for site in $SITES_ENABLED;
	do 
		a2dissite $site
	done	

	#Make Apache Listen on 8080
	sed -i 's/80/8080/' /etc/apache2/apache2.conf
	if [ -f /etc/apache2/ports.conf ]; then 
		sed -i 's/80/8080/' /etc/apache2/ports.conf
	fi

	#Set up domain
	if [ $DOMAIN_ANSWER = 'y' ]; then
		echo -e "Setting up your domain $DOMAIN in Apache...\n"
		wget https://raw.githubusercontent.com/drogomarks/bash_scripts/master/vhosts.sh &> /dev/null && bash vhosts.sh -d $DOMAIN -p 8080
	fi 

	service apache2 restart

	echo -e "Done!"
	sleep 1

	################### CONFIGURE VARNISH #########################
	echo -e "Configuring Varnish...\n"

	sed -i 's/6081/8081/g' /etc/default/varnish

	cp /etc/varnish/default.vcl /etc/varnish/default.vcl.orig

	wget https://raw.githubusercontent.com/drogomarks/bash_scripts/master/files/wordpress_default.vcl &> /dev/null && mv wordpress_default.vcl /etc/varnish/default.vcl

	service varnish restart
	echo -e "DONE!\n"
	sleep 1


	##################### CONFIGURE NGINX ########################
	echo -e "Configuring Nginx...\n"

	cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.orig

	wget https://raw.githubusercontent.com/drogomarks/bash_scripts/master/files/default_nginx.conf &> /dev/null && mv default_nginx.conf /etc/nginx/nginx.conf

	touch /etc/nginx/conf.d/global.deny

	wget https://raw.githubusercontent.com/drogomarks/bash_scripts/master/files/wpStack_nginx_vhost.conf &> /dev/null && mv wpStack_nginx_vhost.conf /etc/nginx/conf.d/default_template.conf

	#Set up domain 
	if [ $DOMAIN_ANSWER = 'y' ]; then
		cp /etc/nginx/conf.d/default_template.conf /etc/nginx/conf.d/$DOMAIN.conf
		sed -i "s/example.com/$DOMAIN/g" /etc/nginx/conf.d/$DOMAIN.conf
	fi

	service nginx restart 
	echo -e "DONE!\n"
	sleep 1
fi
