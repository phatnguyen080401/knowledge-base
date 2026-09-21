Static Pod vs Normal Pod
Containerd pause container (pod sandbox) used to hold a namespace, share environment

etcd use RAFT consensus algorithm

Joining nodes to the cluster: use TLS bootstrapping, a process that allows kubelet to use temporary token to request a proper client certificate from the API server. No need to generate CA manually. Use only for initial joining process.

Invisible pod: create pod in non-existing namespace, this allows attackers to remain hidden in the compromised cluster. Detect: using kubectl debug node to catch unknown process running on a node

Kubelet: client and server certificate are different used.

veth pair