## How to Use Docker Agent

Docker agent let's you run a local docker-compose project on a
remote machine. Your docker commands run on the remote host and
files are copied to the remote host using ssh.

Requires:

- docker installed on the remote host
- you are in the docker group so you can run docker without "sudo"
- you have password-less ssh access
- you have password-less sudo privilege (sudo doesn't ask for a password)

Define a docker context:

```
docker context create remote-vm --docker "host=ssh://seclab@lab0XX.kasetsart.university"
```

- `remote-vm` is any name you want to refer to the remote host as
- You can use an IP address instead of hostname.

Start the context:

```
docker context use remote-vm
```

Now issue docker commands as usual:

```
docker-compose up -d
```
