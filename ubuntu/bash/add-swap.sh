#!/bin/bash

# Import the color palette
source ./colors.sh

# Check if the script is run as root
if [ "$(id -u)" -ne 0 ]; then
  echo -e "${RED}Error: Please run this script as root or using sudo.${RESET}"
  exit 1
fi

# Set default swap size and allow argument override
DEFAULT_SIZE=2
SWAP_SIZE="${1:-$DEFAULT_SIZE}G"

# Define swap file name
SWAP_FILE="/swapfile"

# Step 1: Create a new swap file
echo -e "${CYAN}Step 1:${RESET} Creating a swap file of size ${YELLOW}$SWAP_SIZE${RESET}..."
if fallocate -l $SWAP_SIZE $SWAP_FILE; then
  echo -e "${GREEN}Swap file created successfully using fallocate.${RESET}"
else
  echo -e "${YELLOW}fallocate failed, trying dd...${RESET}"
  if dd if=/dev/zero of=$SWAP_FILE bs=1M count=$((SWAP_SIZE * 1024)); then
    echo -e "${GREEN}Swap file created successfully using dd.${RESET}"
  else
    echo -e "${RED}Error: Failed to create swap file.${RESET}"
    exit 1
  fi
fi

# Step 2: Set appropriate permissions
echo -e "${CYAN}Step 2:${RESET} Setting appropriate permissions..."
chmod 600 $SWAP_FILE
echo -e "${GREEN}Permissions set to 600.${RESET}"

# Step 3: Make the file a swap space
echo -e "${CYAN}Step 3:${RESET} Configuring the swap file as swap space..."
if mkswap $SWAP_FILE; then
  echo -e "${GREEN}Swap space configured successfully.${RESET}"
else
  echo -e "${RED}Error: Failed to configure swap space.${RESET}"
  exit 1
fi

# Step 4: Enable the swap file
echo -e "${CYAN}Step 4:${RESET} Enabling the swap file..."
if swapon $SWAP_FILE; then
  echo -e "${GREEN}Swap file enabled successfully.${RESET}"
else
  echo -e "${RED}Error: Failed to enable swap file.${RESET}"
  exit 1
fi

# Step 5: Add to /etc/fstab for persistence
echo -e "${CYAN}Step 5:${RESET} Adding swap file to /etc/fstab for persistence..."
if ! grep -q "$SWAP_FILE" /etc/fstab; then
  echo "$SWAP_FILE none swap sw 0 0" >> /etc/fstab
  echo -e "${GREEN}Swap file added to /etc/fstab.${RESET}"
else
  echo -e "${YELLOW}Swap file already exists in /etc/fstab.${RESET}"
fi

# Display swap details
echo -e "${CYAN}Swap space configuration completed.${RESET}"
echo -e "${BOLD_GREEN}Swap details:${RESET}"
swapon --show
echo
echo -e "${BOLD_GREEN}Memory status:${RESET}"
free -h
