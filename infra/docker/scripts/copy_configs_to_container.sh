#!/bin/bash

# Script to copy tmux and Claude configurations to Docker container
# Usage: ./copy_configs_to_container.sh

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}Copy Configurations to Container Script${NC}"
echo -e "${CYAN}========================================${NC}"

# Function to list running containers and let user select
select_container() {
    echo -e "\n${YELLOW}Fetching running containers...${NC}\n"
    
    # Get list of running containers
    containers=($(docker ps --format '{{.Names}}'))
    
    if [ ${#containers[@]} -eq 0 ]; then
        echo -e "${RED}No running containers found!${NC}"
        echo -e "${YELLOW}Please start a container first.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Running containers:${NC}"
    echo -e "${BLUE}-------------------${NC}"
    
    # Display containers with numbers
    for i in "${!containers[@]}"; do
        # Get additional info about the container
        image=$(docker ps --filter "name=${containers[$i]}" --format '{{.Image}}')
        ports=$(docker ps --filter "name=${containers[$i]}" --format '{{.Ports}}' | sed 's/,/, /g' | cut -c1-50)
        
        echo -e "${GREEN}[$((i+1))]${NC} ${CYAN}${containers[$i]}${NC}"
        echo -e "    Image: ${image}"
        [ ! -z "$ports" ] && echo -e "    Ports: ${ports}..."
        echo ""
    done
    
    # Get user selection
    while true; do
        echo -e "${YELLOW}Select container number (1-${#containers[@]}) or 'q' to quit: ${NC}"
        read -r selection
        
        if [[ "$selection" == "q" || "$selection" == "Q" ]]; then
            echo -e "${RED}Operation cancelled.${NC}"
            exit 0
        fi
        
        if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le "${#containers[@]}" ]; then
            CONTAINER_NAME="${containers[$((selection-1))]}"
            echo -e "\n${GREEN}Selected container: ${CYAN}${CONTAINER_NAME}${NC}"
            break
        else
            echo -e "${RED}Invalid selection. Please try again.${NC}"
        fi
    done
}

# Function to check container user
check_container_user() {
    # Try to detect if container uses root or another user
    local test_user=$(docker exec "${CONTAINER_NAME}" whoami 2>/dev/null || echo "root")
    
    if [ "$test_user" != "root" ]; then
        echo -e "${YELLOW}Container is running as user: ${test_user}${NC}"
        echo -e "${YELLOW}Do you want to copy to user's home directory instead of /root? (y/n): ${NC}"
        read -r use_user_home
        
        if [[ "$use_user_home" == "y" || "$use_user_home" == "Y" ]]; then
            USER_HOME=$(docker exec "${CONTAINER_NAME}" sh -c 'echo $HOME')
            echo -e "${GREEN}Using home directory: ${USER_HOME}${NC}"
        else
            USER_HOME="/root"
        fi
    else
        USER_HOME="/root"
    fi
}

# Function to copy file to container
copy_file_to_container() {
    local source_file="$1"
    local dest_file="$2"
    local description="$3"
    
    if [ -f "$source_file" ]; then
        echo -e "  ${CYAN}→${NC} ${description}"
        docker cp "$source_file" "${CONTAINER_NAME}:${dest_file}"
        echo -e "    ${GREEN}✓ Copied$(basename $source_file)${NC}"
    else
        echo -e "  ${RED}✗ Not found: $source_file${NC}"
    fi
}

# Function to copy directory to container
copy_dir_to_container() {
    local source_dir="$1"
    local dest_path="$2"
    local description="$3"
    
    if [ -d "$source_dir" ]; then
        echo -e "  ${CYAN}→${NC} ${description}"
        
        # Create parent directory in container first
        docker exec "${CONTAINER_NAME}" mkdir -p "$(dirname $dest_path)" 2>/dev/null || true
        
        # Copy the directory
        docker cp "$source_dir" "${CONTAINER_NAME}:${dest_path}"
        
        # Count files copied
        file_count=$(find "$source_dir" -type f | wc -l)
        echo -e "    ${GREEN}✓ Copied ${file_count} files${NC}"
    else
        echo -e "  ${RED}✗ Not found: $source_dir${NC}"
    fi
}

# Main execution starts here
select_container
check_container_user

echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}Starting configuration copy...${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Ask what to copy
echo -e "${YELLOW}What would you like to copy?${NC}"
echo -e "${GREEN}[1]${NC} Both tmux and Claude configurations"
echo -e "${GREEN}[2]${NC} Only tmux configurations"
echo -e "${GREEN}[3]${NC} Only Claude configurations"
echo -e "${GREEN}[q]${NC} Quit"
echo ""
read -r copy_choice

case $copy_choice in
    1)
        copy_tmux=true
        copy_claude=true
        ;;
    2)
        copy_tmux=true
        copy_claude=false
        ;;
    3)
        copy_tmux=false
        copy_claude=true
        ;;
    q|Q)
        echo -e "${RED}Operation cancelled.${NC}"
        exit 0
        ;;
    *)
        echo -e "${RED}Invalid choice. Copying both configurations.${NC}"
        copy_tmux=true
        copy_claude=true
        ;;
esac

# Copy tmux configurations
if [ "$copy_tmux" = true ]; then
    echo -e "\n${GREEN}[1/3] Copying tmux configurations${NC}"
    copy_file_to_container "$HOME/.tmux.conf" "${USER_HOME}/.tmux.conf" "tmux config"
    copy_file_to_container "$HOME/.tmux-cheatsheet.md" "${USER_HOME}/.tmux-cheatsheet.md" "tmux cheatsheet"
    copy_file_to_container "$HOME/.tmux_term_fix" "${USER_HOME}/.tmux_term_fix" "tmux term fix"
fi

# Copy Claude configurations
if [ "$copy_claude" = true ]; then
    echo -e "\n${GREEN}[2/3] Copying Claude configurations${NC}"
    copy_dir_to_container "$HOME/.claude" "${USER_HOME}/.claude" "Claude config directory"
    copy_file_to_container "$HOME/.claude.json" "${USER_HOME}/.claude.json" "Claude JSON config"
    copy_file_to_container "$HOME/.claude.json.backup" "${USER_HOME}/.claude.json.backup" "Claude JSON backup"
fi

# Set proper permissions in container
echo -e "\n${GREEN}[3/3] Setting permissions...${NC}"
docker exec "${CONTAINER_NAME}" bash -c "
    # Set Claude permissions if copied
    if [ -d '${USER_HOME}/.claude' ]; then
        chmod 600 ${USER_HOME}/.claude/.credentials.json 2>/dev/null || true
        chmod 644 ${USER_HOME}/.claude/*.md 2>/dev/null || true
    fi
    
    # Set tmux permissions if copied
    if [ -f '${USER_HOME}/.tmux.conf' ]; then
        chmod 644 ${USER_HOME}/.tmux.conf 2>/dev/null || true
    fi
    
    # Set ownership if we're root
    if [ \$(whoami) = 'root' ] && [ '${USER_HOME}' = '/root' ]; then
        chown -R root:root ${USER_HOME}/.claude 2>/dev/null || true
        chown root:root ${USER_HOME}/.tmux* 2>/dev/null || true
    fi
"
echo -e "  ${GREEN}✓ Permissions set${NC}"

# Install tmux in container if requested and not already installed
if [ "$copy_tmux" = true ]; then
    echo -e "\n${YELLOW}Checking tmux installation...${NC}"
    if ! docker exec "${CONTAINER_NAME}" which tmux > /dev/null 2>&1; then
        echo -e "${YELLOW}tmux is not installed. Install it? (y/n): ${NC}"
        read -r install_tmux
        
        if [[ "$install_tmux" == "y" || "$install_tmux" == "Y" ]]; then
            echo -e "${YELLOW}Installing tmux...${NC}"
            docker exec "${CONTAINER_NAME}" bash -c "
                if command -v apt-get > /dev/null; then
                    apt-get update && apt-get install -y tmux
                elif command -v yum > /dev/null; then
                    yum install -y tmux
                elif command -v apk > /dev/null; then
                    apk add --no-cache tmux
                else
                    echo 'Package manager not recognized'
                    exit 1
                fi
            "
            echo -e "  ${GREEN}✓ tmux installed${NC}"
        fi
    else
        echo -e "  ${GREEN}✓ tmux already installed${NC}"
    fi
fi

# Create and run validation script
echo -e "\n${YELLOW}Validating configuration...${NC}"
docker exec "${CONTAINER_NAME}" bash -c "cat > /tmp/validate_configs.sh << 'EOF'
#!/bin/bash
echo ''
echo '==== Configuration Status ===='
echo ''

if [ -f '${USER_HOME}/.tmux.conf' ]; then
    echo '✓ Tmux configuration:'
    ls -la ${USER_HOME}/.tmux* 2>/dev/null | grep -E '\.tmux'
    echo ''
fi

if [ -d '${USER_HOME}/.claude' ]; then
    echo '✓ Claude configuration:'
    echo '  Directory: ${USER_HOME}/.claude/'
    file_count=\$(find ${USER_HOME}/.claude -type f 2>/dev/null | wc -l)
    echo '  Files: '\$file_count' files'
    echo ''
fi

if command -v tmux > /dev/null 2>&1; then
    echo '✓ Tmux version:' \$(tmux -V)
else
    echo '✗ Tmux: not installed'
fi

echo ''
echo '==== Validation Complete ===='
EOF
chmod +x /tmp/validate_configs.sh
/tmp/validate_configs.sh
rm /tmp/validate_configs.sh
"

echo -e "\n${CYAN}========================================${NC}"
echo -e "${GREEN}✓ Configuration copy completed!${NC}"
echo -e "${CYAN}========================================${NC}"
echo -e "\n${YELLOW}To enter the container:${NC}"
echo -e "  ${GREEN}With tmux:${NC} docker exec -it ${CONTAINER_NAME} tmux"
echo -e "  ${GREEN}With bash:${NC} docker exec -it ${CONTAINER_NAME} bash"

if [ "$copy_claude" = true ]; then
    echo -e "\n${YELLOW}Note:${NC} Claude configurations are copied."
    echo -e "      Install Claude CLI separately if needed."
fi