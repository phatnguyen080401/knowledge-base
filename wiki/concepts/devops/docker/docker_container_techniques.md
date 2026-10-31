---
title: Docker Container Techniques
tags: [devops, deployment, docker]
created: 2026-10-31 11:47:01
updated: 2026-10-31 12:12:46
---

# Docker Container Techniques

These are the techniques for working with a container after `docker run` has started it: how the command actually becomes a process, how an interactive terminal reaches it, how to attach to or exec into it, how to stop, kill, or freeze it, how to signal it, and how to get its filesystem out. They build on the architecture described in [[concepts/devops/docker/docker|Docker]].

## Why It Matters

Most surprises with containers come from not knowing which process you are talking to. Ctrl-C that does nothing, a shell exit that stops a production container, "the input device is not a TTY" in CI, a `docker stop` that always takes ten seconds, a paused container that still holds memory, and an exported filesystem with files missing all trace back to the same few mechanisms. Knowing how streams, terminals, and signals travel from the CLI to the containerized process explains each of them.

The stakes are highest at shutdown. An application that is killed mid-operation cannot finish in-flight requests, flush buffers, commit or roll back transactions, release locks, or close connections cleanly. The result can be dropped requests, half-written files, or a database that has to recover on the next start.

## How `docker run` Works

![[raw/assets/docker_run_command.png|600]]

The diagram, from iximiuz Labs, shows `docker run nginx:latest` as a chain of processes. The CLI talks to `dockerd`, which talks to `containerd`, which starts a runtime shim, whose child processes are the containerized nginx master and workers. Signals and stdin flow toward the container, and stdout and stderr flow back to the terminal.

### A compound command

`docker run` is a compound command. It translates into a sequence of more basic operations, and depending on the flags and the image, the exact sequence can differ:

| Step | Equivalent command | What happens |
| --- | --- | --- |
| 1. Image pull | `docker image pull nginx:latest` | Only if the image is not already local |
| 2. Container create | `docker container create --name web nginx:latest` | Allocates the writable layer and stores the configuration; nothing runs yet |
| 3. Container attach | `docker container attach web` | Connects the CLI to the container's stdio streams, unless `-d` is given |
| 4. Network connect | `docker network connect bridge web` | Attaches the container to its network |
| 5. Container start | `docker container start web` | Creates the namespaces and cgroups and starts the main process |

Running `docker create` and then `docker start -a` by hand reproduces `docker run` without `-d`.

### The process chain

| Component | Runs as | Talks to the next hop over |
| --- | --- | --- |
| `docker` CLI | A foreground process in your terminal session | HTTP REST API on a Unix socket (`/var/run/docker.sock`) |
| `dockerd` | A [[concepts/linux/systemd_targets\|systemd service]] (daemon) | gRPC API on a Unix socket |
| `containerd` | A systemd service (daemon) | Starts one shim per container |
| `containerd-shim-runc-v2` | A background process, one per container | FIFOs or a Unix socket to the container's stdio |
| Container processes | Children of the shim, inside their own mount, PID, and network namespaces | — |

The host's process tree in the diagram shows the key design choice: the container's processes are children of the **shim**, not of `dockerd` or `containerd`. `runc` creates the container and exits, and the shim stays behind to hold the container's stdio open and collect its exit status. That is why `containerd`, and with the `live-restore` setting also `dockerd`, can be restarted or upgraded without killing running containers.

### Foreground and detached

- **Foreground (default).** The CLI stays attached, streams stdout and stderr to your terminal, and forwards signals it receives, such as SIGINT from Ctrl-C, to the container's main process. This forwarding is `--sig-proxy`, on by default.
- **Detached (`-d`).** The CLI prints the container ID and exits. Output still goes to the container's log driver, so `docker logs -f` shows it later, and `docker attach` can reconnect to the streams.

## Interactive Terminals: `docker run -it`

![[raw/assets/docker_run_it.png|600]]

The diagram, from iximiuz Labs, shows `docker run -it python:3`. Docker allocates a pseudo-terminal (PTY) for the container, and the CLI keeps your terminal's TTY in sync with it by forwarding input, signals, and window-size changes.

An interactive program such as a shell or the Python REPL needs a real terminal: it wants to show a prompt, edit lines, and receive Ctrl-C as a signal. A container has no terminal of its own, so Docker provides one. The `-t` flag allocates a **pseudo-TTY** and makes it the **controlling terminal** of the containerized application. The `-i` flag keeps the container's stdin open and connected. Together they make the container behave as if it were running directly in your terminal.

| Flags | Behaviour | Typical use |
| --- | --- | --- |
| none | Output is streamed; no input | Batch jobs and servers in the foreground |
| `-i` | Stdin is piped in, but there is no terminal: no prompt, no line editing | `echo data \| docker run -i alpine wc -c` and other scripted input |
| `-t` | A terminal but no input: a prompt appears and you cannot type into it | Rarely useful on its own |
| `-it` | A full interactive session | `docker run -it python:3`, `docker exec -it web sh` |

- **"The input device is not a TTY".** `-t` requires the CLI's own stdin to be a terminal. In CI jobs, cron, or when piping input, drop `-t` and keep only `-i`.
- **One output stream.** A TTY has a single output, so with `-t` the separate [[concepts/linux/standard_streams|stdout and stderr]] streams arrive merged, and lines end in `\r\n`. Do not use `-t` when a script needs to separate or parse the streams.
- **Detaching.** In a `-it` session, Ctrl-P then Ctrl-Q detaches the CLI and leaves the container running. Typing `exit` instead ends the shell, which is the container's main process, and stops the container.

## `docker attach` vs. `docker exec`

`docker attach` merely connects your terminal to the containerized application's stdio streams and starts forwarding signals. `docker exec` starts a **new process** inside the existing container, which iximiuz Labs describes as a "hidden container" inside it: the new process joins all of the target container's namespaces and its cgroup.

| | `docker attach web` | `docker exec -it web sh` |
| --- | --- | --- |
| What you talk to | The container's existing main process (PID 1) | A new process you name |
| Creates a process | No | Yes |
| Streams | The main process's stdio, shared by every attached client | The new process's own stdio |
| Ctrl-C or exit | Reaches PID 1 and can stop the container | Ends only the exec'd process |
| Detach | Ctrl-P Ctrl-Q, if the container was started with `-it` | Exit the process |
| Typical use | Watching or interacting with a foreground app started with `-it` | Debugging: a shell, `ps`, reading config, running a one-off command |

- `docker attach --sig-proxy=false` attaches without forwarding signals, so Ctrl-C detaches instead of stopping the container. `--no-stdin` attaches to output only.
- `docker exec` runs only in a **running** container. It accepts `-u` for the user, `-w` for the working directory, and `-e` for environment variables. The exec'd process is not restarted, and it is killed when the container stops.
- If the image has no shell, as with distroless or scratch-based images, `docker exec ... sh` fails. Exec the tool directly, or use `docker debug` or a debug sidecar.

## Stopping vs. Killing a Container

`docker stop` and `docker kill` both end a running container, but `docker stop` asks the application to shut down and gives it time to clean up, while `docker kill` terminates it immediately. A graceful stop avoids the damage described under Why It Matters, but only if the application actually handles the signal it is sent.

### `docker stop`

1. Sends **SIGTERM** to the container's main process (PID 1), a polite request to shut down.
2. Waits for a grace period, **10 seconds** by default.
3. If the process is still running when the grace period ends, sends **SIGKILL**, which ends it by force.

This gives the application time to clean up resources, save data, and close connections. In short: "Please shut down nicely… okay, now I'll force it."

```bash
docker stop my_container          # SIGTERM, then SIGKILL after 10 s
docker stop -t 30 my_container    # allow 30 s before SIGKILL
```

The first signal and the default timeout can also be set ahead of time. The Dockerfile `STOPSIGNAL` instruction, or `docker run --stop-signal`, replaces SIGTERM with another signal, for example `SIGQUIT` for nginx's graceful shutdown. `docker run --stop-timeout` changes the default grace period for that container.

### `docker kill`

- Sends **SIGKILL** immediately by default, or another signal if one is specified.
- There is no waiting and no chance to clean up. The container is terminated instantly.

In short: "Stop right now. No questions asked."

```bash
docker kill my_container                    # SIGKILL
docker kill --signal=SIGTERM my_container   # send SIGTERM without the SIGKILL fallback
```

With `--signal`, `docker kill` becomes a general way to send any signal to the container's main process, not only to end it. The uses beyond shutdown are covered under Signalling a Running Application below.

### Key differences

| Feature | `docker stop` | `docker kill` |
| --- | --- | --- |
| Default signal | SIGTERM, then SIGKILL | SIGKILL |
| Graceful shutdown | Yes | No |
| Wait time | Yes, 10 s by default (`-t` to change) | No |
| Custom signal | Set beforehand with `STOPSIGNAL` or `--stop-signal` | Chosen per call with `--signal` |
| Typical exit code | 0 or 143 (128 + 15) if the app exits on SIGTERM; 137 if the timeout forced SIGKILL | 137 (128 + 9) |
| Use case | Normal shutdown | Emergency, or a frozen or unresponsive app |

An exit code of 137 on a container you stopped normally is a sign that the application ignored SIGTERM and was killed when the grace period ran out.

- Use **`docker stop`** for normal operations. It is the recommended default.
- Use **`docker kill`** when the container is frozen or unresponsive, when you need immediate termination, or when you want to send a specific signal.

### Why a graceful stop can still take the full timeout

`docker stop` is only graceful if SIGTERM reaches an application that handles it:

- **PID 1 ignores unhandled signals.** Inside a container the main process runs as PID 1, and the kernel does not apply the default "terminate" action to PID 1 for signals it has no handler for. An application that never installs a SIGTERM handler simply keeps running until SIGKILL arrives.
- **Shell form swallows the signal.** With `CMD python -m app`, PID 1 is `/bin/sh`, which does not forward SIGTERM to the app. Use the exec form, `CMD ["python", "-m", "app"]`, as the [[concepts/devops/docker/docker#Writing a Dockerfile|Writing a Dockerfile]] section recommends.
- **Use an init process if needed.** `docker run --init` runs a tiny init as PID 1 that forwards signals and reaps zombie processes, for applications that cannot be fixed.

> [!tip] Check the shutdown time
> Time `docker stop` on your container. If it takes almost exactly 10 seconds, the application is not handling SIGTERM and every stop is really a kill.

### Equivalents elsewhere

- **Docker Compose:** `docker compose stop` and `docker compose kill` behave the same way, and a service's `stop_grace_period` sets its timeout.
- **Kubernetes:** deleting a pod follows the same SIGTERM, grace period, SIGKILL sequence, with a 30-second default (`terminationGracePeriodSeconds`). The [[concepts/devops/kubernetes/kubernetes|Kubernetes]] note covers graceful pod shutdown.

## `docker pause` vs. `docker stop`

When you **pause** a container, all of its processes are suspended. Docker uses the cgroup freezer, so the processes cannot catch or even notice the suspension. They still appear in the host's process list, and the container is technically still **running**: `docker inspect` reports it as both running and paused.

When you **stop** a container, all of its processes are terminated, but its filesystem and metadata remain intact, so you can start it again later.

| | `docker pause` / `docker unpause` | `docker stop` / `docker start` |
| --- | --- | --- |
| Processes | Suspended, still in the host's process list | Terminated |
| Container state | Running and paused | Exited |
| Memory | Kept; the app resumes exactly where it left off | Released; the app starts from scratch |
| CPU | None while paused | None |
| Open connections | Stay open but stop responding | Closed |
| Writable layer and metadata | Kept | Kept |
| How the app sees it | It doesn't; time simply jumps | SIGTERM, then SIGKILL after a grace period |

Pausing is useful for freezing a container briefly without losing its state, for example to take a consistent snapshot: `docker commit` pauses the container by default while it captures the filesystem. How a stop terminates processes is covered under [[concepts/devops/docker/docker_container_techniques#Stopping vs. Killing a Container|Stopping vs. Killing a Container]] above. Only `docker rm` deletes the container's writable layer.

> [!note] Not the Kubernetes pause container
> `docker pause` is unrelated to the "pause" container Kubernetes uses to hold a pod's namespaces, covered in [[concepts/devops/kubernetes/pod_sandbox|Pod Sandbox (Pause Container)]].

## Signalling a Running Application

Signals can be used not only to terminate or forcefully kill applications, but also to influence their behaviour. `docker kill --signal` sends any signal to the container's main process:

```bash
docker kill --signal=SIGHUP web     # same as: docker kill -s HUP web
```

| Application | Signal | Effect |
| --- | --- | --- |
| nginx | `SIGHUP` | Reload the configuration, starting new workers and gracefully retiring the old ones |
| nginx | `SIGUSR1` | Reopen log files, for example after log rotation |
| nginx | `SIGQUIT` | Graceful shutdown; the official image sets it as the stop signal |
| HAProxy | `SIGHUP` | Reload the configuration |
| Gunicorn | `SIGHUP` | Reload the configuration and restart workers gracefully |
| Custom apps | `SIGUSR1` / `SIGUSR2` | Whatever the app implements, often a debug dump such as thread stacks or internal state |

- The signal goes to **PID 1** only. If PID 1 is a shell wrapper that does not forward signals, the application never sees it, for the reasons in [[concepts/devops/docker/docker_container_techniques#Why a graceful stop can still take the full timeout|Why a graceful stop can still take the full timeout]].
- Many tools also offer a command that sends the signal for you, run through `docker exec`. For example, `docker exec web nginx -s reload` makes nginx send SIGHUP to its own master process.

## Getting a Container's Filesystem Out

| Command | Input | Output |
| --- | --- | --- |
| `docker export web -o fs.tar` | A **container** | One flattened tar of its filesystem (image layers plus the writable layer), with no history, environment, or `CMD` |
| `docker save nginx:latest -o image.tar` | An **image** | An archive of every layer plus the image metadata, restorable with `docker load` |
| `docker cp web:/etc/nginx ./nginx` | A container path | Just that file or directory |
| `docker import fs.tar myimage` | An exported tar | A new single-layer image; add `--change 'CMD [...]'` to restore metadata |

### Extracting an image's filesystem

`docker export` works on containers, not images, so to inspect what an image contains, create a container from it without running it:

```bash
docker create --name tmp ghcr.io/iximiuz/labs/redis:latest
mkdir -p ~/imagefs && docker export tmp | tar -x -C ~/imagefs
docker rm tmp
```

`docker create` never starts the container, so this works even for images whose command would fail or that have no shell.

Other tools can export an image without a Docker daemon, but the result needs checking. In the iximiuz Labs exercise this note draws on, `crane export` surprisingly produced incomplete results: comparing the `/root` directory of the actual image filesystem, viewable at ima.ge.cx, with the `~/imagefs` directory produced by `crane export` showed that some files were missing locally. Before relying on an exported filesystem, compare it against a trusted view of the image.

## Related Concepts

- [[concepts/devops/docker/docker|Docker]] — the parent note: images, the daemon architecture these techniques travel through, and the full command reference
- [[concepts/devops/kubernetes/kubernetes|Kubernetes]] — the same SIGTERM-then-SIGKILL contract at pod level, plus `preStop` hooks for draining traffic
- [[concepts/devops/kubernetes/kubernetes_components|Kubernetes Components]] — containerd and the shim from Kubernetes' side, where the same runtime runs pods without `dockerd`
- [[concepts/devops/kubernetes/pod_sandbox|Pod Sandbox (Pause Container)]] — the namespace-holding container that shares a name, but nothing else, with `docker pause`

## References

- [iximiuz Labs: Linux PTY, what powers docker attach](https://iximiuz.com/en/posts/linux-pty-what-powers-docker-attach-functionality/) — pseudo-terminals, `docker run -t`, and attach
- [iximiuz Labs: Freeze and thaw Linux processes](https://labs.iximiuz.com/challenges/linux-freeze-and-thaw-processes) — what pausing does to processes
- [iximiuz Labs: How To Extract Container Image Filesystem Using Docker](https://labs.iximiuz.com/tutorials/extracting-container-image-filesystem)
- [ima.ge.cx: ghcr.io/iximiuz/labs/redis:latest](https://ima.ge.cx/ghcr.io/iximiuz/labs/redis:latest) — a browsable view of the image filesystem used in the export comparison
- [nginx: Controlling nginx](https://nginx.org/en/docs/control.html) — nginx's signal meanings
- The two diagrams are by iximiuz Labs.
