#!/bin/bash
#
#Basic bash script for reading Nginx vhost files and determining what domains are running and what ports are being used
#
# Determine the OS - RHEL or Debian based
if [ -f /etc/redhat-release ]; then
        echo "Red Hat based sytem detected."
        DISTRO="RedHat"
fi

if [ -f /etc/debian_version ]; then
        echo "Debian Based System Detected."
        DISTRO="Debian"
fi

sleep 1
echo -e "Examing Nginx vhost configuration..."
sleep 1


#The following if statement checks that the OS is RHEL or Debian based and then pulls out all the .conf/sites-enabled files in the nginx vhost
#direcotry into a list and then the for loop iterates over each one pulling out the server_name and the port that is listening.

#Got it working now by creating a loop for 80, 443 and anything else under Alts.

if [[ "$DISTRO" == "RedHat" ]]; then
        
	echo -e "The following vhosts directories have been located: \f"

	if [ -d /etc/nginx/vhost.d/ ]; then
		CONFS1=$(ls /etc/nginx/vhost.d/*.conf | sort)
		echo -e "- vhost.d/ vhosts directory found. \n"
		sleep 1
	fi

	if [ -d /etc/nginx/sites-available/ ]; then
		CONFS2=$(ls /etc/nginx/sites-available/*.conf | sort)
		echo -e "- sites-available/ vhosts directory found. \n"
		sleep 1
	fi
	
	if [ -d /etc/nginx/conf.d/ ]; then
		CONFS=$(ls /etc/nginx/conf.d/*.conf | sort)
		echo -e "- conf.d/ vhosts directory found. \n"
		sleep .5
        fi


        echo -e "===========================================================================   "
        echo -e "Nginx Tool has found the follwing vhosts configured on the following ports:   "
        echo -e "=========================================================================== \f"



############# $CONFS

if [[ -z $CONFS ]];then
	exit
else

        echo -e "\n-------------"
        echo -e "From conf.d/"
        echo -e "------------- \f"

	sleep 1

        echo -e "HTTP: "

        for i in  $CONFS;
                do
                        PORT=`cat $i | grep listen | grep -o '[80]\+'  | awk 'NR==1'`
                        DOMAIN=`cat $i | grep -m1 server_name | awk '{print $2}' | sed 's/;//g'`
                        if [[ "$DOMAIN" == "server_name" ]]; then
                                DOMAIN=`cat $i | grep -m1 server_name | awk '{print $3}' | sed 's/;//g'`
                        fi
                        if [[ "$PORT" == "80" ]]; then
                                echo -e "$DOMAIN :$PORT ($i) \f"
                        fi
                done | column -t | sort -rk 2,2

        echo -e "HTTPS:"

        for i in  $CONFS;
                do
                        PORT=`cat $i | grep listen | grep -o '[443]\+'  | awk 'NR==1'`
                        DOMAIN=`cat $i | grep -m1 server_name | awk '{print $2}' | sed 's/;//g'`
                        if [[ "$DOMAIN" == "server_name" ]]; then
                                DOMAIN=`cat $i | grep -m1 server_name | awk '{print $3}' | sed 's/;//g'`
                        fi
                        if [[ "$PORT" == "443" ]]; then
                        echo -e "$DOMAIN :$PORT ($i) \f"
                        fi
                done | column -t | sort -rk 2,2


        echo -e "Alt. Ports: "

        for i  in  $CONFS;
                do
                        PORT=`cat $i | grep listen | grep -o '[0-9]\+' | awk 'NR==1'`
                        DOMAIN=`cat $i | grep -m1 server_name | awk '{print $2}' | sed 's/;//g'`
                        if [[ "$DOMAIN" == "server_name" ]]; then
                                DOMAIN=`cat $i | grep -m1 server_name | awk '{print $3}' | sed 's/;//g'`
                        fi
                        if [[ "$PORT" != "80" && "$PORT" != "443" ]]; then
                        echo -e "$DOMAIN :$PORT ($i) \f"
                        fi
        done | column -t | sort -rk 2,2


fi

############# $CONFS1
if [[ -z $CONFS1 ]];then
	exit
else

        echo -e "\n-------------"
        echo -e "From vhost.d/"
        echo -e "------------- \f"

	sleep 1
	
        echo -e "HTTP: "

        for i in  $CONFS1;
                do
                        PORT=`cat $i | grep listen | grep -o '[80]\+'  | awk 'NR==1'`
                        DOMAIN=`cat $i | grep -m1 server_name | awk '{print $2}' | sed 's/;//g'`
                        if [[ "$DOMAIN" == "server_name" ]]; then
                                DOMAIN=`cat $i | grep -m1 server_name | awk '{print $3}' | sed 's/;//g'`
                        fi
                        if [[ "$PORT" == "80" ]]; then
                                echo -e "$DOMAIN :$PORT ($i) \f"
                        fi
                done | column -t | sort -rk 2,2

        echo -e "HTTPS:"

        for i in  $CONFS1;
                do
                        PORT=`cat $i | grep listen | grep -o '[443]\+'  | awk 'NR==1'`
                        DOMAIN=`cat $i | grep -m1 server_name | awk '{print $2}' | sed 's/;//g'`
                        if [[ "$DOMAIN" == "server_name" ]]; then
                                DOMAIN=`cat $i | grep -m1 server_name | awk '{print $3}' | sed 's/;//g'`
                        fi
                        if [[ "$PORT" == "443" ]]; then
                        echo -e "$DOMAIN :$PORT ($i) \f"
                        fi
                done | column -t | sort -rk 2,2


        echo -e "Alt. Ports: "

        for i  in  $CONFS1;
                do
                        PORT=`cat $i | grep listen | grep -o '[0-9]\+' | awk 'NR==1'`
                        DOMAIN=`cat $i | grep -m1 server_name | awk '{print $2}' | sed 's/;//g'`
                        if [[ "$DOMAIN" == "server_name" ]]; then
                                DOMAIN=`cat $i | grep -m1 server_name | awk '{print $3}' | sed 's/;//g'`
                        fi
                        if [[ "$PORT" != "80" && "$PORT" != "443" ]]; then
                        echo -e "$DOMAIN :$PORT ($i) \f"
                        fi
        done | column -t | sort -rk 2,2


fi

############# $CONFS2

if [[ -z $CONFS2 ]]; then
	exit
else

        echo -e "\n---------------------"
        echo -e "From sites-available/"
        echo -e "--------------------- \f"

	sleep 1

        echo -e "HTTP: "

        for i in  $CONFS2;
                do
                        PORT=`cat $i | grep listen | grep -o '[80]\+'  | awk 'NR==1'`
                        DOMAIN=`cat $i | grep -m1 server_name | awk '{print $2}' | sed 's/;//g'`
                        if [[ "$DOMAIN" == "server_name" ]]; then
                                DOMAIN=`cat $i | grep -m1 server_name | awk '{print $3}' | sed 's/;//g'`
                        fi
                        if [[ "$PORT" == "80" ]]; then
                                echo -e "$DOMAIN :$PORT ($i) \f"
                        fi
                done | column -t | sort -rk 2,2

        echo -e "HTTPS:"

        for i in  $CONFS2;
                do
                        PORT=`cat $i | grep listen | grep -o '[443]\+'  | awk 'NR==1'`
                        DOMAIN=`cat $i | grep -m1 server_name | awk '{print $2}' | sed 's/;//g'`
                        if [[ "$DOMAIN" == "server_name" ]]; then
                                DOMAIN=`cat $i | grep -m1 server_name | awk '{print $3}' | sed 's/;//g'`
                        fi
                        if [[ "$PORT" == "443" ]]; then
                        echo -e "$DOMAIN :$PORT ($i) \f"
                        fi
                done | column -t | sort -rk 2,2


        echo -e "Alt. Ports: "

        for i  in  $CONFS2;
                do
                        PORT=`cat $i | grep listen | grep -o '[0-9]\+' | awk 'NR==1'`
                        DOMAIN=`cat $i | grep -m1 server_name | awk '{print $2}' | sed 's/;//g'`
                        if [[ "$DOMAIN" == "server_name" ]]; then
                                DOMAIN=`cat $i | grep -m1 server_name | awk '{print $3}' | sed 's/;//g'`
                        fi
                        if [[ "$PORT" != "80" && "$PORT" != "443" ]]; then
                        echo -e "$DOMAIN :$PORT ($i) \f"
                        fi
        done | column -t | sort -rk 2,2

	fi        
fi
nginx -t


#Essentially the same thing but with Debian/Ubuntu

if [[ "$DISTRO" == "Debian" ]]; then
        echo -e "===========================================================================   "
        echo -e "Nginx Tool has found the follwing vhosts configured on the following ports:   "
        echo -e "=========================================================================== \f"
        CONFS=$(ls /etc/nginx/sites-enabled/* | sort)

        echo -e "HTTP: "

        for i in  $CONFS;
                do
                        PORT=`cat $i | grep listen | grep -o '[80]\+'  | awk 'NR==1'`
                        DOMAIN=`cat $i | grep -m1 server_name | awk '{print $2}' | sed 's/;//g'`
                        if [[ "$DOMAIN" == "server_name" ]]; then
                                DOMAIN=`cat $i | grep -m1 server_name | awk '{print $3}' | sed 's/;//g'`
                        fi
                        if [[ "$PORT" == "80" ]]; then
                                echo -e "$DOMAIN :$PORT ($i) \f"
                        fi
                done | column -t | sort -rk 2,2

        echo -e "HTTPS:"

        for i in  $CONFS;
                do
                        PORT=`cat $i | grep listen | grep -o '[443]\+'  | awk 'NR==1'`
                        DOMAIN=`cat $i | grep -m1 server_name | awk '{print $2}' | sed 's/;//g'`
                        if [[ "$DOMAIN" == "server_name" ]]; then
                                DOMAIN=`cat $i | grep -m1 server_name | awk '{print $3}' | sed 's/;//g'`
                        fi
                        if [[ "$PORT" == "443" ]]; then
                        echo -e "$DOMAIN :$PORT ($i) \f"
                        fi
                done | column -t | sort -rk 2,2


        echo -e "Alt. Ports: "

        for i  in  $CONFS;
                do
                        PORT=`cat $i | grep listen | grep -o '[0-9]\+' | awk 'NR==1'`
                        DOMAIN=`cat $i | grep -m1 server_name | awk '{print $2}' | sed 's/;//g'`
                        if [[ "$DOMAIN" == "server_name" ]]; then
                                DOMAIN=`cat $i | grep -m1 server_name | awk '{print $3}' | sed 's/;//g'`
                        fi
                        if [[ "$PORT" != "80" && "$PORT" != "443" ]]; then
                        echo -e "$DOMAIN :$PORT ($i) \f"
                        fi
        done | column -t | sort -rk 2,2

        nginx -t

fi
