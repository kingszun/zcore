#!/bin/bash

# Docker + NVIDIA GPU Support Installation Script
# Ubuntu 24.04 LTS

set -e  # Exit on any error

echo "=== Docker + NVIDIA GPU Support Installation ==="
echo "Ubuntu $(lsb_release -rs) detected"
echo ""

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo "This script should not be run as root. Please run as regular user with sudo access."
   exit 1
fi

# Check NVIDIA GPU
echo "Checking NVIDIA GPU..."
if ! command -v nvidia-smi &> /dev/null; then
    echo "ERROR: nvidia-smi not found. Please install NVIDIA drivers first."
    exit 1
fi
nvidia-smi
echo ""

# 1. System Update
echo "1. Updating system packages..."
sudo apt update
sudo apt upgrade -y

# 2. Install Docker Engine
echo ""
echo "2. Installing Docker Engine..."

# Remove old versions if any
sudo apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

# Install prerequisites
sudo apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# 3. Install NVIDIA Container Toolkit
echo ""
echo "3. Installing NVIDIA Container Toolkit..."

# Configure the production repository
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

# Install NVIDIA Container Toolkit
sudo apt update
sudo apt install -y nvidia-container-toolkit

# Configure Docker daemon
echo ""
echo "4. Configuring Docker for NVIDIA runtime..."
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker

# 5. User Configuration
echo ""
echo "5. Adding user to docker group..."
sudo usermod -aG docker $USER
newgrp docker
sudo chown $USER: /var/run/docker.sock

# 6. Enable Docker service
echo ""
echo "6. Enabling Docker service..."
sudo systemctl enable docker
sudo systemctl start docker

# 7. Installation Tests
echo ""
echo "7. Testing Docker installation..."
echo "Docker version:"
docker --version
echo ""
echo "Docker Compose version:"
docker compose version
echo ""

echo "Testing basic Docker functionality..."
if docker run --rm hello-world; then
    echo "✓ Docker basic test passed"
else
    echo "✗ Docker basic test failed"
    exit 1
fi

echo ""
echo "Testing NVIDIA GPU support..."
if docker run --rm --gpus all nvidia/cuda:12.2-base-ubuntu20.04 nvidia-smi; then
    echo "✓ NVIDIA GPU support test passed"
else
    echo "✗ NVIDIA GPU support test failed"
    echo "Note: You may need to log out and log back in for group changes to take effect"
fi

echo ""
echo "=== Installation Complete! ==="
echo ""
echo "Important Notes:"
echo "1. Log out and log back in (or run 'newgrp docker') to apply group changes"
echo "2. Test GPU support with: docker run --rm --gpus all nvidia/cuda:12.2-base-ubuntu20.04 nvidia-smi"
echo "3. Docker Compose is available as 'docker compose' (not docker-compose)"
echo ""
echo "Common Docker + GPU commands:"
echo "- docker run --gpus all <image>     # Use all GPUs"
echo "- docker run --gpus 1 <image>       # Use 1 GPU"
echo "- docker compose up                 # Run docker-compose.yml"
echo "- docker images                     # List images"
echo "- docker ps                         # List running containers"