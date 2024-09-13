# Offline_RepoUpdate
Purpose: This script automates the process of updating an offline (air-gapped) repository and sending updates to other RHEL (or similar distro) machines within a closed-network utilizing ansible.

Preparation:
- Ensure to follow the README-prep instructions to prepare your environment. 

Contents:
1. Log creation in /var/log/
2. Inbox creation '$HOME/inbox'(if it does not exist). This directory is where repo-update zip files will be staged for extracting.
3. Repo directory creation.
4. Extract from inbox to new repo directory.
5. Format directory to contain only '.rpm' files.
6. Update the 'offline.repo.client' file to contain the new repo directory location.
7. Execute the 'update.yml' script using Ansible. This will ssh into all other clients in the 'inventory.ini' file, mount to your offline repo, copy the 'offline.repo.client' file, and run yum clean/update.
8. As is echo'ed, if everything ran smoothly, remove all files in the '$HOME/inbox/' directory to prepare for your next updates.
