# Offline_RepoUpdate(INTRO)
Purpose: Automate the process of updating an offline (air-gapped) repository and sending updates to other RHEL (or similar distro) machines within a closed-network.

There are two different approaces to update your machines, depending on what you have in your environment:
1. Update using Ansible (/Offline_RepoUpdate/ansible-update/)
2. Update solely using Bash (/Offline_RepoUpdate/bash-update/)

- Within each of these directories, contained in the README files, there will be a (1)summarization of what is being done and (2) how to prep your environment for execution.
- Ensure to only follow one approach to avoid conflictions.

- This process assumes that you are copying contents in the format of a zipped folder. Due to being in an air-gapped network, and most likely in an environment where USB devices are not allowed, it is also assumed that the zipped content is being copied from limited storage DVD's. Thus the reason why there there will be an 'inbox' for content that has been securely copied and a loop to unzip all archives within the inbox.
