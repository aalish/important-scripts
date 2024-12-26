#!/bin/bash

# Import the color palette
source ./colors.sh

# Check if the script is run as root
if [ "$(id -u)" -ne 0 ]; then
  echo -e "${RED}Error: Please run this script as root or using sudo.${RESET}"
  exit 1
fi

# Variables
NODE_EXPORTER_VERSION="1.6.1"
DOWNLOAD_URL="https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz"
INSTALL_DIR="/usr/local/bin"
SERVICE_FILE="/etc/systemd/system/node_exporter.service"

# Step 1: Download Node Exporter
echo -e "${CYAN}Step 1:${RESET} Downloading Node Exporter v${YELLOW}${NODE_EXPORTER_VERSION}${RESET}..."
wget -q $DOWNLOAD_URL -O /tmp/node_exporter.tar.gz
if [ $? -eq 0 ]; then
  echo -e "${GREEN}Downloaded Node Exporter successfully.${RESET}"
else
  echo -e "${RED}Error: Failed to download Node Exporter.${RESET}"
  exit 1
fi

# Step 2: Extract Node Exporter
echo -e "${CYAN}Step 2:${RESET} Extracting Node Exporter..."
tar -xzf /tmp/node_exporter.tar.gz -C /tmp
if [ $? -eq 0 ]; then
  echo -e "${GREEN}Node Exporter extracted successfully.${RESET}"
else
  echo -e "${RED}Error: Failed to extract Node Exporter.${RESET}"
  exit 1
fi

# Step 3: Move the binary to the installation directory
echo -e "${CYAN}Step 3:${RESET} Moving Node Exporter binary to ${YELLOW}${INSTALL_DIR}${RESET}..."
mv /tmp/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter $INSTALL_DIR
if [ $? -eq 0 ]; then
  echo -e "${GREEN}Node Exporter binary moved successfully.${RESET}"
else
  echo -e "${RED}Error: Failed to move Node Exporter binary.${RESET}"
  exit 1
fi

# Step 4: Create a systemd service file
echo -e "${CYAN}Step 4:${RESET} Creating a systemd service file..."
cat <<EOL > $SERVICE_FILE
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=${INSTALL_DIR}/node_exporter
Restart=always

[Install]
WantedBy=multi-user.target
EOL

if [ $? -eq 0 ]; then
  echo -e "${GREEN}Systemd service file created successfully.${RESET}"
else
  echo -e "${RED}Error: Failed to create systemd service file.${RESET}"
  exit 1
fi

# Step 5: Create a user for Node Exporter
echo -e "${CYAN}Step 5:${RESET} Creating a dedicated user for Node Exporter..."
useradd -r -s /bin/false node_exporter
if [ $? -eq 0 ]; then
  echo -e "${GREEN}User created successfully.${RESET}"
else
  echo -e "${YELLOW}User already exists or failed to create.${RESET}"
fi

# Step 6: Reload systemd and enable the service
echo -e "${CYAN}Step 6:${RESET} Reloading systemd and enabling the Node Exporter service..."
systemctl daemon-reload
systemctl enable node_exporter
if [ $? -eq 0 ]; then
  echo -e "${GREEN}Node Exporter service enabled successfully.${RESET}"
else
  echo -e "${RED}Error: Failed to enable Node Exporter service.${RESET}"
  exit 1
fi

# Step 7: Start the service
echo -e "${CYAN}Step 7:${RESET} Starting the Node Exporter service..."
systemctl start node_exporter
if [ $? -eq 0 ]; then
  echo -e "${GREEN}Node Exporter service started successfully.${RESET}"
else
  echo -e "${RED}Error: Failed to start Node Exporter service.${RESET}"
  exit 1
fi

# Step 8: Check the service status
echo -e "${CYAN}Step 8:${RESET} Checking the Node Exporter service status..."
systemctl status node_exporter --no-pager
if [ $? -eq 0 ]; then
  echo -e "${GREEN}Node Exporter is running successfully.${RESET}"
else
  echo -e "${RED}Error: Node Exporter service is not running.${RESET}"
fi

# Cleanup
echo -e "${CYAN}Cleanup:${RESET} Removing temporary files..."
rm -rf /tmp/node_exporter*

echo -e "${BOLD_GREEN}Node Exporter installation and configuration completed successfully.${RESET}"
