#!/bin/bash

#automation.sh
#BASH Script for:-
#1. Hosting Web Server
#2. Archiving Logs
#3. Bookkeeping of archived files
#4. Cron Job for execution of the script

#Declaring variables
name="Rakesh"
s3_bucket="upgrad-rakesh"
inventoryFile="/var/www/html/inventory.html"
cronJobFile="/etc/cron.d/automation"
automationScriptFile="/root/Automation_Project/automation.sh"

#Script updates the package information
echo "APT Update In-progress...!!!"
sudo apt -y update

#Script ensures that the HTTP Apache server is installed
if [ "dpkg-query -W apache2 | awk {'print $1'} = "apache2"" ]; then
    echo "Apache2 is already installed...!!!"
else
    echo "Installing Apache2...!!!"
    sudo apt-get -y install apache2
fi

#Script ensures that HTTP Apache server is running
if systemctl is-active apache2 --quiet; then
    echo "Apache2 is already running...!!!"
else
    echo "Starting Apache2 Service...!!!"
    sudo service apache2 start
fi

#Script ensures that HTTP Apache service is enabled
apacheService=`service apache2 status | grep 'apache2.service; enabled' | wc -l`
if [ $apacheService -eq 1 ]; then
    echo "Apache2 Service is already enabled...!!!"
else
    echo "Enabling Apache2 Service...!!!"
    sudo systemctl enable apache2
fi

#Archiving logs to S3
echo "TAR Apache2 Logs...!!!"
timestamp=$(date '+%m%d%Y-%H%M%S')
tarFileName=$name-httpd-logs-$timestamp.tar
cd /var/log/apache2/
sudo tar -cvf /tmp/$tarFileName *.log
echo "Copy Apache2 Logs TAR to S3 Bucket...!!!"
aws s3 cp /tmp/$tarFileName s3://${s3_bucket}/$tarFileName

#Bookkeeping
sizeOfTAR=`ls /tmp/$tarFileName -sh | awk {'print $1'}`
if [ -f "$inventoryFile" ]; then
    echo "$inventoryFile already exists...!!!"
else
    echo "Creating $inventoryFile file...!!!"
    touch $inventoryFile
    echo -e 'Log Type\tDate Created\t\tType\tSize' >> $inventoryFile
fi
echo "Adding record to inventory...!!!"
echo -e 'httpd-logs\t'$timestamp'\t\ttar\t'$sizeOfTAR >> $inventoryFile

#Cron Job
if [ -f "$cronJobFile" ]; then
    echo "$cronJobFile already exists...!!!"
else
    echo "Creating $cronJobFile file...!!!"
    touch $cronJobFile
    echo "Setting CRON Job to run every day...!!!"
    echo '0 0 * * * root '$automationScriptFile >> $cronJobFile
fi
