#!/bin/bash

# Start SSH server
# Port 1111 is already configured in /etc/ssh/sshd_config by ssh-config.sh
echo "Starting SSH server on port 1111..."
/usr/sbin/sshd -D

# This script will keep running as sshd runs in foreground mode (-D) 