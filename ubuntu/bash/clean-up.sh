#!/bin/bash

# Define colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

# Check if the script is run as root
if [ "$(id -u)" -ne 0 ]; then
  echo -e "${RED}Error: This script must be run as root.${RESET}"
  exit 1
fi

# Function to cleanup swap
cleanup_swap() {
  echo -e "${CYAN}Cleaning up swap file...${RESET}"
  SWAP_FILE="/swapfile"
  if [ -f "$SWAP_FILE" ]; then
    swapoff "$SWAP_FILE"
    rm -f "$SWAP_FILE"
    sed -i '/\/swapfile/d' /etc/fstab
    echo -e "${GREEN}Swap file and related configurations removed.${RESET}"
  else
    echo -e "${YELLOW}No swap file found.${RESET}"
  fi
}

# Function to cleanup user
cleanup_user() {
  echo -e "${CYAN}Cleaning up user 'worker'...${RESET}"
  USER="worker"
  if id "$USER" &>/dev/null; then
    userdel -r "$USER"
    echo -e "${GREEN}User 'worker' and home directory removed.${RESET}"
  else
    echo -e "${YELLOW}User 'worker' not found.${RESET}"
  fi
}

# Function to cleanup OpenVPN
cleanup_openvpn() {
  echo -e "${CYAN}Cleaning up OpenVPN...${RESET}"
  apt purge -y openvpn easy-rsa
  rm -rf /etc/openvpn /usr/share/easy-rsa /var/log/openvpn
  sed -i '/net.ipv4.ip_forward=1/d' /etc/sysctl.conf
  sysctl -w net.ipv4.ip_forward=0
  echo -e "${GREEN}OpenVPN and associated configurations removed.${RESET}"
}

# Function to cleanup Node Exporter
cleanup_node_exporter() {
  echo -e "${CYAN}Cleaning up Node Exporter...${RESET}"
  NODE_EXPORTER_SERVICE="/etc/systemd/system/node_exporter.service"
  if [ -f "$NODE_EXPORTER_SERVICE" ]; then
    systemctl stop node_exporter
    systemctl disable node_exporter
    rm -f "$NODE_EXPORTER_SERVICE"
    rm -rf /usr/local/bin/node_exporter
    systemctl daemon-reload
    echo -e "${GREEN}Node Exporter and related files removed.${RESET}"
  else
    echo -e "${YELLOW}Node Exporter service not found.${RESET}"
  fi
}

# Function to cleanup SonarQube
cleanup_sonarqube() {
  echo -e "${CYAN}Cleaning up SonarQube...${RESET}"
  SONARQUBE_DIR="/opt/sonarqube"
  SONARQUBE_SERVICE="/etc/systemd/system/sonarqube.service"
  if [ -d "$SONARQUBE_DIR" ]; then
    systemctl stop sonarqube
    systemctl disable sonarqube
    rm -rf "$SONARQUBE_DIR"
    rm -f "$SONARQUBE_SERVICE"
    rm -f credentials.txt
    systemctl daemon-reload
    echo -e "${GREEN}SonarQube installation, service, and credentials removed.${RESET}"
  else
    echo -e "${YELLOW}SonarQube installation not found.${RESET}"
  fi
  echo -e "${CYAN}Cleaning up PostgreSQL database for SonarQube...${RESET}"
  sudo -i -u postgres psql -c "DROP DATABASE sonarqube;" &>/dev/null
  sudo -i -u postgres psql -c "DROP USER sonar;" &>/dev/null
  echo -e "${GREEN}PostgreSQL database and user for SonarQube removed.${RESET}"
}

# Main cleanup logic
if [ $# -ne 1 ]; then
  echo -e "${RED}Usage: $0 <swap|user|openvpn|node-exporter|sonarqube>${RESET}"
  exit 1
fi

case "$1" in
  swap)
    cleanup_swap
    ;;
  user)
    cleanup_user
    ;;
  openvpn)
    cleanup_openvpn
    ;;
  node-exporter)
    cleanup_node_exporter
    ;;
  sonarqube)
    cleanup_sonarqube
    ;;
  *)
    echo -e "${RED}Invalid argument. Use one of: swap, user, openvpn, node-exporter, sonarqube.${RESET}"
    exit 1
    ;;
esac
