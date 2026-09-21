## Understanding Systemd Targets (Replacing SysVinit Runlevels)

**Introduction**

Modern Linux distributions have largely adopted `systemd` as their init system, replacing the older SysVinit system. One significant change introduced by `systemd` is the concept of **targets**, which serve a similar purpose to the traditional SysVinit **runlevels** but with greater flexibility and power. This document explains what systemd targets are, how they relate to the old runlevels, and how to manage them.

**What were SysVinit Runlevels?**

In SysVinit, runlevels defined discrete operating states for the system. When the system booted, it would enter a specific runlevel, which determined which services were started or stopped. The standard runlevels (0-6) were:

- **Runlevel 0:** Halt (system shutdown)
- **Runlevel 1 (or S):** Single-user mode (for maintenance)
- **Runlevel 2:** Multi-user mode without networking services (rarely used in modern systems)
- **Runlevel 3:** Full multi-user mode with networking services (text-based login, common for servers)
- **Runlevel 4:** User-definable (often unused)
- **Runlevel 5:** Full multi-user mode with a graphical display manager (graphical login, common for desktops)
- **Runlevel 6:** Reboot

Switching between runlevels would stop services associated with the old runlevel and start services associated with the new one in a defined sequence.

**Introducing Systemd Targets**

Systemd replaces the rigid, sequential runlevel system with **targets**. A target is a `systemd` unit file (`.target` extension) that groups other `systemd` units (like services, sockets, mount points, etc.) and serves as a **synchronization point**.

Instead of the system being _in_ a single runlevel, `systemd` aims to reach a set of desired targets. Targets can depend on other targets, allowing for more complex and parallel startup sequences compared to the strictly numerical runlevels of SysVinit.

**Mapping SysVinit Runlevels to Systemd Targets**

For compatibility and ease of transition, `systemd` provides targets that are symbolic links to targets functionally equivalent to the old runlevels. While the underlying mechanism is different, these mappings help users familiar with runlevels understand the corresponding systemd states:

|SysVinit Runlevel|Systemd Target (Compatibility Link)|Corresponding Functional Target|Description|
|---|---|---|---|
|**0**|`runlevel0.target`|`poweroff.target`|Shuts down the system.|
|**1**|`runlevel1.target`|`rescue.target`|Sets up a rescue shell.|
|**2**|`runlevel2.target`|`multi-user.target`|Multi-user, non-graphical.|
|**3**|`runlevel3.target`|`multi-user.target`|Multi-user, non-graphical.|
|**4**|`runlevel4.target`|`multi-user.target`|Multi-user, non-graphical.|
|**5**|`runlevel5.target`|`graphical.target`|Multi-user, graphical.|
|**6**|`runlevel6.target`|`reboot.target`|Reboots the system.|
The most commonly used functional targets corresponding to multi-user states are `multi-user.target` and `graphical.target`.

**Key Systemd Targets**

Here are descriptions of the most important systemd targets you'll encounter:

- **`poweroff.target`**: Achieves a state where the system is powered off.
- **`reboot.target`**: Achieves a state where the system is ready to reboot.
- **`rescue.target`**: Provides a minimal environment with a rescue shell, typically used for system repair when the system cannot reach `multi-user.target`. It's more functional than `emergency.target`.
- **`emergency.target`**: Provides the most minimal shell environment possible, often not even mounting the root filesystem read-write. Used for critical troubleshooting when `rescue.target` is inaccessible.
- **`multi-user.target`**: A state where the system is configured for multiple users, including networking and non-graphical logins (text consoles). This is a common default for servers.
- **`graphical.target`**: A state that includes `multi-user.target` and additionally starts a display manager to provide a graphical login and desktop environment. This is a common default for desktop systems.
- **`default.target`**: This is the target that `systemd` attempts to reach by default upon booting. It is typically a symbolic link to either `graphical.target` or `multi-user.target`.
**Managing Targets with `systemctl`**

The `systemctl` command is used to interact with `systemd`, including managing targets.

- **Get the default target:**
```bash
systemctl get-default
```

- **Set the default target:** (Requires root privileges)
```bash
systemctl set-default multi-user.target
```
or
```bash
systemctl set-default graphical.target
```

This modifies the `/etc/systemd/system/default.target` symlink.

- **Switch to a target (Isolate):** (Requires root privileges)
```bash
systemctl isolate graphical.target
```
or
```bash
systemctl isolate multi-user.target
```

The `isolate` command switches to the specified target, stopping all services not required by the new target and starting all services required _only_ by the new target. This is the command equivalent to changing runlevels in SysVinit. _Be cautious_ when using `isolate` on remote systems, as switching to a target that doesn't enable networking might disconnect you.

- **List active targets:**
```bash
systemctl list-units --type=target
```

- **View dependencies of a target:**
```bash
systemctl list-dependencies graphical.target
```
or
```bash
systemctl list-dependencies multi-user.target
```

This shows which units (services, other targets, etc.) are pulled in by the specified target.

**Advantages of Systemd Targets over SysVinit Runlevels**

Systemd targets offer several advantages:
- **Dependency-Based Activation:** Units start based on their dependencies being met, rather than a fixed order within a runlevel.
- **Parallelism:** `systemd` can start many services concurrently based on dependencies, leading to faster boot times. SysVinit runlevels were largely sequential.
- **Flexibility:** Targets can depend on other targets, and multiple targets can be active simultaneously. This allows for more complex and granular system states.
- **Clearer Relationships:** Unit files explicitly define their dependencies and relationships, making it easier to understand the boot process.