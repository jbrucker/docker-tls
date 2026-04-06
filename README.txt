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

## IP Address

### Show IPv6 address, briefly

```
    ip -brief -oneline -6 addr
```
Output:
```
lo               UNKNOWN        ::1/128 
eth0             UP             fe80::5054:ff:fe70:d00e/64 
docker0          DOWN           fe80::6c02:4aff:fe91:eaba/64
```
**Note:** `fe80::` addresses are link-local, unroutable addresses.

For just the `eth0` interface:

```
    ip -brief -oneline -6 addr show dev eth0
```

### Use Ansible to show the IPv6 address for all hosts in an inventory

Use the name `all` for all hosts or a named group of hosts (e.g. `lab`).

```
ansible all -i hosts.ini -m command -a "ip -o -br -6 addr show dev eth0" -o
```

Or use a Playbook and tasks:
```yaml
- hosts: all
  gather_facts: no
  tasks:
    - name: Get IPv6 addresses
      shell: ip -oneline -br -6 addr show dev eth0
      register: result
      changed_when: false

    - name: Print result
      debug:
        var: result.stdout
```
then run:  `ansible-playbook -i hosts.ini show_ip6.yml`


Set the IPv6 address for the duration of this boot. Changes are not persistent.

```
sudo  ip -6 addr add 2001:3c8:1303::c192:1028:3066/64 dev eth0
```


