#!/bin/bash

# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Requesting administrator privileges..."
  sudo "$0" "$@"
  exit
fi

# Define paths
steam_path="$HOME/Library/Application Support/Steam"
dota_path="$steam_path/steamapps/common/dota 2 beta/game/dota/scripts/vscripts/bots"
source_path=$(cd "$(dirname "$0")/.." && pwd)
install_folder=$(cd "$(dirname "$0")" && pwd)

# Check if Steam and Dota paths exist
if [ ! -d "$steam_path" ]; then
  echo "Steam folder not found. Please ensure Steam is installed and try again."
  exit 1
fi

if [ ! -d "$source_path" ]; then
  echo "Source folder not found at $source_path. Please run this script from a valid bot script copy."
  exit 1
fi

# Get the current timestamp (format: YYYYMMDD_HHMMSS)
timestamp=$(date +"%Y%m%d_%H%M%S")

# Check if the bots folder already exists
if [ -d "$dota_path" ]; then
  echo "Folder already exists, renaming to bots_old_$timestamp..."
  mv "$dota_path" "${dota_path}_old_$timestamp"
fi

# Create symbolic link
echo "Using source path: $source_path"
echo "Creating symbolic link..."
ln -s "$source_path" "$dota_path"
if [ $? -eq 0 ]; then
  echo "============"
  echo "Install Succeeded!!!"
  echo "============"
else
  echo "============"
  echo "Install failed!!!"
  echo "1. Ensure Dota 2 is installed and the paths are correct."
  echo "2. Ensure you run this script with sudo."
  echo "============"
fi

# Pause to keep the terminal open
read -p "Press Enter to exit..."
