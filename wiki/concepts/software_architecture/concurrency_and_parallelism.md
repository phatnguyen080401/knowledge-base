---
title: Concurrency and Parallelism
tags: [software-architecture, concurrency, concurrency-control]
created: 2026-10-21 14:47:07
updated: 2026-10-21 14:47:07
---

# Concurrency and Parallelism

Concurrency is the ability of a system to make progress on several tasks whose lifetimes overlap; parallelism is the ability to execute several tasks at literally the same instant on separate hardware. Concurrency is a property of the *program's structure*, parallelism a property of the *machine it runs on* — a single-core laptop runs thousands of concurrent tasks and zero parallel ones. Choosing between threads, processes, and an event loop is a [[concepts/software_architecture/software_architecture|Software Architecture]] decision, because it fixes what state can be shared and therefore which bugs are possible.

## Why It Matters

- **The model is chosen once and assumed everywhere.** Code written for a single-threaded event loop breaks the moment a blocking call enters it; code written for shared-memory threads cannot be lifted into processes without rewriting how it passes data. Retrofitting is a rewrite, not a refactor.
- **It decides which bugs are reachable.** Shared mutable state admits race conditions, deadlocks, and torn reads that are timing-dependent and therefore invisible to ordinary tests. Message passing and process isolation make most of those unrepresentable.
- **Speedup is bounded, and usually by the serial part.** Amdahl's law puts the ceiling at $S = \frac{1}{(1-p) + p/N}$ for a workload that is a fraction $p$ parallelizable across $N$ workers. At $p = 0.9$, infinite cores buy a 10× speedup and nothing more; the lock everything contends on is often the $1-p$.
- **It is where latency and throughput diverge.** Concurrency hides waiting, raising throughput without making any single operation faster. Parallelism can cut the latency of one operation, but only if that operation decomposes.

## Concurrency vs. Parallelism

| | Concurrency | Parallelism |
| --- | --- | --- |
| Question it answers | How is work *structured* into independently progressing tasks? | How much work executes *simultaneously*? |
| Needs | An interleaving mechanism — scheduler, event loop | Multiple execution units — cores, machines, GPUs |
| Target workload | I/O-bound: waiting on network, disk, database | CPU-bound: computation that saturates a core |
| Wins by | Overlapping waiting with useful work | Dividing the computation |
| Fails by | Blocking the scheduler; unbounded task growth | Coordination overhead, memory bandwidth, Amdahl's ceiling |

The practical classification is the first thing to settle, because it eliminates two of the three models immediately:

- **I/O-bound** — the process is mostly idle, waiting on something outside it. The remedy is concurrency; parallelism adds nothing because the cores were never busy.
- **CPU-bound** — the process is pegged on computation. The remedy is parallelism across cores or machines; an event loop only reorders the same work.
- **Mixed** — the common real case. Run an event loop or thread pool for the I/O and offload the CPU-bound spans to a process pool or a native library that leaves the interpreter.

## Multithreading

Threads are independent execution contexts **inside one process**, sharing its address space: the same heap, the same globals, the same open file descriptors. Each has its own stack, registers, and instruction pointer. The operating system schedules them pre-emptively, so a thread can be suspended between any two machine instructions.

- **Cheap to create and switch** relative to processes — no new address space, no page-table swap — which is why thread pools are the default for many concurrent server workloads.
- **Shared memory is the feature and the defect.** Passing data costs nothing because there is nothing to pass, but every mutable object reachable from two threads is a potential race (see below).
- **Pre-emption makes bugs non-deterministic.** The scheduler may switch threads anywhere, so an interleaving that corrupts state may occur once in $10^6$ runs and only under production load.
- **Scaling limits.** Each thread reserves stack space (commonly ~1 MB virtual by default), and context switches cost µs-scale work plus cache pollution. Tens of thousands of threads is a different proposition from tens of thousands of event-loop tasks.

In Python specifically, `threading` gives real OS threads, but CPython serializes bytecode execution with the [[concepts/software_architecture/global_interpreter_lock|Global Interpreter Lock (GIL)]] — so threads overlap *waiting*, not *computing*. They remain the right tool for blocking I/O and for calling C extensions that release the lock.

> [!warning] Threads do not make Python code faster unless it leaves the interpreter
> A CPU-bound function run in four threads on four cores takes roughly as long as running it in one, plus contention overhead. The work must go to processes, to a native library, or to a free-threaded build.

## Multiprocessing

Separate processes, each with its own address space, its own interpreter or runtime, and its own memory manager. The OS scheduler places them on any available core, so they execute in true parallel.

- **Isolation is the point.** No shared mutable state means no data races by construction, and a crash or memory leak is contained to one worker.
- **Communication is explicit and costs serialization.** Arguments and results cross the boundary through pipes, sockets, or shared-memory blocks, which in Python means pickling — so large objects, and anything unpicklable (open sockets, lambdas, local closures), become the limiting factor.
- **Start-up is expensive.** A new process pays for its own runtime initialization and module imports; pools exist so that cost is paid once per worker, not once per task.
- **Start methods differ and change behaviour.** `fork` clones the parent cheaply but copies locks and threads in whatever state they were in, which deadlocks in a parent that already had threads. `spawn` starts a clean interpreter and re-imports the entry module — safe, slower, and the reason multiprocessing code must guard its entry point with `if __name__ == "__main__":`. `forkserver` forks from a small, thread-free helper process to get most of fork's speed without its hazards.
- **Shared memory when copying is the bottleneck.** `multiprocessing.shared_memory` and memory-mapped arrays let workers read the same buffer without serializing it — at which point the data races threads have come back, and so do the locks.

The same reasoning extends past one machine: a process pool and a distributed worker pool differ in how much the coordination costs and in whether a failure is a lost worker or a network partition — see [[concepts/databases/cap_theorem|CAP Theorem]] for what that boundary makes impossible.

## Asyncio and the Event Loop

Asyncio is **cooperative, single-threaded concurrency**. One thread runs an event loop that holds a set of tasks; each task runs until it reaches an `await` on something not yet ready, at which point it yields control back to the loop, which runs the next ready task. The OS never pre-empts — the switch points are exactly the `await` expressions, and they are visible in the source.

```python
import asyncio

async def fetch(client, url):          # a coroutine: calling it returns an object, runs nothing
    return await client.get(url)       # yields to the loop while the socket is pending

async def main(urls):
    async with asyncio.TaskGroup() as tg:          # 3.11+: structured concurrency
        tasks = [tg.create_task(fetch(client, u)) for u in urls]
    return [t.result() for t in tasks]

asyncio.run(main(urls))
```

- **It scales with waiting, not with work.** Tens of thousands of in-flight sockets cost a task object each, not a thread stack each. This is why it dominates for proxies, chat servers, scrapers, and fan-out API clients.
- **Race conditions shrink but do not vanish.** State cannot change *mid-statement*, since there is no pre-emption, but it can change across any `await` — the check-then-act hazard survives if the check and the act straddle one. `asyncio` ships its own `Lock`, `Semaphore`, and `Queue` for exactly that.
- **One blocking call stalls everything.** A synchronous `requests.get`, a CPU-heavy loop, or a plain `time.sleep` inside a coroutine freezes every other task on the loop. The escape hatches are `asyncio.to_thread` for blocking I/O and a process pool executor for computation.
- **It is contagious.** An `async def` can only be awaited from async context, so the colour of a function propagates up the call stack until it reaches `asyncio.run`. Mixing paradigms is a real architectural cost, not a style preference.
- **The ecosystem must cooperate.** Every library on the hot path needs an async-native client; a synchronous database driver negates the model.

### Choosing a model

| | `threading` | `multiprocessing` | `asyncio` |
| --- | --- | --- | --- |
| Parallel CPU work | No (in CPython) | Yes | No |
| Overlaps blocking I/O | Yes | Yes | Yes |
| Memory per unit | ~MB stack | Full process | ~KB task object |
| Shared state | Implicit, unsafe | None by default | Implicit, safe between `await`s |
| Switch points | Anywhere (pre-emptive) | Anywhere | Only at `await` |
| Works with legacy blocking libraries | Yes | Yes | No |
| Typical use | Blocking I/O, C-extension calls | CPU-bound batch work | High-fan-out network I/O |

## Race Conditions

A race condition exists when the result depends on the *timing* of operations that were assumed to be indivisible. The canonical form is **read–modify–write**: an increment compiles to a load, an add, and a store, and two workers can interleave between them.

| | Thread A | Thread B | `counter` |
| --- | --- | --- | --- |
| 1 | read `counter` → 0 | | 0 |
| 2 | | read `counter` → 0 | 0 |
| 3 | compute `0 + 1` | | 0 |
| 4 | | compute `0 + 1` | 0 |
| 5 | write 1 | | 1 |
| 6 | | write 1 | **1** |

Two increments, one lost. The GIL does not prevent this: it serializes *bytecode*, and `counter += 1` is several bytecodes with a legal switch point between them.

The recurring shapes:

- **Lost update** — the case above; the later write overwrites a value it never saw.
- **Check-then-act** — `if key not in cache: cache[key] = compute()`. Both workers see the miss and both compute, or worse, both initialize. In async code the gap is an `await`; in threads it is anywhere.
- **Time-of-check to time-of-use (TOCTOU)** — the state verified (a file's permissions, an account balance, a reservation count) changes before it is used. A security-relevant subclass, and the same hazard that write skew is in [[concepts/databases/isolation_levels|Transaction Isolation Levels]].
- **Memory visibility and reordering** — in languages with a relaxed memory model (C++, Java, Go, Rust), a write by one thread is not guaranteed to be visible to another without a synchronizing operation, and the compiler or CPU may reorder independent instructions. Correctness requires the language's memory model, not intuition about source order.
- **Non-atomic composite state** — two fields that must change together (a balance and its ledger entry) read in the middle of an update yield a state that was never valid.

Races are hard precisely because they are **not reproducible**: the failing interleaving may need load, a specific core count, or an unlucky GC pause. Detection belongs to tooling — thread sanitizers, race detectors, stress tests with randomized scheduling — not to code review alone.

## Concurrency Control

Concurrency control is the set of mechanisms that restore the illusion of indivisibility. Databases solve the same problem with locking, MVCC, and optimistic validation — see [[concepts/databases/acid|ACID (Atomicity, Consistency, Isolation, Durability)]] — and in-process primitives are the same ideas without durability.

### Primitives

| Primitive | Guarantees | Use it for |
| --- | --- | --- |
| **Mutex / `Lock`** | At most one holder at a time | The default: a critical section over shared mutable state |
| **Reentrant lock (`RLock`)** | Same holder may re-acquire | Recursive call paths that re-enter their own critical section |
| **Semaphore** | At most $N$ holders | Bounding concurrency: connection pools, rate limits, in-flight requests |
| **Condition variable** | Wait until a predicate holds, with the lock released while waiting | Producer–consumer handoff without busy-waiting |
| **Event / latch** | One-shot broadcast of "it happened" | Startup gates, shutdown signals |
| **Barrier** | All $N$ participants arrive before any proceeds | Phase-synchronized parallel computation |
| **Read–write lock** | Many readers or one writer | Read-dominated state, where exclusive locking wastes throughput |
| **Atomic / compare-and-swap** | A single indivisible read-modify-write | Counters and flags, and the basis of lock-free structures |
| **Queue** | Thread-safe handoff with back-pressure | Replacing shared state with message passing entirely |

### Pessimistic or optimistic

**Pessimistic** control takes the lock first and assumes conflict: correct, simple, and it serializes. **Optimistic** control proceeds unsynchronized, validates at the end (a compare-and-swap, a version check), and retries on conflict: it scales when conflicts are rare and collapses into a retry storm when they are not. The deciding question is the contention rate, which is why the same codebase often uses both.

A third option beats both where it applies: **do not share**. Immutable values, copies per worker, thread-local state, and message passing through queues or channels — the actor model's position — make the race unrepresentable rather than guarded. `multiprocessing` gets this for free; threads have to choose it.

### Deadlock and its relatives

Deadlock needs all four Coffman conditions simultaneously, so breaking any one prevents it:

1. **Mutual exclusion** — the resource cannot be shared.
2. **Hold and wait** — a holder requests another resource without releasing what it has.
3. **No pre-emption** — a lock cannot be taken away from its holder.
4. **Circular wait** — a cycle of holders each waiting on the next.

The practical defences, in order of reliability: **acquire locks in a single global order** everywhere (kills circular wait); **take all locks at once or none** (kills hold-and-wait); **use timeouts and back off** (makes the wait finite, at the cost of retry logic); **shrink critical sections** so the window barely exists.

Related failures that locking alone does not cover:

- **Livelock** — threads keep responding to each other and none progresses. Retries without randomized back-off are the usual cause.
- **Starvation** — a thread is perpetually denied a resource it is entitled to, typically under an unfair lock or a writer behind a stream of readers.
- **Priority inversion** — a low-priority holder blocks a high-priority waiter; the fix is priority inheritance in the lock implementation.
- **Lock convoying** — every thread queues on one hot lock and the system degrades to serial throughput plus switching overhead. Amdahl's $1-p$, made of a mutex.

> [!tip] The cheapest lock is the one you never take
> Before tuning a primitive, ask whether the state has to be shared at all. Partitioning work so each worker owns its data removes the critical section instead of optimizing it.

## Common Pitfalls

- **Picking the model from the language's fashion rather than the workload.** `asyncio` for CPU-bound work and `multiprocessing` for a chatty I/O client are both slower than doing nothing.
- **Blocking the event loop.** The single most common asyncio defect, and it presents as mysterious tail latency across unrelated endpoints.
- **Assuming an operation is atomic because it is one line.** `+=`, `list.append` followed by a length check, and dictionary get-then-set are all composite.
- **Unbounded concurrency.** Spawning a task per inbound item with no semaphore or queue bound converts a traffic spike into memory exhaustion downstream.
- **Testing concurrency serially.** A test suite that never overlaps operations proves nothing about the interleavings production will find.
- **Sharing a connection, session, or cursor across workers.** Most database and HTTP clients are not safe to share; the pool is the shared object, not the connection.
- **Hand-rolling a lock-free structure.** Correct lock-free code requires a memory model, not cleverness. Use the standard library's.

## Related Concepts

- [[concepts/software_architecture/global_interpreter_lock|Global Interpreter Lock (GIL)]] — why CPython threads overlap I/O but not computation, and what is changing
- [[concepts/software_architecture/software_architecture|Software Architecture]] — the execution model is one of the structural decisions recorded there, and the sync-vs-async choice it names
- [[concepts/databases/acid|ACID (Atomicity, Consistency, Isolation, Durability)]] — the same coordination problem solved durably, where isolation is what a lock buys
- [[concepts/databases/isolation_levels|Transaction Isolation Levels]] — anomalies like lost update and write skew are database-scale race conditions, with the same check-then-act shape
- [[concepts/databases/cap_theorem|CAP Theorem]] — what coordination costs once the workers are on separate machines and the network can fail

## References

- [`asyncio` — Asynchronous I/O](https://docs.python.org/3/library/asyncio.html) — event loop, tasks, and synchronization primitives
- [`multiprocessing` — Process-based parallelism](https://docs.python.org/3/library/multiprocessing.html) — start methods, pools, and shared memory
- Coffman, Elphick, Shoshani, "System Deadlocks", *ACM Computing Surveys*, 1971 — the four necessary conditions
