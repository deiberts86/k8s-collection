# ETCD Useful Commands for Rancher RKE2
- Environment: RKE2 Kubernetes

## Inside ETCD Container
* Exect into etcd pod for these commands: (note: some commands may not work due to missing binaries within the container itself)

```sh
export ETCDCTL_API=3
export ETCDCTL_CACERT=/var/lib/rancher/rke2/server/tls/etcd/server-ca.crt
export ETCDCTL_CERT=/var/lib/rancher/rke2/server/tls/etcd/server-client.crt
export ETCDCTL_KEY=/var/lib/rancher/rke2/server/tls/etcd/server-client.key
```

## From Server CLI
- Login to a Bastion Host and execute these commands

* How to Check DB Size:

```sh
kubectl -n kube-system exec etcd-rke2-node01 -- sh -c "ETCDCTL_ENDPOINTS='https://127.0.0.1:2379' ETCDCTL_CACERT='/var/lib/rancher/rke2/server/tls/etcd/server-ca.crt' ETCDCTL_CERT='/var/lib/rancher/rke2/server/tls/etcd/server-client.crt' ETCDCTL_KEY='/var/lib/rancher/rke2/server/tls/etcd/server-client.key' ETCDCTL_API=3 ls -lrth /var/lib/rancher/rke2/server/db/etcd/member/snap" | grep db
```

* Check Cluster Members:

```sh
kubectl -n kube-system exec etcd-rke2-node01 -- sh -c "ETCDCTL_ENDPOINTS='https://127.0.0.1:2379' ETCDCTL_CACERT='/var/lib/rancher/rke2/server/tls/etcd/server-ca.crt' ETCDCTL_CERT='/var/lib/rancher/rke2/server/tls/etcd/server-client.crt' ETCDCTL_KEY='/var/lib/rancher/rke2/server/tls/etcd/server-client.key' ETCDCTL_API=3  etcdctl endpoint status -w table --cluster" > /var/tmp/
```

- In JSON Format:

```sh
kubectl -n kube-system exec etcd-rke2-node01 -- sh -c "ETCDCTL_ENDPOINTS='https://127.0.0.1:2379' ETCDCTL_CACERT='/var/lib/rancher/rke2/server/tls/etcd/server-ca.crt' ETCDCTL_CERT='/var/lib/rancher/rke2/server/tls/etcd/server-client.crt' ETCDCTL_KEY='/var/lib/rancher/rke2/server/tls/etcd/server-client.key' ETCDCTL_API=3  etcdctl endpoint status -w json --cluster"
```

* What data is taking up the most space:

```sh
kubectl -n kube-system exec etcd-rke2-node01 -- sh -c "ETCDCTL_ENDPOINTS='https://127.0.0.1:2379' ETCDCTL_CACERT='/var/lib/rancher/rke2/server/tls/etcd/server-ca.crt' ETCDCTL_CERT='/var/lib/rancher/rke2/server/tls/etcd/server-client.crt' ETCDCTL_KEY='/var/lib/rancher/rke2/server/tls/etcd/server-client.key' ETCDCTL_API=3 etcdctl get /registry --prefix --keys-only" | grep -v ^$ | awk -F '/'  '{ h[$3]++ } END {for (k in h) print h[k], k}' | sort -nr
```
- Optional Flags:
  - --dial-timeout 15s
  - --command-timeout 20s

