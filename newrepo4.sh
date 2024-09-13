#!/bin/bash

###### CREATED BY CODY PASCUAL ######

logFile=/var/log/update.log
zipLocation=/home/cpaco/inbox 

#Color variables:

RED="\033[0;31m"
GREEN="\033[0;32m"
RESET="\033[0m"

cleanup() {
	rm -rf $newRepo
	echo "Finished cleaning up."
}

read -p "Enter your repository name (e.g. September2024): " repoName

newRepo="/repositories/rhel8/$repoName"

if [ -d $newRepo ]; then
	echo -e "${RED}Repository name already exists.. Exiting..${RESET}"
	exit 1
fi

#1. Create new repo directory
mkdir -p /repositories/rhel8/$repoName
echo -e "${GREEN}Created $repoName in '/repositories/rhel8/'${RESET}"	

#2. Unzip patches to new directory
for zipFile in "$zipLocation"/*.zip; do
    # Check if the file exists and is a file
    if [ -f "$zipFile" ]; then
    	# Test the zip file
        if zip -T "$zipFile" > /dev/null 2>&1; then
            echo "Unzipping '$zipFile' to '$newRepo'"
            unzip "$zipFile" -d "$newRepo" >> "$logFile" 2>&1
            echo -e "${GREEN}Finished unzipping '$zipFile'.${RESET}"
        else
            echo -e "${RED}Zip file '$zipFile' is either corrupted or does not exist.${RESET}"
			cleanup
			exit 1
        fi
    else
        echo -e "${RED}No zip files found in $zipLocation.${RESET}"
		cleanup
		exit 1
	fi
done
	
#Verify directory is populated. If not trigger cleanup.

if [ "$(ls -A $newRepo)" ]; then
	echo "Directory is populated. Continuing..."
else
	echo -e "${RED}$newRepo is empty. Cleaning up.${RESET}"
	cleanup
	exit 1
fi

#3. Move all files within the newly unzipped folders to its parent directory. Then delete the empty subdirectories.
find "$newRepo" -mindepth 2 -type f -exec mv {} "$newRepo" \;
find "$newRepo" -mindepth 1 -type d -empty -delete
echo -e "${GREEN}Formatted repository directory.${RESET}"

#4. Create repodata in new repo directory
echo -e "${RESET}Generating repodata..."
createrepo --update --workers 16 $newRepo

#5. Append the new repository to the 'offline.repo.client' directory
{
	echo ""
	echo "[$repoName]"
	echo "name=$repoName"
	echo "baseurl=file:///mnt/rhel8/$repoName"
	echo "enabled=1"
	echo "gpgcheck=0"
	echo "module_hotfixes=1"
} >> /repositories/offline.repo.client
echo -e "${GREEN}Finished appending to 'offline.repo.client' file.${RESET}"

#6.Copy, clean, update

ansible-playbook -i inventory.ini playbooks/rupdate.yml -K
