# oci-setup
This setup follows the same principle of https://www.simplehomelab.com/docker-media-server-2024/ but adjusted to my VPS setup (Oracle Cloud Instance Free Ampere (ARM) instance)
At home i'm using an Intel NUC with Unraid, might switch this in the future, but my current setup is stable, so I don't see the need to change this any time soon.

## Server setup
Setting up the server is simple with Oracle, simple create a new instance, select the setup, paste public keys and wait for it to spin up.
Next step is connecting with ssh to start setting up the server.

## Update Ubuntu before installing anything
Before installing, we need to update our system to ensure all packages are up-to-date. This helps avoid any conflicts during the installation. To do this, open a terminal and execute the following command:
```
sudo apt-get update
```
Once the update is complete, upgrade any outdated packages with the command below:
```
sudo apt-get upgrade
```

## Installing Powershell
I'm a "powershell-guru" at work, so I thought it would be a logical step to add this to my vps to ease the transition to using a linux based environment :)

Apparently there is [an issue](https://mikefrobbins.com/2024/09/26/how-to-install-powershell-7-and-essential-tools-on-linux/) to install this on an ARM64 system, so we'll be using the following steps to install powershell into the system

```
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
```

After installation, we can verify that PowerShell 7 is installed correctly by running:
```
pwsh
```

## Installing Docker
### Setting up the Repository
Firstly, we need to ensure our system is up-to-date and then install the Docker repository to allow us to download and install the Docker application.


```
sudo apt-get install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
```

```
 sudo mkdir -p /etc/apt/keyrings
```

```
 curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
```

```
 echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

### Install Docker CE
Then we can go ahead and install the Docker application

```
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin
And we can add our current user to the docker group to save us needing to run as sudo each time we want to run a Docker command.
```

```
sudo usermod -aG docker $USER
```

We should now close our session and log back in to allow the changes to take effect.

## Installing the server
Every service has been split up into seperate yml-files, with one main docker-compose-master.yml to include all configs.

First we need to create the folders to hold all the data for the containers, compose files and secrets.
