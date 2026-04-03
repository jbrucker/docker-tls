## Install TLS Certificates in a Docker Container

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
   docker exec -it my-container  /bin/sh  (or /bin/bash if container has bash)
   ```

-  Tell nginx to reread its configuration files.  This requires that `nginx` be on the shell PATH inside the container (usually the case).

   ```
   docker exec nginx-container nginx -s reload
   ```

-  Use curl to test if you can download a testfile from the ACME challenge directory using IPv6.  Omit `-6` to test using IPv4.

   ```
   curl -6 http://lab0XX.kasetsart.university/.well-known/acme-challenge/testfile
   ```

