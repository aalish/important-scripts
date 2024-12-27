#!/bin/bash

# Define colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
  echo -e "${RED}Error: This script must be run as root.${RESET}"
  exit 1
fi

# Variables
SONARQUBE_VERSION="24.12.0.100206"
SONARQUBE_ZIP="sonarqube-${SONARQUBE_VERSION}.zip"
SONARQUBE_URL="https://binaries.sonarsource.com/Distribution/sonarqube/${SONARQUBE_ZIP}"
SONARQUBE_DIR="/opt/sonarqube"
DB_NAME="sonarqube"
DB_USER="sonar"
DB_PASS=$(openssl rand -base64 16)  # Generate a random password
SYS_USER="sonarqube"
CREDENTIALS_FILE="credentials.txt"

# Update and install required packages
echo -e "${CYAN}Updating system and installing required packages...${RESET}"
apt update && apt install -y openjdk-17-jdk unzip wget postgresql postgresql-contrib
if [ $? -ne 0 ]; then
  echo -e "${RED}Error: Failed to install required packages.${RESET}"
  exit 1
fi
echo -e "${GREEN}Packages installed successfully.${RESET}"

# Configure PostgreSQL
echo -e "${CYAN}Configuring PostgreSQL...${RESET}"
sudo -i -u postgres psql -c "CREATE DATABASE ${DB_NAME};"
sudo -i -u postgres psql -c "CREATE USER ${DB_USER} WITH ENCRYPTED PASSWORD '${DB_PASS}';"
sudo -i -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};"
if [ $? -ne 0 ]; then
  echo -e "${RED}Error: Failed to configure PostgreSQL.${RESET}"
  exit 1
fi
echo -e "${GREEN}PostgreSQL configured successfully.${RESET}"

# Save credentials
echo -e "${CYAN}Saving database credentials to ${YELLOW}${CREDENTIALS_FILE}${RESET}..."
cat > $CREDENTIALS_FILE <<EOL
SonarQube Database Credentials:
Database Name: ${DB_NAME}
Username: ${DB_USER}
Password: ${DB_PASS}
EOL
echo -e "${CYAN} Password: ${DB_PASS} ${RESET}"
if [ $? -ne 0 ]; then
  echo -e "${RED}Error: Failed to save credentials.${RESET}"
  exit 1
fi
echo -e "${GREEN}Credentials saved to ${CREDENTIALS_FILE}.${RESET}"

# Download and extract SonarQube
echo -e "${CYAN}Downloading and extracting SonarQube...${RESET}"
wget ${SONARQUBE_URL} -P /tmp
unzip /tmp/${SONARQUBE_ZIP} -d /opt
mv /opt/sonarqube-${SONARQUBE_VERSION} ${SONARQUBE_DIR}
if [ $? -ne 0 ]; then
  echo -e "${RED}Error: Failed to download or extract SonarQube.${RESET}"
  exit 1
fi
echo -e "${GREEN}SonarQube downloaded and extracted successfully.${RESET}"

# Create a system user for SonarQube
echo -e "${CYAN}Creating system user for SonarQube...${RESET}"
useradd -r -s /bin/false ${SYS_USER}
chown -R ${SYS_USER}:${SYS_USER} ${SONARQUBE_DIR}
if [ $? -ne 0 ]; then
  echo -e "${RED}Error: Failed to create system user or set permissions.${RESET}"
  exit 1
fi
echo -e "${GREEN}System user created and permissions set successfully.${RESET}"

# Configure SonarQube
echo -e "${CYAN}Configuring SonarQube...${RESET}"
sed -i "s|#sonar.jdbc.username=|sonar.jdbc.username=${DB_USER}|" ${SONARQUBE_DIR}/conf/sonar.properties
sed -i "s|#sonar.jdbc.password=|sonar.jdbc.password=${DB_PASS}|" ${SONARQUBE_DIR}/conf/sonar.properties
sed -i "s|#sonar.jdbc.url=jdbc:postgresql://localhost/sonarqube|sonar.jdbc.url=jdbc:postgresql://localhost/${DB_NAME}|" ${SONARQUBE_DIR}/conf/sonar.properties
if [ $? -ne 0 ]; then
  echo -e "${RED}Error: Failed to configure SonarQube.${RESET}"
  exit 1
fi
echo -e "${GREEN}SonarQube configured successfully.${RESET}"

# Set system limits
echo -e "${CYAN}Setting system limits...${RESET}"
sysctl -w vm.max_map_count=262144
sysctl -w fs.file-max=65536
ulimit -n 65536
ulimit -u 4096
if [ $? -ne 0 ]; then
  echo -e "${RED}Error: Failed to set system limits.${RESET}"
  exit 1
fi
echo -e "${GREEN}System limits set successfully.${RESET}"

# Create systemd service for SonarQube
echo -e "${CYAN}Creating systemd service for SonarQube...${RESET}"
cat <<EOL > /etc/systemd/system/sonarqube.service
[Unit]
Description=SonarQube service
After=network.target

[Service]
Type=simple
User=${SYS_USER}
Group=${SYS_USER}
ExecStart=${SONARQUBE_DIR}/bin/linux-x86-64/sonar.sh start
ExecStop=${SONARQUBE_DIR}/bin/linux-x86-64/sonar.sh stop
Restart=always
LimitNOFILE=65536
LimitNPROC=4096

[Install]
WantedBy=multi-user.target
EOL
if [ $? -ne 0 ]; then
  echo -e "${RED}Error: Failed to create systemd service.${RESET}"
  exit 1
fi
echo -e "${GREEN}Systemd service created successfully.${RESET}"

# Reload systemd and start SonarQube service
echo -e "${CYAN}Starting SonarQube service...${RESET}"
systemctl daemon-reload
systemctl start sonarqube
systemctl enable sonarqube
if [ $? -ne 0 ]; then
  echo -e "${RED}Error: Failed to start or enable SonarQube service.${RESET}"
  exit 1
fi
echo -e "${GREEN}SonarQube service started and enabled successfully.${RESET}"

# Final message
echo -e "${BOLD_GREEN}SonarQube setup completed successfully!${RESET}"
echo -e "${CYAN}You can access SonarQube at http://your_server_ip:9000${RESET}"
echo -e "${CYAN}Default login credentials are admin / admin. Please change the password after the first login.${RESET}"
echo -e "${CYAN}Database credentials saved in ${YELLOW}${CREDENTIALS_FILE}${RESET}"
