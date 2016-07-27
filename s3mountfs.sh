#!/bin/bash
# Determine the OS

if [ -f /etc/redhat-release ]; then
        ech1`o "Red Hat based sytem detected."
        DISTRO="RedHat"
fi

if [ `cat /etc/issue | grep -i Amazon | awk {'print $1'}` == "Amazon" ]; then
        echo "Amazon Linux (RHEL Based) system located"
        DISTRO="RedHat"
fi



if [ -f /etc/debian_version ]; then
        echo "Debian Based System Detected."
        DISTRO="Debian"
fi



# Install dependencies 


if [ $DISTRO == "RedHat" ]; then
	echo -e "RHEL based OS detected."
	yum install gcc libstdc++-devel gcc-c++ curl-devel libxml2-devel openssl-devel mailcap fuse-libs

fi

if [ $DISTRO = "Debian" ]; then
	echo -e "Debian based OS detected."
	apt-get install build-essential libcurl4-openssl-dev libxml2-dev mime-support fuse-libs

fi
# Download and install Latest Fuse

wget https://github.com/libfuse/libfuse/releases/download/fuse-2.9.7/fuse-2.9.7.tar.gz

mv fuse-2.9.7.tar.gz /usr/src/ 

tar xvf /usr/src/fuse-2.9.7.tar.gz  -C /usr/src/

cd /usr/src/fuse-2.9.7/ && ./configure --prefix=/usr/local && make && make install

export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig

ldconfig
modprobe fuse


#Download and install S3FS

wget https://s3fs.googlecode.com/files/s3fs-1.74.tar.gz 
mv s3fs-1.74.tar.gz /usr/src/

tar xvf /usr/src/s3fs-1.74.tar.gz -C /usr/src/

cd /usr/src/s3fs-1.74/ && ./configure --prefix=/usr/local && make && make install


#Get Access Key ID and Key

while [ -z $KEY_ID ]; do

	echo -e "Access Key ID:"
	read KEY_ID
done 

while [ -z $ACCESS_KEY ]; do
	echo -e "Secret Access Key:"
	read ACCESS_KEY
done


echo "$KEY_ID:$ACCESS_KEY" > ~/.passwd-s3fs

chmod 600  ~/.passwd-s3fs


echo -e "Installation Complete!\n"

echo -e "NOTE: Ensure your Key ID and Access Key are correct in ~/.passwd-s3fs file!\n"
echo -e "To mount a bucket run: s3fs your_bucket_name_here /destination/mount/point/here"

exit
