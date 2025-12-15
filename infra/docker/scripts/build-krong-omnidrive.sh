#!/bin/bash

# =============================================================================
# Build and Run Script for Krong-OmniDrive Development Environment
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Krong-OmniDrive Development Environment${NC}"
echo -e "${GREEN}========================================${NC}"

# Change to the project root directory
cd /workspace/projects/vla

# Build the Docker image
echo -e "\n${YELLOW}Building Krong-OmniDrive Docker image...${NC}"
docker-compose -f infra/docker/docker-compose.yaml build krong-omnidrive-cu118-2508

# Check if build was successful
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Build completed successfully!${NC}"
else
    echo -e "${RED}✗ Build failed!${NC}"
    exit 1
fi

# Start the container
echo -e "\n${YELLOW}Starting Krong-OmniDrive container...${NC}"
docker-compose -f infra/docker/docker-compose.yaml up -d krong-omnidrive-cu118-2508

# Check if container started successfully
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Container started successfully!${NC}"
    
    echo -e "\n${GREEN}Available Services:${NC}"
    echo "  • Jupyter Lab: http://localhost:8890"
    echo "  • TensorBoard: http://localhost:6007"
    echo "  • MLflow: http://localhost:5000"
    echo "  • FastAPI: http://localhost:8002"
    echo "  • Code Server: http://localhost:8081"
    echo "  • SSH: ssh -p 1112 root@localhost"
    echo "  • Kafka: localhost:9092"
    echo "  • Redis: localhost:6379"
    echo "  • Prometheus: http://localhost:9090"
    echo "  • Grafana: http://localhost:3000"
    echo "  • Dash: http://localhost:8050"
    echo "  • Streamlit: http://localhost:8501"
    
    echo -e "\n${GREEN}To enter the container:${NC}"
    echo "  docker exec -it krong-omnidrive-cu118-2508 bash"
    
    echo -e "\n${GREEN}To stop the container:${NC}"
    echo "  docker-compose -f infra/docker/docker-compose.yaml stop krong-omnidrive-cu118-2508"
else
    echo -e "${RED}✗ Failed to start container!${NC}"
    exit 1
fi