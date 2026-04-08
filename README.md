## Install TLS Certificates in a Docker Container

This repository contains some example files that use the EFF `certbot`
and Nginx to obtain and use a TLS certificate.

The goal is to develop a technique to obtain, deploy, and manage TLS
certificates on remote VMs.  Objectives are:

- be able to obtain and deploy TLS certificates on remote servers with minimum manual effort. We don't want to manually modify (edit) docker-compose files or Ngninx config files.

- clean separation of infrastructure concerns from application concerns.  `docker-compose.yml` and Ansible tasks (or Terraform) handle infrastructure concerns.  Container content, such as `nginx.conf`, handles the application.

There are several ways to do this and many "tweaks" to consider,
such as whether to use a host's file system for certs or challenge files
or store them in Docker volumes.

## Notes on Implementation

These files use the EFF `certbot` and Nginx to obtain a TLS certificate.



## Useful Commands

-  Get a list of running containers.

   ```
   compose ps
   ```

-  Execute a command in a docker container named `my-container`.

   ```
   docker exec my-container  some-command
   ```

-  Open an interactive shell in a container:

   ```
   docker exec -it my-container  /bin/sh
   ```

-  Tell nginx to reread its configuration files.  This is needed when certbot updates the TLS certificates.

   ```
   docker exec nginx-container nginx -s reload
   ```

-  Use curl to test if you can download a testfile from the ACME challenge directory using IPv6.  Omit `-6` to test using IPv4.

   ```
   curl -6 http://lab0XX.kasetsart.university/.well-known/acme-challenge/testfile
   ```

## IP Address

### Show IPv6 address, briefly

```
    ip -brief -oneline -6 addr
```
Output:
```
lo               UNKNOWN        ::1/128 
eth0             UP             2001:3c8:1303::c192:1028:3066/64
docker0          DOWN           fe80::6c02:4aff:fe91:eaba/64
```
**Note:** `fe80::` addresses are link-local, unroutable addresses.  For the server to accessible using IPv6 it needs a globally routable address.

to show only the `eth0` interface (omit `-brief -6` for full details)

```
    ip -brief -6 addr show dev eth0
```

another command is ifconfig ("ipconfig" on Windows):
```
    ifconfig eth0
```


