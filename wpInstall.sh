#!/bin/bash

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


#Set up DB?

echo - e "Would you like to set up a database for this installation (on this server/localhost)?"
read DB_ANSWER

if [ $DB_ANSWER == "no" ] || [ $DB_ANSWER == "No" ] || [ $ANSWER == "NO" ]; then
	echo "Exiting..."
	exit
else 

echo -e "What database name would you like?" 
read DB_NAME

echo -e "What user name would you like for your database $DB_NAME?"
read DB_USR

echo -e "Password for this $DB_USR:"
read $DB_USR_PASS


mysql -e "grant all privileges on $DB_NAME.* to $DB_USR identified by '$DB_USR_PASS'";"


