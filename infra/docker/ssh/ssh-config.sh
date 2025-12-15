#!/bin/bash

# SSH Configuration Setup Script
# This script configures SSH server settings during Docker image build

echo "=== Configuring SSH Server ==="

# Create SSH run directory
mkdir -p /var/run/sshd

# Configure SSH server settings
echo "Configuring SSH server settings..."

# Update SSH configuration
sed -i 's/#Port 22/Port 1111/' /etc/ssh/sshd_config
sed -i 's/Port 22/Port 1111/' /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config  
sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/#AuthorizedKeysFile/AuthorizedKeysFile/' /etc/ssh/sshd_config

# Set root password
echo 'root:1234' | chpasswd

# Create SSH directory and set permissions
mkdir -p /root/.ssh
chmod 700 /root/.ssh
touch /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys

# Add SSH public key to authorized_keys
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFsHx1t1jddGIGN/6nxp7upeHVQpM6DoxP5McpiNO3r0" >> /root/.ssh/authorized_keys

echo "✓ SSH server configured successfully"

# Display configuration summary
echo ""
echo "=== SSH Configuration Summary ==="
echo "Port: 1111"
echo "PermitRootLogin: yes"
echo "PasswordAuthentication: yes"
echo "PubkeyAuthentication: yes"
echo "Root Password: 1234"
echo ""
echo "=== SSH Directory Permissions ==="
ls -la /root/.ssh/
echo ""
echo "SSH configuration complete. Connect using: ssh root@<container-ip> -p 1111"