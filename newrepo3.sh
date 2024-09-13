#!/bin/bash

###### CREATED BY CODY PASCUAL ######

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
fi

#1. Create new repo directory
mkdir -p /repositories/rhel8/$repoName
echo -e "${GREEN}Created $repoName in '/repositories/rhel8/'${RESET}"
	
#2. Unzip patches to new directory
while true; do
	read -p "Enter the path to your repository .zip file: " zipLocation
	#Zip test before extraction
	if zip -T $zipLocation; then
		echo "Unzipping to '$newRepo'"
		unzip $zipLocation -d $newRepo
		echo -e "${GREEN}Finished unzipping.${RESET}"
	else
		echo -e "${RED}Zip file is either corrupted or does not exist.${RESET}"
	fi
	
	read -p "Do you have more repository .zip files? (y/n): " answer
	if [[ $answer != "y" ]]; then
		break
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
echo -e "${GREEN}Formatted repository directory: $newRepo${RESET}"

#4. Create repodata in new repo directory
echo -e "${RESET}Generating repodata..."
createrepo --update --workers 16 $newRepo

#5. Append the new repository to the 'rand.repo.client' directory
{
	echo ""
	echo "[$repoName]"
	echo "name=$repoName"
	echo "baseurl=file:///mnt/rhel8/$repoName"
	echo "enabled=1"
	echo "gpgcheck=0"
	echo "module_hotfixes=1"
} >> /repositories/rand.repo.client
echo -e "${GREEN}Finished appending to 'rand.repo.client' file.${RESET}"

#6. Configure remote systems. Ssh-copy-id must be run prior in order for this to run without prompt.
for host in $(cat /repository/Cscripts/updateinventory); do
	echo "Configuring and updating $host"
	ssh root@$host > /dev/null 2>&1 << EOF
	mount smrepobox:/repositories /mnt
	cp /mnt/rand.repo.client /etc/yum.repos.d/rand.repo
	yum clean all
	yum update --allowerasing --nobest -y
EOF
	echo -e "${GREEN}Completed configuring and updating $host.${RESET}"
done

echo -e "${GREEN}Environment has been updated.${RESET}"