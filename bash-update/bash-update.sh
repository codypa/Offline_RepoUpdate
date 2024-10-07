#!/bin/bash

###### CREATED BY CODY PASCUAL ######

# Check if the script is running with root privileges
if [ "$EUID" -ne 0 ]; then
  echo "This script must be run with sudo access."
  echo "Please run it as root"
  exit 1
fi

#Functions:
cleanup() {
	rm -rf $newRepo
	echo "Finished cleaning up." | tee -a $logFile
}

#Color variables:

RED="\033[0;31m"
GREEN="\033[0;32m"
RESET="\033[0m"

#Log creation
if [ ! -f /var/log/repoUpdate.log ]; then
	mkdir -p /var/log/repoUpdate.log
fi
logFile=/var/log/repoUpdate.log
DATE=$(date '+%Y-%m-%d %H:%M:%S')
echo "========== $DATE : New repo script executed ==========" >> $logFile

#Environment prep
if [ ! -d $HOME/inbox ]; then
	mkdir -p "$HOME/inbox"
	echo -e "${RED}The '$HOME/inbox' directory has been created but did not previously exist. Zip files must be re-imported into the '$HOME/inbox' directory and this script must be run again.${RESET}" | tee -a $logFile
	exit 1
fi

zipLocation="$HOME/inbox"

#Script begin:

read -p "Enter your repository name (e.g. September2024): " repoName

if [ ! -d "/repositories/rhel/" ]; then
	mkdir /repositories/rhel/
	echo -e "${GREEN}Created /repository/rhel/ directory.${RESET}" | tee -a $logFile
fi

if [ -d $newRepo ]; then
	echo -e "${RED}Repository name already exists.. Exiting..${RESET}" | tee -a $logFile
	exit 1
else
	newRepo="/repositories/rhel/$repoName"
fi

#1. Create new repo directory
mkdir -p /repositories/rhel/$repoName
echo -e "${GREEN}Created $repoName in '/repositories/rhel/'${RESET}" | tee -a $logFile

#2. Unzip patches to new directory
for zipFile in "$zipLocation"/*.zip; do
    # Check if the file exists and is a file
    if [ -f "$zipFile" ]; then
    	# Test the zip file and unzip
        if zip -T "$zipFile" > /dev/null 2>&1; then
            echo "Unzipping '$zipFile' to '$newRepo'"
            unzip "$zipFile" -d "$newRepo" >> /dev/null 2>&1
            echo -e "${GREEN}Finished unzipping '$zipFile'.${RESET}" | tee -a $logFile
        else
            echo -e "${RED}Zip file '$zipFile' is either corrupted or does not exist. Exiting.. ${RESET}" | tee -a $logFile 
			cleanup
			exit 1
        fi
    else
        echo -e "${RED}No zip files found in $zipLocation. Exiting.. ${RESET}" | tee -a $logFile
		cleanup
		exit 1
	fi
done
	
#Verify directory is populated. If not, trigger cleanup.

if [ ! "$(ls -A $newRepo)" ]; then
	echo -e "${RED}$newRepo is empty. Cleaning up.${RESET}" | tee -a $logFile
	cleanup
	exit 1
fi

#3. Move all files within the newly unzipped folders to its parent directory. Then delete the empty subdirectories.
find "$newRepo" -mindepth 2 -type f -exec mv {} "$newRepo" \;
find "$newRepo" -mindepth 1 -type d -empty -delete
echo -e "${GREEN}Prepared repository directory for repo creation.${RESET}" | tee -a $logFile

#4. Create repodata in new repo directory
echo -e "${RESET}Generating repodata..." | tee -a $logFile
createrepo --update --workers 16 $newRepo | tee -a $logFile

#5. Append the new repository information to the 'offline.repo.client' file
{
	echo ""
	echo "[$repoName]"
	echo "name=$repoName"
	echo "baseurl=file:///mnt/rhel/$repoName"
	echo "enabled=1"
	echo "gpgcheck=0"
	echo "module_hotfixes=1"
} >> /repositories/offline.repo.client
echo -e "${GREEN}Finished appending to 'offline.repo.client' file.${RESET}" | tee -a $logFile

#6.Mount, copy, clean, and update. Ssh-copy-id must be run beforehand on all hosts in order for this to be without prompt. Change repo hostname (nfs01) to your own.

for host in $(cat /repositories/Cscripts/updateinventory); do
	echo "Configuring and updating $host"
	ssh username@$host >> $logFile 2>&1 << EOF
		mount nfs01:/repositories /mnt
		/usr/bin/cp -f /mnt/offline.repo.client /etc/yum.repos.d/offline.repo
		yum clean all
		yum update --allowerasing --nobest -y
EOF
	echo -e "$(GREEN)Completed configuring and updating $host.$(RESET)"
done

#7 Finish
echo -e "${GREEN}Script complete.${RESET}"
echo "If complete without errors, please run 'rm -f $HOME/inbox' to clean up.
