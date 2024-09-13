Purpose: Automate the process of updating an offline (air-gapped) repository and sending updates to other RHEL (or similar distro) machines within a closed-network.

There are two different approaces to update your machines, depending on what you have in your environment:
1. Update using Ansible (/Offline_RepoUpdate/ansible-update/)
2. Update solely using Bash (/Offline_RepoUpdate/bash-update/)

- Within each of these directories, contained in the README files, there will be a summarization of what is being done and how to prep your environment for execution.
- Ensure to only follow one approach to avoid conflictions.
