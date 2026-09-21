docker-image:tag@hash_value

Dung hash_value khi tai docker image giup dam bao tinh toan ven cua image. Image co the bi thay doi khi o nguon vi vay can dung hash_value de xac dinh dung image, neu khong co the dan den cac lo hong bao mat (enhance security)

digest-binned base docker

static linking vs dynamic linking

ldd with python3 (to list all share libs in python) (python share object)

![[docker command.png]]

docker run -it 
By using a [pseudo-terminal (TTY)](https://iximiuz.com/en/posts/linux-pty-what-powers-docker-attach-functionality/). This is exactly what the `docker run -t` flag does - it allocates a pseudo-TTY (pty), and makes it a controlling terminal of the containerized application.
![[docker run -it.png]]

`docker attach`, is merely connecting our terminal to the containerized application's _stdio_ streams (and starting to forward signals), while the `docker exec` command starts a new _hidden container_ inside the existing container.

## Docker pause vs stop
When you **pause** a container, [all container's processes get suspended](https://labs.iximiuz.com/challenges/linux-freeze-and-thaw-processes), but you can still find them in the host's process list, and the container is technically considered to be still **running**.

However, when you **stop** a container, all container's processes get terminated, but its filesystem and metadata remain intact, so you can restart it again later.

# Docker signal
Signal a Running Containerized Application
Signals can be used not only to terminate or forcefully kill applications, but also to influence their behavior. For example:

- Nginx will reload its configuration and reopen log files upon receiving `SIGUSR1`.
- HAProxy and Gunicorn will reload their configuration upon receiving `SIGHUP`.
- Custom apps may implement `SIGUSR1`/`SIGUSR2` handlers for debug dumps.

# Docker export
The `crane export` command surprisingly produces incomplete results. Compare the `/root` directory in the actual image filesystem at [ima.ge.cx/ghcr.io/iximiuz/labs/redis:latest](https://ima.ge.cx/ghcr.io/iximiuz/labs/redis:latest) and the `~/imagefs` directory produced by `crane export`. You may be surprised to see that the local `~/imagefs` directory is missing some files.

Feeling a bit lost? Check out this short tutorial - [How To Extract Container Image Filesystem Using Docker](https://labs.iximiuz.com/tutorials/extracting-container-image-filesystem).