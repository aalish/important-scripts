#!/bin/bash

# Import the color palette
source /path/to/colors.sh

# Check if the script is run as root
if [ "$(id -u)" -ne 0 ]; then
  echo -e "${RED}Error: Please run this script as root or using sudo.${RESET}"
  exit 1
fi

# Variables
USERNAME="worker"
HOMEDIR="/data"
SHELL="/bin/bash"

# Step 1: Check if the user already exists
echo -e "${CYAN}Step 1:${RESET} Checking if the user ${YELLOW}$USERNAME${RESET} already exists..."
if id -u "$USERNAME" >/dev/null 2>&1; then
  echo -e "${YELLOW}Warning: User ${USERNAME} already exists.${RESET}"
  exit 0
else
  echo -e "${GREEN}User ${USERNAME} does not exist. Proceeding with creation.${RESET}"
fi

# Step 2: Create the user with the specified home directory and shell
echo -e "${CYAN}Step 2:${RESET} Creating the user ${YELLOW}$USERNAME${RESET} with home directory ${YELLOW}$HOMEDIR${RESET} and shell ${YELLOW}$SHELL${RESET}..."
if useradd -m -d "$HOMEDIR" -s "$SHELL" "$USERNAME"; then
  echo -e "${GREEN}User ${USERNAME} created successfully.${RESET}"
else
  echo -e "${RED}Error: Failed to create the user ${USERNAME}.${RESET}"
  exit 1
fi


# Step 4: Verify the user creation
echo -e "${CYAN}Step 4:${RESET} Verifying the user ${YELLOW}$USERNAME${RESET} creation..."
USER_DETAILS=$(getent passwd "$USERNAME")
if [ -n "$USER_DETAILS" ]; then
  echo -e "${GREEN}User details:${RESET}"
  echo -e "${BOLD_GREEN}$USER_DETAILS${RESET}"
else
  echo -e "${RED}Error: User ${USERNAME} not found in the system after creation.${RESET}"
  exit 1
fi

# Step 5: Check the home directory
echo -e "${CYAN}Step 5:${RESET} Checking the home directory ${YELLOW}$HOMEDIR${RESET}..."
if [ -d "$HOMEDIR" ]; then
  echo -e "${GREEN}Home directory ${HOMEDIR} exists and is set correctly.${RESET}"
else
  echo -e "${RED}Error: Home directory ${HOMEDIR} does not exist.${RESET}"
  exit 1
fi

# Final message
echo -e "${BOLD_GREEN}User ${USERNAME} created successfully with home directory ${HOMEDIR} and shell ${SHELL}.${RESET}"
