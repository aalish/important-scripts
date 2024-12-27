#!/bin/bash

# Import the color palette
source ./colors.sh

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
  echo -e "${RED}Error: This script must be run as root.${RESET}"
  exit 1
fi

# Variables
OPENVPN_DIR="/etc/openvpn"
EASYRSA_DIR="$HOME/easy-rsa"
SERVER_CN="server"
CLIENT_NAME="client1"
SERVER_IP=$(curl -s ifconfig.me)

# Update and install necessary packages
echo -e "${CYAN}Updating system and installing required packages...${RESET}"
apt update && apt install -y openvpn easy-rsa curl ufw
if [ $? -ne 0 ]; then
  echo -e "${RED}Error: Failed to install required packages.${RESET}"
  exit 1
fi
echo -e "${GREEN}Packages installed successfully.${RESET}"

# Set up Easy-RSA
echo -e "${CYAN}Setting up Easy-RSA...${RESET}"
mkdir -p $EASYRSA_DIR
ln -s /usr/share/easy-rsa/* $EASYRSA_DIR/
chown -R $(whoami) $EASYRSA_DIR
chmod 700 $EASYRSA_DIR
cd $EASYRSA_DIR
./easyrsa init-pki
echo -e "${GREEN}Easy-RSA setup completed.${RESET}"

# Build CA
echo -e "${CYAN}Building Certificate Authority (CA)...${RESET}"
(echo -ne '\n') | ./easyrsa build-ca nopass
if [ $? -ne 0 ]; then
  echo -e "${RED}Error: Failed to build CA.${RESET}"
  exit 1
fi
echo -e "${GREEN}CA built successfully.${RESET}"

# Generate server certificate and key
echo -e "${CYAN}Generating server certificate and key...${RESET}"
./easyrsa gen-req $SERVER_CN nopass
./easyrsa sign-req server $SERVER_CN
if [ $? -ne 0 ]; then
  echo -e "${RED}Error: Failed to generate server certificate and key.${RESET}"
  exit 1
fi
echo -e "${GREEN}Server certificate and key generated successfully.${RESET}"

# Generate Diffie-Hellman parameters
echo -e "${CYAN}Generating Diffie-Hellman parameters...${RESET}"
./easyrsa gen-dh
if [ $? -ne 0 ]; then
  echo -e "${RED}Error: Failed to generate Diffie-Hellman parameters.${RESET}"
  exit 1
fi
echo -e "${GREEN}Diffie-Hellman parameters generated successfully.${RESET}"

# Generate HMAC key for additional security
echo -e "${CYAN}Generating HMAC key for additional security...${RESET}"
openvpn --genkey --secret ta.key
if [ $? -ne 0 ]; then
  echo -e "${RED}Error: Failed to generate HMAC key.${RESET}"
  exit 1
fi
echo -e "${GREEN}HMAC key generated successfully.${RESET}"

# Create server configuration
echo -e "${CYAN}Creating OpenVPN server configuration...${RESET}"
cat > $OPENVPN_DIR/server.conf <<EOL
port 1194
proto udp
dev tun
ca $EASYRSA_DIR/pki/ca.crt
cert $EASYRSA_DIR/pki/issued/$SERVER_CN.crt
key $EASYRSA_DIR/pki/private/$SERVER_CN.key
dh $EASYRSA_DIR/pki/dh.pem
tls-auth $EASYRSA_DIR/ta.key 0
topology subnet
server 10.8.0.0 255.255.255.0
ifconfig-pool-persist ipp.txt
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 8.8.4.4"
keepalive 10 120
cipher AES-256-CBC
user nobody
group nogroup
persist-key
persist-tun
status openvpn-status.log
verb 3
explicit-exit-notify 1
EOL
if [ $? -ne 0 ]; then
  echo -e "${RED}Error: Failed to create server configuration.${RESET}"
  exit 1
fi
echo -e "${GREEN}Server configuration created successfully.${RESET}"

# Enable IP forwarding
echo -e "${CYAN}Enabling IP forwarding...${RESET}"
sysctl -w net.ipv4.ip_forward=1
echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
if [ $? -ne 0 ]; then
  echo -e "${RED}Error: Failed to enable IP forwarding.${RESET}"
  exit 1
fi
echo -e "${GREEN}IP forwarding enabled.${RESET}"

# Configure firewall
# echo -e "${CYAN}Configuring firewall...${RESET}"
# ufw allow 1194/udp
# ufw allow OpenSSH
# ufw disable
# ufw enable
# if [ $? -ne 0 ]; then
#   echo -e "${RED}Error: Failed to configure firewall.${RESET}"
#   exit 1
# fi
# echo -e "${GREEN}Firewall configured successfully.${RESET}"

# Start and enable OpenVPN service
echo -e "${CYAN}Starting and enabling OpenVPN service...${RESET}"
systemctl start openvpn@server
systemctl enable openvpn@server
if [ $? -ne 0 ]; then
  echo -e "${RED}Error: Failed to start and enable OpenVPN service.${RESET}"
  exit 1
fi
echo -e "${GREEN}OpenVPN service started and enabled.${RESET}"

# Generate client certificate and key
echo -e "${CYAN}Generating client certificate and key...${RESET}"
./easyrsa gen-req $CLIENT_NAME nopass
./easyrsa sign-req client $CLIENT_NAME
if [ $? -ne 0 ]; then
  echo -e "${RED}Error: Failed to generate client certificate and key.${RESET}"
  exit 1
fi
echo -e "${GREEN}Client certificate and key generated successfully.${RESET}"

# Create client configuration
echo -e "${CYAN}Creating client configuration...${RESET}"
cat > $HOME/$CLIENT_NAME.ovpn <<EOL
client
dev tun
proto udp
remote $SERVER_IP 1194
resolv-retry infinite
nobind
user nobody
group nogroup
persist-key
persist-tun
remote-cert-tls server
cipher AES-256-CBC
verb 3
<ca>
$(cat $EASYRSA_DIR/pki/ca.crt)
</ca>
<cert>
$(cat $EASYRSA_DIR/pki/issued/$CLIENT_NAME.crt)
</cert>
<key>
$(cat $EASYRSA_DIR/pki/private/$CLIENT_NAME.key)
</key>
<tls-auth>
$(cat $EASYRSA_DIR/ta.key)
</tls-auth>
key-direction 1
EOL
if [ $? -ne 0 ]; then
  echo -e "${RED}Error: Failed to create client configuration file.${RESET}"
  exit 1
fi
echo -e "${GREEN}Client configuration file created successfully at ${YELLOW}$HOME/$CLIENT_NAME.ovpn${RESET}"

# Final message
echo -e "${BOLD_GREEN}OpenVPN server setup completed successfully!${RESET}"
echo -e "${CYAN}Client configuration file:${RESET} ${YELLOW}$HOME/$CLIENT_NAME.ovpn${RESET}"
echo -e "${CYAN}You can distribute this file to clients to connect to the OpenVPN server.${RESET}"
