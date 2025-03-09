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

## Installing Traefik
I’m using traefik official docker image and docker compose to spin up traefik, you can use any version you want or use the latest version as of at the time you’re reading this,

```
services:
  traefik:
    image: traefik:v3.1
    container_name: traefik
    restart: unless-stopped
    networks:
      - proxy
    ports:
      - 80:80
      - 443:443
      - 8080:8080
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./config/traefik.yml:/traefik.yml:ro
      - ./config/acme.json:/acme.json

networks:
  proxy:
    external: true
```

Here, this is a pretty straight forward docker compose for traefik, used official docker image for traefik with version 3.1, assigned restart policy to unless stopped, exposed ports for HTTP/80, HTTPS/443 and 8080 port for dashboard access for now, we will remove this port after all the configuration is completed and working properly.

I’ve mounted the docker sock file so that it can access and modify the docker containers, traefik.yml file for the traefik configs and acme.json for storing TLS cert keys.

Here we’ve used external network named proxy, and we will deploy our other containers to the same network so that traefik can access those container and those containers can communicate with traefik.
```
api:
  dashboard: true
  debug: true
  insecure: true
entryPoints:
  http:
    address: ":80"
    http:
      redirections:
        entryPoint:
          to: https
          scheme: https
  https:
    address: ":443"
serversTransport:
  insecureSkipVerify: true
providers:
  docker:
    endpoint: "unix:///var/run/docker.sock"
    exposedByDefault: false
certificatesResolvers:
  caresolver:
    acme:
      email: me@example.com
      storage: acme.json
      caServer: https://acme-v02.api.letsencrypt.org/directory # prod (default)
      httpChallenge:
        # used during the challenge
        entryPoint: http
```

This is my traefik.yml file.

> Note that, traefik only work for yml file extension, if you’re using yaml as file extension it will not work.

In this config all are pretty basic as per the official docs for traefik, here I’ve set dashboard and insecure to true as we will check the dashboard, using docker as provider and configured the docker sock for endpoint, for TLS certificate resolver i’m using let’s encrypt and to store the certificate set the storage acme.json that we mounted on the docker compose, and we are using HTTP/80 and HTTPS/443 ports.

> Note that, as acme.json will hold all the cert keys it will have to be with permission set to 600. This is the simple command to set the file permission,
```
chmod 600 acme.json
```
Now the last piece, we need a docker network called proxy, to create the network run this command,
```
docker network create proxy
```
Here you can use any name for the network, but keep that in mind you have to update the compose file with the network name properly to work.

Now run docker compose command in detached mode,
```
docker compose up -d
```
If everything worked, then you can go to the public ip of your vm on 8080 port, and you should see something like this,


## Portainer
### Installing Portainer
Firstly, we need to install a volume for our Portainer data. Because Docker containers are self-contained, when we tear down our container, we also lose any data stored within the container. To prevent data loss, we use Docker to create volumes, which are basically storage areas on the host machine that are mapped into a container, so that when the container is destroyed, the volume and data stored within it are retained. This is useful for when we're upgrading or redeploying containers, and can re-map the volume to the new container without data loss.

```
docker volume create portainer_data
```

We can then tell Docker to run the Portainer container. In the command below, we provide port mappings which tell Docker to expose port 8000 from within the container to port 9443 on the host machine. Remember, we allowed access to 9443 when we configured the virtual machine firewall earlier.

We also give the container a name, a restart policy and link 2 volumes. The one we just created above, and the docker socket. This allows Portainer to execute Docker commands to allow it to manage Docker for us.

The final line is the image name and tag. At the time of writing 2.9.3 was the latest version of Portainer container. If this image doesn't already exist on the local machine, Docker will go ahead and download it for you.

~~
```
docker run -d -p 8000:8000 -p 9443:9443 --name portainer \
    --restart=always \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v portainer_data:/data \
    portainer/portainer-ce:latest
```
~~

Composer-file for portainer running with traefik
```
services:
  portainer:
    image: portainer/portainer-ce:latest
    container_name: portainer
    restart: unless-stopped
    networks:
      - proxy
    ports:
      - 9443
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /appdata/portainer:/data
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.nginx.rule=Host(`portainer.example.com`)"
      - "traefik.http.routers.nginx.entrypoints=https"
      - "traefik.http.routers.nginx.tls=true"
      - "traefik.http.routers.nginx.tls.certresolver=caresolver"
      - "traefik.http.services.nginx.loadbalancer.server.port=9443"
    networks:
      - proxy

networks:
  proxy:
    external: true
```

When this has completed the installation, we should be able to list the containers in our Docker instance and see our Portainer container running:

```
docker ps
```
10.JPG

### Accessing Portainer
We should now be able to access our Portainer instance at :9443

You may be presented with a certificate error as Portainer uses a self-signed certificate. You can safely ignore this.

The first time you load the Portainer interface you will be asked to create a user account.

11.JPG

Create an account and then when presented with the environment wizard, select 'Proceed with the current environment'.

You should then be presented with the local environment, which should have a single container (our Portainer container) up and running:

12.JPG
