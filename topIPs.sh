#!/bin/bash
# Simple scrpt to look at 2000 lines of an Apache access log file and find the top 15 most occurning addresses and do a whois look up on them. 
# Script does not make any modifications to files, but does not gaurentee anything. use at your own risk. 

#Set Function for 'help' text
function help {
    echo -e "ERROR: No arguments given. -f or --file [LOG FILE] REQUIRED.\n"
    echo -e "Usage: ./topIPs.sh -f [LOG FILE] -l [# of Lines to Parse] -m [Max Amount of Top IPs to Show]\n"
    echo -e "-f\t --file\t\t\t  The log file to parse/examin.\n"
    echo -e "-l\t --lines-to-parse\t  The amount of lines you'd like to examine from the log file.
                                  Default value is set to 1000 if none is set.\n"
    echo -e "-m\t --max-ips\t\t  The max amount of 'top' IPs you'd like to gather from the log file.
                                  Default value is 10 if no value set."

    exit 0
}

#Make sure some args are being passed
if [[ $# == 0 ]];then
	help
else

# Store key/value pairs of args
while [[ $# > 0 ]];do
    key="$1"

     case $key in
        -l|--lines-to-parse)
        LINES_TO_PARSE="$2"
        shift 
        ;;
        -m|--max-ips)
        MAX_IPS="$2"
        shift 
        ;;
        -f|--file)
        LOG_FILE="$2"
        shift
        ;;
        -h|--help)
	help
        ;;
        *)
	help
        ;;
    esac
    shift 
done
fi


if [ -z $LINE_TO_PARSE ];then
    LINES_TO_PARSE=2000
elif [ -z $MAX_IPS ];then
    MAX_IPS=15
fi


# Detect OS to make sure WHOIS is installed
#RHEL/CentOS
if [ -f /etc/redhat-release ]; then
	echo "Redhat based system located"
	DISTRO="Redhat"
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
	DISTRO="Redhat"
fi


# Verify if WHOIS is installed, if not install it

if [ -f /usr/bin/whois ];then
     echo -e "Verifying whois is installed..."
elif [ $DISTRO == "Redhat" ];then
    echo "whois NOT installed. Installing.."
    yum -y install jwhois
elif [ $DISTRO == "Ubuntu14" ] || [ $DISTRO == "Debian" ];then
    echo -e "whois NOT installed. Installing..."
    apt-get -y install whois
fi



#Let's gather our list of "top" hitting IPs Addresses and show them to the user
echo -e "\n-----------------------------------------------------------------"
echo -e "Top $MAX_IPS IPs in last $LINES_TO_PARSE lines of access log (occurences on left):"
echo -e "-----------------------------------------------------------------\n"


tail -n $LINES_TO_PARSE $LOG_FILE | cut -f 1 -d ' '| sort | uniq -c| sort -nr | head -$MAX_IPS | sed 's/,//g'


# Now lets put those IPs into a list and and gather some info using whois

echo -e "\nGathing more information about these IPs...\n"

sleep 1

TOP_IPS=$(tail -n $LINES_TO_PARSE $LOG_FILE | cut -f 1 -d ' '| sort | uniq -c| sort -nr | head -$MAX_IPS | sed 's/,//g' | awk {'print $2'})

for ip in $TOP_IPS;do
     echo -e "$ip"
     echo -e "------------"
     whois $ip | grep -i "OrgName\|descr\|City\|State\|Country\|Amazon"
     echo -e "------------\n"
     sleep 1
done

