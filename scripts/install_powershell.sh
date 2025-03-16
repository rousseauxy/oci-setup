#!/bin/bash

# Determine the system architecture
ARCH=$(dpkg --print-architecture)

# Get the latest PowerShell version number
pwshVersion=$(curl -s https://api.github.com/repos/PowerShell/PowerShell/releases/latest | grep 'tag_name' | cut -d '"' -f 4 | sed 's/v//')

# Download PowerShell tarball for the detected architecture and version
downloadUrl="https://github.com/PowerShell/PowerShell/releases/download/v$pwshVersion/powershell-$pwshVersion-linux-$ARCH.tar.gz"
curl -L -o /tmp/powershell.tar.gz "$downloadUrl"

# Create the installation directory if it doesn't exist
sudo mkdir -p /opt/microsoft/powershell/7

# Extract the tarball to the installation directory
sudo tar zxf /tmp/powershell.tar.gz -C /opt/microsoft/powershell/7

# Make pwsh executable
sudo chmod +x /opt/microsoft/powershell/7/pwsh

# Remove the existing symlink if one exists
sudo rm "/usr/bin/pwsh"

# Create a new symlink for pwsh
sudo ln -s /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh

# Clean up by removing the downloaded tarball
rm /tmp/powershell.tar.gz