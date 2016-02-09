#!/bin/bash
#added the ability to run the script locally with arguments in the event that justcurl.com is not avaialbe. 

while getopts "d:r:p:" opt; do
   case $opt in 
      d) DOMAIN=$OPTARG ;;
      r) DOCROOT=$OPTARG ;;
      p) PORT=$OPTARG ;;
   esac
done


# $DOMAIN cannot an empty variable

if [ -z "$DOMAIN" ];then
   echo -e "\nERROR: -d <domain> is a required argument. \n"
   echo -e "NOTE: if -r <document root> and -p <port number> are not entered, the defaults '/var/www/vhosts/' and port 80 will be used.\n"
   exit 1
fi


# Set $DOCROOT and $PORT to defaults if no value is assigned

if [ -z "$DOCROOT" ];then
   DOCROOT='/var/www/vhosts/'$DOMAIN''
fi

if [ -z "$PORT" ];then
   PORT=80
fi

#script from justcurl.com written by Lindsey Anderson

#RHEL/CentOS
if [ -f /etc/redhat-release ]; then
	echo "Redhat based system located"
	DISTRO="RedHat"
fi


#Debian Based or Ubuntu 14
if [[ `cat /etc/issue` == *"14"* ]]; then
	echo "Ubuntu 14 detected"
	DISTRO="Ubuntu14"
else
	if [ -f /etc/debian_version ]; then
		echo "Debian based System located"
		DISTRO="Debian"
	fi
fi


#Amazon Linux
if [[ `cat /etc/issue | grep -i Amazon | awk {'print $1'}` == "Amazon" ]]; then
	echo "Amazon Linux (RHEL Based) system located"
	DISTRO="Amazon"
fi


DATA="<VirtualHost *:$PORT>
        ServerName $DOMAIN
        ServerAlias www.$DOMAIN
        #### This is where you put your files for that domain: $DOCROOT
        DocumentRoot $DOCROOT

	#RewriteEngine On
	#RewriteCond %{HTTP_HOST} ^$DOMAIN
	#RewriteRule ^(.*)$ http://www.$DOMAIN$1 [R=301,L]

        <Directory $DOCROOT>
                Options -Indexes +FollowSymLinks -MultiViews
                AllowOverride All
		Order deny,allow
		Allow from all
        </Directory>"
if [[ "$DISTRO" == "Debian" ]]; then
	DATA=$DATA"
        CustomLog /var/log/apache2/$DOMAIN-access.log combined
        ErrorLog /var/log/apache2/$DOMAIN-error.log"
elif [[ "$DISTRO" == "Redhat" ]]; then
	DATA=$DATA"
        CustomLog /var/log/httpd/$DOMAIN-access.log combined
        ErrorLog /var/log/httpd/$DOMAIN-error.log"
fi
DATA=$DATA"
        # New Relic PHP override
        <IfModule php5_module>
               php_value newrelic.appname "$DOMAIN"
        </IfModule>
        # Possible values include: debug, info, notice, warn, error, crit,
        # alert, emerg.
        LogLevel warn
</VirtualHost>


##
# To install the SSL certificate, please place the certificates in the following files:
# >> SSLCertificateFile    /etc/pki/tls/certs/$DOMAIN.crt
# >> SSLCertificateKeyFile    /etc/pki/tls/private/$DOMAIN.key
# >> SSLCACertificateFile    /etc/pki/tls/certs/$DOMAIN.ca.crt


#<VirtualHost _default_:443>
#        ServerName $DOMAIN
#        ServerAlias www.$DOMAIN
#        DocumentRoot $DOCROOT
#        <Directory $DOCROOT>
#                Options -Indexes +FollowSymLinks -MultiViews
#                AllowOverride All
#        </Directory>
#"
if [[ "$DISTRO" == "Debian" ]]; then
        DATA=$DATA"
#        CustomLog /var/log/apache2/$DOMAIN-ssl-access.log combined
#        ErrorLog /var/log/apache2/$DOMAIN-ssl-error.log"
elif [[ "$DISTRO" == "Redhat" ]]; then
        DATA=$DATA"
#        CustomLog /var/log/httpd/$DOMAIN-ssl-access.log combined
#        ErrorLog /var/log/httpd/$DOMAIN-ssl-error.log"
fi
DATA=$DATA"
#
#        # Possible values include: debug, info, notice, warn, error, crit,
#        # alert, emerg.
#        LogLevel warn
#
#        SSLEngine on"
if [[ "$DISTRO" == "Debian" ]]; then
        DATA=$DATA"
#        SSLCertificateFile    /etc/ssl/certs/2014-$DOMAIN.crt
#        SSLCertificateKeyFile /etc/ssl/private/2014-$DOMAIN.key
#        SSLCACertificateFile /etc/ssl/certs/2014-$DOMAIN.ca.crt
#"
elif [[ "$DISTRO" == "Redhat" ]]; then
        DATA=$DATA"
#        SSLCertificateFile    /etc/pki/tls/certs/2014-$DOMAIN.crt
#        SSLCertificateKeyFile /etc/pki/tls/private/2014-$DOMAIN.key
#        SSLCACertificateFile /etc/pki/tls/certs/2014-$DOMAIN.ca.crt
#"
fi
DATA=$DATA"
#        <IfModule php5_module>
#                php_value newrelic.appname "$DOMAIN"
#        </IfModule>
#        <FilesMatch \\\"\.(cgi|shtml|phtml|php)\$\\\">
#                SSLOptions +StdEnvVars
#        </FilesMatch>
#
#        BrowserMatch \\\"MSIE [2-6]\\\" \\
#                nokeepalive ssl-unclean-shutdown \\
#                downgrade-1.0 force-response-1.0
#        BrowserMatch \\\"MSIE [17-9]\\\" ssl-unclean-shutdown
#</VirtualHost>"



if [[ "$DISTRO" == "Redhat" ]]; then
	# Check for vhost directory in /etc/httpd
	if [ ! -d /etc/httpd/vhost.d  ]; then
		mkdir /etc/httpd/vhost.d &&
		echo "include vhost.d/*.conf" >> /etc/httpd/conf/httpd.conf
	fi
	if [ -f /etc/httpd/vhost.d/$DOMAIN.conf ]; then
		echo "This virtual host already exists on this system."
		echo "Please remove the virtual host configuration file."
		exit 1
	fi
	echo "$DATA" > /etc/httpd/vhost.d/$DOMAIN.conf && 
	mkdir -p $DOCROOT
	 
	
 
elif  [[ "$DISTRO" == "Debian" ]]; then
        	if [ -f /etc/apache2/sites-available/$DOMAIN ]; then
                	echo "This virtual host already exists on this system."
                	echo "Please remove the virtual host configuration file."
                	exit 1
        	fi
	echo "$DATA" > /etc/apache2/sites-available/$DOMAIN && 
	mkdir -p $DOCROOT
	 
	
	ln -s /etc/apache2/sites-available/$DOMAIN /etc/apache2/sites-enabled/domain.com

	

elif [[ "$DISTRO" == "Ubuntu 14" ]]; then
        	if [ -f /etc/apache2/sites-available/$DOMAIN.conf ]; then
               	 echo "This virtual host already exists on this system."
               	 echo "Please remove the virtual host configuration file."
               	 exit 1
        	fi
        	echo "$DATA" > /etc/apache2/sites-available/$DOMAIN.conf &&
        	mkdir -p $DOCROOT


        	ln -s /etc/apache2/sites-available/$DOMAIN.conf /etc/apache2/sites-enabled/$DOMAIN.conf
	

fi


echo "********************"
echo ">> Server Name : $DOMAIN"
echo ">> Server Alias: www.$DOMAIN"
echo ">> Document Root: $DOCROOT"
echo "********************"
