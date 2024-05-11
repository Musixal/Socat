#!/bin/bash

# Logo
show_logo() {
echo -e "${BLUE}"
cat << "EOF"
 ___  _____  ___    __   ____ 
/ __)(  _  )/ __)  /__\ (_  _)
\__ \ )(_)(( (__  /(__)\  )(  
(___/(_____)\___)(__)(__)(__) 
         by github.com/Musixal
EOF
  echo -e "${NC}"
}

# Check if the script is being run as root
if [ "$(id -u)" != "0" ]; then
    echo -e "${RED}This script must be run as root${NC}" 1>&2
    read -p "Press any key to continue..."
    exit 1
fi


# Check if socat is installed
if ! command -v socat &> /dev/null; then
    echo -e "${YELLOW}socat is not installed. Attempting to install...${NC}"
    
    # Check if the system is using apt package manager
    if command -v apt-get &> /dev/null; then
        sudo apt-get update
        sudo apt-get install -y socat
    else
        echo -e "${RED}Error: Unsupported package manager. Please install socat manually.${NC}"
        read -p "Press any key to continue..."
        exit 1
    fi
    
    # Check if socat installation was successful
    if ! command -v socat &> /dev/null; then
        echo -e "${RED}Error: socat installation failed. Please install socat manually.${NC}"
        read -p "Press any key to continue..."
        exit 1
    fi
fi


configure_socat_service() {
service="/etc/systemd/system/socat.service"
# Check if socat.service exists
if [ -f "$service" ]; then
    # Ask user for confirmation
    read -p "socat.service exists. Do you want to delete it? (y/n): " confirm
    if [ "$confirm" = "y" ]; then
        echo -e "${YELLOW}Deleting socat.service...${NC}"
        sudo rm /etc/systemd/system/socat.service
        sudo systemctl disable socat.service
        sudo systemctl stop socat.service
        echo -e "${YELLOW}socat.service deleted.${NC}"
    else
        echo -e "${RED}Deletion canceled.${NC}"
        read -p "Press any key to continue..."
        return 1
    fi
fi

# Prompt the user to enter the port to listen on
read -p "Enter the port to listen on: " listen_port

# Prompt the user to enter the destination IP address
read -p "Enter the destination IP address (Kharej): " dest_ip

# Prompt the user to enter the destination port
read -p "Enter the destination port: " dest_port


    cat << EOF > "$service"
[Unit]
Description=Socat Tunnel Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/socat TCP-LISTEN:${listen_port},reuseaddr,fork TCP:${dest_ip}:${dest_port}
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd to load the new service unit
sudo systemctl daemon-reload

# Enable and start the service
sudo systemctl enable socat.service
sudo systemctl start socat.service

echo -e "${GREEN}Socat service created and started successfully${NC}"
read -p "Press any key to continue..."
}

remove_socat_service() {
    # Check if socat.service exists
    if [ ! -f "/etc/systemd/system/socat.service" ]; then
        echo -e "${RED}Error: socat.service does not exist.${NC}"
        read -p "Press any key to continue..."
        return 1
    fi

    # Check if socat.service is active
    if systemctl is-active --quiet socat.service; then
        # Stop the service if it is active
        sudo systemctl stop socat.service
        echo -e "${YELLOW}socat.service stopped.${NC}"
    fi

    # Disable the service
    sudo systemctl disable socat.service >/dev/null 2>&1

    # Delete the service unit file
    sudo rm "/etc/systemd/system/socat.service"

    # Reload systemd to apply changes
    sudo systemctl daemon-reload

    echo -e "${GREEN}Socat service stopped and deleted successfully.${NC}"
    read -p "Press any key to continue..."
}

check_socat_service_status() {
    # Check if socat.service exists
    if [ ! -f "/etc/systemd/system/socat.service" ]; then
        echo -e "${RED}Error: socat.service does not exist.${NC}"
        read -p "Press any key to continue..."
        return 1
    fi

    # Display status of socat.service
    sudo systemctl status socat.service
    read -p "Press any key to continue..."
}


restart_socat_service() {
    # Check if socat.service exists
    if [ ! -f "/etc/systemd/system/socat.service" ]; then
        echo -e "${RED}Error: socat.service does not exist.${NC}"
        read -p "Press any key to continue..."
        return 1
    fi

    # Restart socat.service
    sudo systemctl restart socat.service
    echo -e "${YELLOW}socat.service restarted.${NC}"
    read -p "Press any key to continue..."
}

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to display menu
display_menu(){
    clear
    show_logo
    echo "Menu:"
    echo -e "${GREEN}1. Tunnel Configure${NC}"
    echo -e "${BLUE}2. Check Status${NC}"
    echo -e "${YELLOW}3. Restart Socat Service${NC}"
    echo -e "${RD}4. Destroy Tunnel ${NC}"
    echo "5. Exit"
    echo "-------------------------------"
  }
# Function to read user input
read_option(){
    read -p "Enter your choice: " choice
    case $choice in
        1) configure_socat_service ;;
        2) check_socat_service_status ;;
        3) restart_socat_service ;;
        4) remove_socat_service ;;
        5) echo "Exiting..." && break ;;
        *) echo -e "${RED}Invalid option!${NC}" && sleep 1 ;;
    esac
}

# Main loop
while true
 do
    display_menu
    read_option
done
