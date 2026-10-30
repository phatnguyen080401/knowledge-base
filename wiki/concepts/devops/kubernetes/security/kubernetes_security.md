---
title: Kubernetes Security
tags: [devops, access-management, access-control, kubernetes, overview]
created: 2026-10-30 21:58:54
updated: 2026-10-30 23:11:13
---

# Kubernetes Security

Kubernetes security means protecting a [[concepts/devops/kubernetes/kubernetes|Kubernetes]] cluster's API, nodes, and workloads from misuse, and finding an attacker who is already inside. This hub maps where a cluster can be attacked and links to one note per attack technique, each covering what it gives the attacker, how to detect it, and how to reduce the risk.

> [!info] Scope of this note
> Attack surfaces, and an index of the attack-technique notes in this folder. The everyday controls (RBAC, Pod Security Standards, admission policies, image scanning) are summarized in the hub's Security section. The kubelet's credentials and the hardening of its API are in [[concepts/devops/kubernetes/kubelet_tls_bootstrapping|Kubelet TLS Bootstrapping]].

## Why It Matters

- **The API server sees only part of the cluster.** `kubectl`, dashboards, admission policies, and audit logs all work from what passes through the API server. A node runs whatever its kubelet and container runtime are told to run, including workloads the API never hears about.
- **Some techniques are for after a break-in.** An attacker with a foothold, such as a compromised pod or root on a node, wants to gain more privileges, reach other nodes, or stay hidden. Prevention alone does not cover that; the cluster also needs detection.
- **Detection often means comparing two views.** A recurring check is to compare what a node actually runs with what the API believes it runs. A mismatch is a strong signal.

## Attack Surface

| Surface | What an attacker who controls it gets | Main controls | Covered in |
| --- | --- | --- | --- |
| **kube-apiserver** | Whatever their RBAC permissions allow, across the cluster | Authentication, least-privilege RBAC, admission policies, audit logging | [[concepts/devops/kubernetes/kubernetes\|Kubernetes]], [[concepts/devops/kubernetes/kubernetes_components\|Kubernetes Components]] |
| **etcd** | Every object, including Secrets, which are stored unencrypted unless encryption at rest is configured | Encryption at rest, ideally through a KMS provider; snapshots protected like the cluster itself | [[concepts/devops/kubernetes/kubernetes_components\|Kubernetes Components]] |
| **kubelet API (port 10250)** | With anonymous access on and `AlwaysAllow` authorization, commands in every pod on that node | Anonymous access off, webhook authorization, client certificates | [[concepts/devops/kubernetes/kubelet_tls_bootstrapping\|Kubelet TLS Bootstrapping]] |
| **Bootstrap tokens** | A node identity under any node name, because the built-in approver checks only the request's shape | Short lifetimes; tokens deleted after the join | [[concepts/devops/kubernetes/kubelet_tls_bootstrapping\|Kubelet TLS Bootstrapping]] |
| **A node's static pod directory** | Any container on that node, including one the API never lists | Root-only access, no `hostPath` volumes, file monitoring | [[concepts/devops/kubernetes/security/hidden_static_pods\|Hidden Static Pods]] |

## Attack Techniques

Each technique has its own note in this folder, covering what it gives an attacker, what it requires, how to detect it, and how to reduce the risk.

| Technique | Surface | Attacker needs | Effect |
| --- | --- | --- | --- |
| [[concepts/devops/kubernetes/security/hidden_static_pods\|Hidden Static Pods]] | A node's static pod directory | Root on the node, or a pod that mounts the directory through `hostPath` | A pod that runs on the node but never appears in the API |

## Related Concepts

- [[concepts/devops/kubernetes/security/hidden_static_pods|Hidden Static Pods]] — the first technique: persistence through a static pod the API cannot list
- [[concepts/devops/kubernetes/static_pod_vs_normal_pod|Static Pod vs. Normal Pod]] — the kubelet's file-defined pods, whose manifest directory is one of the surfaces above
- [[concepts/devops/kubernetes/kubelet_tls_bootstrapping|Kubelet TLS Bootstrapping]] — node identities, `NodeRestriction`, and the kubelet API, three of the surfaces above
- [[concepts/devops/kubernetes/kubernetes_components|Kubernetes Components]] — the API server's authentication and admission pipeline, and etcd encryption at rest
- [[concepts/devops/kubernetes/kubernetes|Kubernetes]] — the hub: RBAC, Pod Security Standards, admission control, and supply-chain scanning
- [[concepts/devops/observers|Observers]] — node-level telemetry and runtime monitoring that catch what the API does not show

## References

- [Kubernetes security concepts](https://kubernetes.io/docs/concepts/security/) — the official overview
