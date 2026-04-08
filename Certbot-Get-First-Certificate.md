## Getting a First TLS Certificate using Certbot

There are several ways to use Certbot with Docker to get your initial
TLS Certificate.  the Let's Encrypt service verifies the applicant's 
control over a domain by either:

- client places a "challenge file" in a known location in the web root served using http.  The web *path* to this file is `.well-known/acme-challenge/{filename}`.
- client places a specifies TXT record in the authitative DNS service for the domain.  This method is required to obtain a wildcard certificate.

Let's Encrypt provides a program named `certbot` that runs on the server
receiving the TLS certificate.  Certbot does:

- manage challenge file placement
- manage installing and updating TLS certificates in `/etc/letsencrypt`
- handle certificate renewal. But you need to launch `certbot` periodically to perform a check for renewal

Certbot has other functions as well. See [certbot.eff.org](https://certbot.eff.org/).

## Certbot with web-root Challenge File

If you want to obtain a certificate using a web-based challenge file to
prove domain control, there are three methods:

- **standalone** - Certbot runs a built-in web server on port 80 to publish the challenge file.
- **certonly** - Certbot places the challenge in the web-root of another web server (such as Nginx).
- **nginx** - Like `certonly` but Certbot also configures Nginx


This file describes the `certonly` approach. 


## Method: Certbot with Nginx Listening on Port 80

In this configuration, certbot runs in one container and Nginx in another.
Both containers share a volume where the challenge file is written
(by the `certbot` app) and read by the Let's Encrypt server.
The Internet-facing URL for the challenge must be:

```
http://your-domain-name/.well-known/acme-challenge/{challengefile}
```

After starting both containers and verifying the Nginx is working
(by placing a test file in `.well-known/acme-challenge`),
you manually issue a `certbot certonly` command **inside** the certbot 
container to launch certbot and get a certificate. 

If it succeeds, the public and private keys are placed in 
`/etc/letsencrypt/archive/{domain-name}` with symlinks in the directory
`/etc/letsencrypt/live/{domain-name}`.

That the "live" certificates are actually symbolic links to other files
can be nuisance for virtualizing the location.

### 1. Configure a Shared Volume

Certbot and Nginx need access to a shared volume. Inside the containers the "standard" path is `/var/www/certbot`.

The shared volume can be either:

- (a) directory mounted from the **host filesystem**, e.g. "/var/www/certbot" or "/srv/docker/certbot/www"
- (b) a **named volume** defined in `docker-compose.yml`

Since the contents of this directory are only used by certbot and Nginx to serve the challenge, using a named volume is cleaner.  On the flip side, its easier to but a test file in an external volume.

To define a named volume, use:
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
- 2. it is not necessary to create this directory (docker will create it), but you might want to create it yourself and install a test file. I used Ansible for this.

Implications:

1. Creating a directory in the host filesystem adds some pollution of the host environment. But makes it easier to place test files to verify correct configuration.

2. A named volume is managed by docker. Potentially more secure.


### 2. Configure `docker-compose.yml` 

The important things to configure are:

-  web root where the Certbot challenge file will be placed, e.g. /var/www/certbot
-  root path for where the TLS certificates will be stored. This must be mounted in container at `/etc/letsencrypt`.

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
 
I used the second method to learning, and the "standalone" mode for true aotomation (so I don't need to reconfigure Nginx). 

Before running the `certbot certonly` command, I placed a test file in `/var/www/certbot/.well-known/acme-challenge` and verify I can read it using a web browser.

I also use the log files to debug problems:
```shell
docker logs <container-name>
```

or run Dozzle in another container and view logs in Dozzle.


### Getting a Certificate Without Running Nginx

A weak point of the above approach is that you need to change the Nginx configuration file (add TLS support) *after* you get a certificate.
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
/etc/letsencrypt/live/<domain-name>/cert.pem
/etc/letsencrypt/live/<domain-name>/privkey.pem
```

the files are actually symbolic links to files in `/etc/letsencrypt/archive/<domain-name>`.


`privkey.pem` must not be readable by anyone except root and (maybe) the nginx user.

By default, certbot creates both the `live` and `archive` directories as mode 0700 (readable only by root) and Nginx is able to read the certificates.

