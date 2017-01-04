#!/bin/bash
##################
# Hot and Diry bash script to install LAMP and set up WordPress on an instance.
# ***NOTE*** LAMP Install portion DOES NOT work on RHEL 7. #


echo -e "Do you need to install LAMP on this server?(y/n)"
read LAMP_ANSWER

if [ $LAMP_ANSWER == 'y' ];then

#Can I haz OS?
#RHEL 7 or 6
if [ -f /etc/redhat-release ]; then
        if [[ `cat /etc/redhat-release` == *"7"* ]];then
                echo -e "RedHat 7 System detected."
                echo -e "RedHat 7 is currently not supported...but I'm working on it!"
                echo -e "kthxbai!\n"
                DISTRO="RedHat7"
                exit
        else
                echo "RedHat 6 or earlier detected"
                DISTRO="RedHat"
        fi
fi

#Debian
if [ -f /etc/debian_version ]; then
                echo "Debian based System located"
                DISTRO="Debian"
fi

#Amazon Linux
if [[ `cat /etc/issue | grep -i Amazon | awk {'print $1'}` == "Amazon" ]]; then
        echo "Amazon Linux (RHEL Based) system located"
        DISTRO="Amazon"
fi




#Update Packages
if [ "$DISTRO" == "RedHat" ] || [ "$DISTRO" == "Amazon" ]; then
        echo -e "Updating packages first..."
        sleep .5
        yum update

        #Install packages
        echo -e "Installing pacakges now.."
        sleep .5
        yum install php php-mysql httpd mysql-client

        echo "Do you want to install MySQL on this server? (y/n)?"
        read MYSQL_ANSWER

        #Local MySQL?
        if [ $MYSQL_ANSWER == 'y' ]; then
                echo "Installing MySQL Server..."
                sleep .5
                yum install mysql-server
                service mysqld start
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


        #Set up domain
        if [ $DOMAIN_ANSWER = 'y' ]; then
                echo -e "Setting up your domain $DOMAIN in Apache...\n"
                wget https://raw.githubusercontent.com/drogomarks/bash_scripts/master/vhosts.sh &> /dev/null && bash vhosts.sh -d $DOMAIN
        fi

        service httpd restart

        echo -e "Done!"
        sleep 1



####################
#    Debian based   #
####################

#Update Packagesa
if [[ "$DISTRO" == "Debian" ]]; then
        echo -e "Updating packages first..."
        sleep .5
        apt-get update

        #Install packages
        echo -e "Installing pacakges now.."
        sleep .5
        apt-get install php5 libapache2-mod-php5 php5-mcrypt php5-mysql mysql-client

        echo "Do you want to install MySQL on this server? (y/n)?"
        read MYSQL_ANSWER

                #Local MySQL?
        if [ $MYSQL_ANSWER == 'y' ]; then
                echo "Installing MySQL Server..."
                sleep .5
                apt-get install mysql-server
                service mysql start
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


        #Set up domain
        if [ $DOMAIN_ANSWER = 'y' ]; then
                echo -e "Setting up your domain $DOMAIN in Apache...\n"
                wget https://raw.githubusercontent.com/drogomarks/bash_scripts/master/vhosts.sh &> /dev/null && bash vhosts.sh -d $DOMAIN
        fi

        service apache2 restart

        echo -e "Done!"
        sleep 1

    fi

fi

else

    echo -e "Okay moving on..."

fi

echo -e "What directory are you installing Wordpress to? (FULL path)\n"
read WP_DIR

echo $WP_DIR


if [ ! -d "$WP_DIR" ]; then
        echo -e "$PWD does not exsist, would like to create it now? (yes/no)"
        read ANSWER
        if [ $ANSWER == "no" ] || [ $ANSWER == "No" ] || [ $ANSWER == "NO" ]; then
                echo -e "Exiting..."
                exit
        fi

        if [ $ANSWER == "yes" ] || [ $ANSWER == "Yes" ] || [ $ANSWER == "YES" ]; then
                mkdir -p $WP_DIR

        else
                echo -e "No valid answer was given, exiting..."
                exit
        fi
fi



#Grab the Tarball
echo -e "Downloading latest version of WordPress...\n"
sleep .5
wget wordpress.org/latest.tar.gz && tar xvf latest.tar.gz &> /dev/null

#Move the contents to the Document Root
echo -e "\nMoving contents to Document Root..\n"
cp -ra wordpress/* $WP_DIR

#Copy the config file
echo -e "Copying config file..\n"
cp $WP_DIR/wp-config-sample.php $WP_DIR/wp-config.php

#Clean up
echo -e "Cleaning up.."
rm -rf wordpress/ && rm latest.tar.gz

echo -e "Done!"


#Set Permissions

echo -e "Setting permissions.."

find $WP_DIR -type d -exec chmod 2775 {} \;
find $WP_DIR -type f -exec chmod 2664 {} \;

if [ $DISTRO == "RedHat" ] || [ $DISTRO == "Amazon" ];then
        chown apache $WP_DIR -R
elif [ $DISTRO == "Debian" ]; then
        chown www-data $WP_DIR -R
fi

#Set up DB?

echo -e "Would you like to set up a database for this installation (on this server i.e. localhost) y/n"
read DB_ANSWER

if [ $DB_ANSWER == "n" ] || [ $DB_ANSWER == "N" ] || [ $DB_ANSWER == "no" ] || [ $DB_ANSWER == "No" ] || [ $ANSWER == "NO" ]; then
        echo "Exiting..."
        exit
else

        echo -e "What database name would you like?"
        read DB_NAME

        echo -e "What user name would you like for your database $DB_NAME?"
        read DB_USR

        echo -e "Password for $DB_USR?"
        read DB_USR_PASS

        mysql -e "create database $DB_NAME"

        mysql -e "grant all privileges on $DB_NAME.* to $DB_USR@'localhost' identified by '"$DB_USR_PASS"';"

fi



#Plugin new DB info to wp-config.php

sed -i "s/database_name_here/$DB_NAME/g" $WP_DIR/wp-config.php
sed -i "s/username_here/$DB_USR/g" $WP_DIR/wp-config.php
sed -i "s/password_here/$DB_USR_PASS/g" $WP_DIR/wp-config.php


echo -e "All Done! Go to your IP or Domain to continue Wordpress set up."
