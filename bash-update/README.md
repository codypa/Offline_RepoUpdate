# BASH-Update
Purpose: This script automates the process of updating an offline (air-gapped) repository and sending updates to other RHEL (or similar distro) machines within a closed-network, utilizing bash only.

Summary:

1. Log creation in /var/log/
2. Inbox creation '$HOME/inbox'(if it does not exist). This directory is where repo-update zip files will be staged for extracting.
3. Repo directory creation.
4. Extract from inbox to new repo directory.
5. Format directory to contain only '.rpm' files.
6. Update the 'offline.repo.client' file to contain the new repo directory location.
7. Loop through the updateinventory file to mount to the offline repo, copy the updated repo script, and yum clean/update.
8. As is echo'ed, if everything ran smoothly, remove all files in the '$HOME/inbox/' directory to prepare for your next updates.

# Preparation
- In order to update an offline server, you first need a server that is online with a subscription to sync from the Redhat Network(RHN). Server 1:
- Create a directory in your home directory named repositories: `mkdir /repositories`
- Create a cronjob to sync from the desired RepoID's every day to your '/repositories' directory. You can create this file in '/etc/cron.daily':
```bash
dnf reposync --repoid=rhel-8-for-x86_64-appstream-rpms -p /repositories/ --downloadcomps --download-metadata
dnf reposync --repoid=rhel-8-for-x86_64-baseos-rpms -p /repositories/ --downloadcomps --download-metadata
dnf reposync --repoid=rhel-8-for-x86_64-supplementary-rpms -p /repositories/ --downloadcomps --download-metadata
dnf reposync --repoid=epel -p /repositories/ --downloadcomps --download-metadata
```
- When it comes time to update systems in your offline network, you need to copy the latest RPM's to disc(s):
```bash
#Create a directory for outgoing RPMs
mkdir -p /home/outbox/rhel
month="CURRENT_MONTH-2024"
cd /repositories
#Find and copy latest RPM's to the outbox directory
find . -name '*.rpm' -newermt "01-$month -1 sec" -and -not -newermt "01-$month +1 month -1 sec" -exec cp -p {} /home/outbox/rhel \;
chown -R youruser:youruser /home/outbox
#The following is an example, given you have already mounted your disc.
scp -r /home/outbox/rhel /mnt/cdrom
cd /
umount /mnt/cdrom
```
- Next, will be configuring your offline repository. Server 2:
- Create an inbox for incoming patches: `mkdir $HOME/inbox`
- Create a file (/repositories/Cscripts/updateinventory) containing the FQDN's of other hosts:
```bash
host01.lab.com
host02.lab.com
host03.lab.com
```
- Make your offline repo server mountable by also making it an NFS server:
```bash
dnf install nfs-utils -y
chown -R nfsnobody:nfsnobody /repositories
chmod -R 755 /repositories
vim /etc/exports
```
- Follow this configuration for the 'exports' file:
```bash
/repositories *(rw,sync,no_root_squash,no_all_squash)
```
- Apply changes:
```bash
exportfs -a
systemctl start nfs-server
systemctl enable nfs-server
systemctl start rpcbind
systemctl enable rpcbind
```
- Configure firewall:
```bash
firewall-cmd --permanent --add-service=nfs
firewall-cmd --permanent --add-service=rpc-bind
firewall-cmd --permanent --add-service=mountd
firewall-cmd --reload
```
- Other hosts will need to install nfs-utils in order to mount, if not already installed: `dnf install nfs-utils -y`
- From here, you should be ready to launch the script. Enjoy.
