#!/bin/bash   


#CloudLink SecureVM script to download, install and encrypt a drive on CoreOS
#Change the IP's to match CloudLink Center





cd ~
#Check if the SecureVM script exists, if not download and execute it
if [ ! -f ~/securevm ]
then
	wget http://192.168.244.132/cloudlink/securevm
	sudo sh securevm -S 192.168.244.132
fi

sudo mkdir /var/lib/docker
#Check if the disk is already partitioned/mounted if not then partition/mount

sleep 5

if ls -l /dev/ | grep sdb1
then
	echo "Disk is already paritioned"
else
	echo "Running fdisk and formatting the partition"
	(
	echo o 
	echo n ls -l /dev/ | grep sdb1
	echo p 
	echo 1 
	echo   
	echo   
	echo w 
	) | sudo fdisk /dev/sdb
	
	sudo mkfs.ext4 /dev/sdb1
	sudo mount /dev/sdb1 /var/lib/docker
fi

#try to mount
mount /dev/sdb1 /var/lib/docker

#Check if the disk is encrypted
if  ls -l /dev/mapper | grep svm_sdb1
then
	echo "Device is already encrypted"
else
	echo "Tryinging to encrypt the data disk"
	sudo svm encrypt /var/lib/docker
	#If the encryption was already done, try to recover
	if (($? == 1))
		then 
			echo "Datadisk is already encrypted, recovering now...."
			sudo svm recover /var/lib/docker /dev/sdb1
			sleep 5
			#Need to start the service if the disk has been recovered
			sudo systemctl restart svmd
			sleep 5
	fi
fi



#Set the docker image location to the encrypted disk (Should be done using docker env variables, but this hack works
#if ! [ -L /var/lib/docker ]
#then
#	sudo ln -s /mnt/datadisk /var/lib/docker
#fi

echo "Running Docker Test"
docker run hello-world

