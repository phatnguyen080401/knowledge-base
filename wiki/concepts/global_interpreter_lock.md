---
title: Global Interpreter Lock (GIL)
tags: [software-architecture, concurrency, concurrency-control, python]
created: 2026-10-21 14:47:07
updated: 2026-10-21 14:47:07
---

# Global Interpreter Lock (GIL)

The Global Interpreter Lock is a single mutex in the CPython interpreter that must be held by any thread executing Python bytecode, so exactly one thread runs Python code at a time no matter how many cores are available. It is an implementation detail of CPython rather than a property of the Python language, and it is the reason the threading half of [[concepts/concurrency_and_parallelism|Concurrency and Parallelism]] behaves differently in Python than in Java, Go, or C++.

## Why It Exists

CPython manages memory with **reference counting**: every object carries a count of how many references point at it, updated on essentially every assignment, argument pass, and scope exit. Those updates are not atomic. Two threads incrementing and decrementing the same count without synchronization will eventually lose an update, and an object freed one reference too early is a use-after-free in the interpreter itself.

A single interpreter-wide lock solves that with one acquisition instead of one atomic operation per object touch, which buys three things the project has repeatedly chosen to keep:

- **Fast single-threaded execution.** Fine-grained locking or atomic refcounts cost on every object operation, including in the overwhelming majority of programs that are single-threaded. Guido van Rossum's standing condition for removing the GIL was that single-threaded performance must not regress.
- **Simple C extensions.** An extension author can touch Python objects without writing any locking, because holding the GIL is the contract for calling into the C API. Decades of extensions depend on that assumption.
- **A simple interpreter.** Interpreter-internal structures — the object allocator, interned strings, type caches — need no per-structure lock.

> [!warning] The GIL protects the interpreter, not your data
> It guarantees that interpreter internals stay consistent. It guarantees nothing about *your* invariants: `counter += 1` is several bytecodes, and a thread switch between them loses an update exactly as in any other language. Application code still needs the locks from [[concepts/concurrency_and_parallelism#Concurrency Control|Concurrency Control]].

## How It Schedules

Since CPython 3.2 the GIL is time-sliced rather than instruction-counted. The holding thread is asked to drop the lock after a **switch interval**, by default 5 ms, readable and settable with `sys.getswitchinterval()` and `sys.setswitchinterval()`. Earlier versions used a check interval of 100 bytecodes, which gave worse fairness and more pointless hand-offs.

The lock is also released voluntarily, and this is what makes threads useful at all:

| Situation | GIL held? | Consequence |
| --- | --- | --- |
| Executing Python bytecode | Yes | Only one thread computes at a time |
| Blocking I/O — socket, file, `time.sleep` | **Released** | Other threads run while this one waits |
| C extension inside `Py_BEGIN_ALLOW_THREADS` | **Released** | NumPy, compression, hashing and crypto can run in true parallel |
| Calling back into the C API | Must be re-acquired | The extension blocks until the lock is free |

So the rule of thumb is: **threads parallelize waiting and native code, never Python-level computation**.

## What It Costs

- **CPU-bound threads do not scale.** Four threads on four cores finish a pure-Python workload in roughly the single-threaded time, plus contention — sometimes measurably *worse*, because every forced hand-off is a context switch and a cache miss for no gain.
- **Latency interference.** A CPU-bound thread holds the lock for a full switch interval at a time, so an I/O thread that just became ready waits on it. A background computation inflates the tail latency of an unrelated request handler.
- **It hides design errors until deployment.** Code that "worked fine" threaded on a developer's laptop was being saved by the GIL's coarse serialization, not by correct synchronization.

What it does **not** cost: asyncio throughput (a single thread was going to run one task at a time regardless), multiprocess throughput (each process has its own GIL), or anything in workloads dominated by native libraries.

## Working Around It

In rough order of how often it is the right answer:

1. **Use processes.** `multiprocessing` or `concurrent.futures.ProcessPoolExecutor` gives one interpreter and one GIL per worker, and real parallelism. The price is serialization at the boundary and no shared mutable state.
2. **Leave the interpreter.** NumPy, Polars, PyArrow, scikit-learn, and most compression, hashing, and I/O libraries release the GIL around their heavy sections. Vectorizing a loop into a native call both removes the Python overhead and makes the remaining threads parallel.
3. **Write the hot path as an extension.** C, Cython with `nogil`, Rust via PyO3 — each can drop the lock for a self-contained computation that does not touch Python objects.
4. **Use subinterpreters.** PEP 684 gave each subinterpreter its own GIL in CPython 3.12 (C API only), and PEP 734 exposes them to Python code as `concurrent.interpreters` in 3.14. Isolation is close to a process at a fraction of the start-up cost, but objects cannot simply be shared across interpreters.
5. **Use a free-threaded build.** PEP 703 removes the GIL outright, replacing it with biased and deferred reference counting plus per-object locking. It shipped as an experimental, separately compiled binary (`python3.13t`) in CPython 3.13 and became an officially supported — but still non-default — build in 3.14. The costs are real: a single-threaded performance penalty, and C extensions must explicitly declare support or the runtime falls back to enabling the GIL.

## Other Implementations

The GIL belongs to CPython, not to Python. Jython (JVM) and IronPython (.NET) have no GIL, because they inherit garbage collection from their host runtime and never needed reference counting. PyPy has a GIL for the same refcount-adjacent reasons CPython does. Any code whose correctness depends on "the GIL makes this atomic" is therefore not portable Python — it is CPython-specific, and it stops being true on a free-threaded build of CPython too.

## Common Misconceptions

- **"The GIL makes Python thread-safe."** It makes the *interpreter* memory-safe. Your dictionary update spanning two statements is as racy as ever.
- **"The GIL means threads are useless."** They are the standard tool for blocking I/O and for native libraries that release it. Only CPU-bound pure-Python work is excluded.
- **"Removing the GIL makes Python fast."** It removes a ceiling on multi-core scaling. Single-threaded code gets slower, not faster, and the locks the GIL was implicitly providing now have to be written explicitly.
- **"Asyncio avoids the GIL."** Asyncio runs on one thread, so the GIL is simply never contended. It is irrelevant there, not avoided.

## Related Concepts

- [[concepts/concurrency_and_parallelism|Concurrency and Parallelism]] — the parent note: the three execution models, race conditions, and the synchronization primitives this lock does not replace
- [[concepts/software_architecture|Software Architecture]] — a runtime constraint that propagates into component boundaries, since "run it in a thread" stops being an available answer
- [[concepts/isolation_levels|Transaction Isolation Levels]] — the database analogue of coarse locking: strong serialization bought with throughput

## References

- [PEP 703 — Making the Global Interpreter Lock Optional in CPython](https://peps.python.org/pep-0703/)
- [PEP 684 — A Per-Interpreter GIL](https://peps.python.org/pep-0684/)
- [PEP 734 — Multiple Interpreters in the Stdlib](https://peps.python.org/pep-0734/)
- [`sys.setswitchinterval`](https://docs.python.org/3/library/sys.html#sys.setswitchinterval) — the switch interval and its default
- [`threading` — Thread-based parallelism](https://docs.python.org/3/library/threading.html) — the CPython note on the GIL and when threads still help
