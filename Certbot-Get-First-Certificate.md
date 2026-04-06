## Getting the First Certificate using Certbot

There are several ways to use Certbot with Docker to get your initial
TLS Certificate.  This file describes one way and some good and bad
implications.

## Method: Certbot with Nginx Listening on Port 80

In this configuration, certbot runs in one container and Nginx in another.
Both containers share a volume where the challenge file will be written
(written by the `certbot` app) and read by the Let's Encrypt server
at `http://your-domain-name/.well-known/acme-challenge/{challengefile}`.
This means Nginx must serve that same directory at the required path.


You manually issue a `certbot certonly` command (in the container)
to launch the app and get a certificate. 

### 1. Configuration of a Shared Volume

Certbot and Nginx need access to a shared volume. Inside the containers the "standard" path is `/var/www/certbot`.

The shared volume can be either:

- (a) directory mounted from the **host filesystem**, e.g. "/var/www/certbot" or "/srv/docker/certbot/www"
- (b) a **named volume** defined in `docker-compose.yml`

To define a named volume:
```yml

services:
  certbot:
    image: certbot/certbot:latest
    volumes: 
      - certbot-www:/var/www/certbot:rw

  nginx:
    image: nginx:stable
    volumes: 
      - certbot-www:/var/www/certbot:ro

  volumes:
    - vertbot-www:
```

To use a mount from the host filesystem instead of a named volume, do:

- 1. remove the "volumes:" section and use a full path instead of `certbot-www`, such as `/var/www/certbot` or (for isolation) `/srv/docker/certbot/www`.
- 2. create this directory on the server where containers will run. I used Ansible for this.

Implications:

1. Using the host filesystem creates some pollution of the host environment and requires an extra step to create the directory. But you can place test files in the directory to verify correct configuration.

2. A named volume is managed by docker. Potentially more secure and 

### 2. Configure `docker-compose.yml` 

The important things to configure are:

-  web root where the Certbot challenge file will be placed, e.g. /var/www/certbot
-  root path for where the TLS certificates will be stored.
   - Your choice as to where on the host to store this.
   - Must be mounted in container at `/etc/letscrypt`.

See [docker-compose.yml](./docker-compose.yml) in this repo for example.

### 3. Configure Nginx to Serve Content from Challenge Path

The Let's Encrypt server will attempt to read the challenge file from `http://your-domain/.well-known/acme-challenge/{challenge-file}`. Configure Nginx to serve this from the shared volume (described above). 

```conf
# nginx.conf

server {
    listen 80;
    listen [::]:80;
    server_name _;   # or hardcode actual domain name(s)

    # Location for certbot content.
    # Should be separate from your other web content.

    location /.well-known/acme-challenge/ {
        # use the volume mount point in docker-compose.yml
        root /var/www/certbot; 
        # I prefer: /usr/share/nginx/certbot;
    }

    # Location for normal web content
    location / {
        root /some/path/www;
        index index.html;
    }
}
```

### 3. Run Certbot to Get the Initial TLS Certificate

There are two ways to do this.  They both run the same command:

```shell
   certbot -v certonly \
           --webroot --webroot-path=/var/www/certbot \
           --agree-tos \
           --email $EMAIL \
           -d $HOSTNAME
```

- `certonly` means "just get a certificate" and save it. This is one of several modes of operation for Certbot.
- `--webroot`  means to use the web-based token challenge (aka HTTP-01).
- `--webroot-path` is the path to your web server's html root where the `.well-known/acme-challenge` subdirectory is
- `--agree-tos` means "agree to terms of service" to avoid interactive prompting

1.  Use a docker "run" command to start an instance of the certbot container
    and get a certificate, then remove the container. The nginx container must already be running or auto-started via a "requires: nginx" in docker-compose.yml.

    ```shell
    docker compose run --rm certbot -v certonly \
      --webroot --webroot-path=/var/www/certbot \
      --agree-tos \
      --email $EMAIL -d $HOSTNAME
    ```

2.  Start the containers first, then "exec" into the running certbot container and issue the command.

    ```shell
    docker-compose up -d
    # get the container name
    compose ps
    docker compose exec <container-name>  exec certbot -v certonly \
      --webroot --webroot-path=/var/www/certbot \
      --agree-tos \
      --email $EMAIL -d $HOSTNAME
 
I prefer the second method. Before running the `certbot certonly` command, I place a test file in `/var/www/certbot/.well-known/acme-challenge` and verify I can get it using a web browser.

I also use the log files to debug problems:
```shell
docker logs <container-name>
```

or run Dozzle in another container and view logs in Dozzle.

### Getting a Certificate Without Running Nginx

A weak point of the above approach is *after* you get a cert you need to modify the Nginx configuration to use the cert with https on port 443.
That means extra manual intervention.

Certbot has a `standalone` configuration where it will use a built-in
web server on port 80 to serve the challenge file.

This way, to get an initial certificate you run the `certbot` container only.
Once you have the certificate, you run both certbot (for certificate renewal)
and nginx. 

In `docker-compose.yml` you can use **profiles** to control which container(s) run in which phase of operation.

### Where to Store The Certificate Files?

You need to securely store the certificate public and private key files.
You also need to save other files managed by certbot.
They are all in subdirectories of `/etc/letsencrypt`.

The current certificate files will be in:

```
/etc/letsencrypt/live/<domain-name>/fullchain.pem
/etc/letsencrypt/live/<domain-name>/privkey.pem
```

The files must both be **readable by Nginx** (which may drop privilege to a non-root user after startup).  `privkey.pem` must not be readable by anyone except root and (maybe) the nginx user.

