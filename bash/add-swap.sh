#!/bin/bash

# Check if the script is run as root
if [ "$(id -u)" -ne 0 ]; then
  echo "Please run this script as root or using sudo."
  exit 1
fi

# Set default swap size and allow argument override
DEFAULT_SIZE=2
SWAP_SIZE="${1:-$DEFAULT_SIZE}G"

# Define swap file name
SWAP_FILE="/swapfile"

# Create a new swap file
echo "Creating a swap file of size $SWAP_SIZE..."
fallocate -l $SWAP_SIZE $SWAP_FILE || {
  echo "fallocate failed, trying dd..."
  dd if=/dev/zero of=$SWAP_FILE bs=1M count=$((SWAP_SIZE * 1024))
}

# Set the appropriate permissions
chmod 600 $SWAP_FILE

# Make the file a swap space
mkswap $SWAP_FILE

# Enable the swap file
swapon $SWAP_FILE

# Add to /etc/fstab for persistence
if ! grep -q "$SWAP_FILE" /etc/fstab; then
  echo "$SWAP_FILE none swap sw 0 0" >> /etc/fstab
fi

echo "Swap space of size $SWAP_SIZE added and enabled."
swapon --show
free -h

