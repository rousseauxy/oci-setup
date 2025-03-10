# oci-setup

## Installing Docker
### Setting up the Repository
Firstly, we need to ensure our system is up-to-date and then install the Docker repository to allow us to download and install the Docker application.
```
sudo apt-get update
```

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
