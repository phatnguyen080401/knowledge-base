### `docker stop`

- Sends a **SIGTERM** signal first (polite request to stop).
- Waits for a grace period (default: **10 seconds**).
- If the container doesn’t stop in time, it then sends **SIGKILL** (force kill).
- Allows your app to **clean up resources**, save data, close connections, etc.

👉 Think of it as: _“Please shut down nicely… okay, now I’ll force it.”_

You can customize the wait time:

```
docker stop -t 30 my_container
```

---

### 💥 `docker kill`

- Sends a **SIGKILL** signal immediately (or another signal if specified).
- No waiting, no cleanup.
- The container is **terminated instantly**.

👉 Think of it as: _“Stop right now. No questions asked.”_

You can also send different signals:

```
docker kill --signal=SIGTERM my_container
```

---

### ⚖️ Key Differences

|Feature|`docker stop` 🧊|`docker kill` 💥|
|---|---|---|
|Default signal|SIGTERM → SIGKILL|SIGKILL|
|Graceful shutdown|✅ Yes|❌ No|
|Wait time|Yes (default 10s)|No|
|Use case|Normal shutdown|Emergency / stuck apps|

---

### 🧠 When to use which?

- Use **`docker stop`** for **normal operations** (recommended).
- Use **`docker kill`** when:
    - The container is frozen or unresponsive
    - You need immediate termination