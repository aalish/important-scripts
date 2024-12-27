#!/bin/bash

# Import the color palette
source ./colors.sh

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
  echo -e "${RED}Error: This script must be run as root.${RESET}"
  exit 1
fi

# Variables
EASYRSA_DIR="$HOME/easy-rsa"
OUTPUT_DIR="$HOME/openvpn-clients"
CLIENT_NAME="$1"
SERVER_IP=$(curl -s ifconfig.me)

# Check if client name is provided
if [ -z "$CLIENT_NAME" ]; then
  echo -e "${RED}Error: No client name provided.${RESET}"
  echo -e "${CYAN}Usage:${RESET} $0 <client_name>"
  exit 1
fi

# Navigate to Easy-RSA directory
if [ ! -d "$EASYRSA_DIR" ]; then
  echo -e "${RED}Error: Easy-RSA directory not found at $EASYRSA_DIR.${RESET}"
  exit 1
fi
cd $EASYRSA_DIR

# Step 1: Generate client certificate and key
echo -e "${CYAN}Step 1:${RESET} Generating certificate and key for client ${YELLOW}$CLIENT_NAME${RESET}..."
./easyrsa gen-req $CLIENT_NAME nopass
if [ $? -ne 0 ]; then
  echo -e "${RED}Error: Failed to generate client certificate and key.${RESET}"
  exit 1
fi
echo -e "${GREEN}Client certificate and key generated successfully.${RESET}"

# Step 2: Sign the client certificate
echo -e "${CYAN}Step 2:${RESET} Signing the certificate for client ${YELLOW}$CLIENT_NAME${RESET}..."
./easyrsa sign-req client $CLIENT_NAME
if [ $? -ne 0 ]; then
  echo -e "${RED}Error: Failed to sign client certificate.${RESET}"
  exit 1
fi
echo -e "${GREEN}Client certificate signed successfully.${RESET}"

# Step 3: Create output directory
echo -e "${CYAN}Step 3:${RESET} Creating output directory for client configuration..."
mkdir -p $OUTPUT_DIR
if [ $? -ne 0 ]; then
  echo -e "${RED}Error: Failed to create output directory.${RESET}"
  exit 1
fi
echo -e "${GREEN}Output directory created at ${YELLOW}$OUTPUT_DIR${RESET}."

# Step 4: Generate client configuration file
echo -e "${CYAN}Step 4:${RESET} Generating client configuration file..."
CLIENT_CONFIG="$OUTPUT_DIR/$CLIENT_NAME.ovpn"
cat > $CLIENT_CONFIG <<EOL
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
echo -e "${GREEN}Client configuration file created successfully at ${YELLOW}$CLIENT_CONFIG${RESET}."

# Step 5: Display final message
echo -e "${BOLD_GREEN}Client setup completed successfully!${RESET}"
echo -e "${CYAN}Client configuration file:${RESET} ${YELLOW}$CLIENT_CONFIG${RESET}"
echo -e "${CYAN}You can distribute this file to the client to connect to the OpenVPN server.${RESET}"
