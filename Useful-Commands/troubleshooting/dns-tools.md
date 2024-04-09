# DNS Cluster Tools
  * Reference Found here: [RancherDocs-DNS](https://ranchermanager.docs.rancher.com/troubleshooting/other-troubleshooting-tips/dns)
---
## Create Manifest and Execute

```bash
kubectl apply -f -<<EOF
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: dnstest
  namespace: kube-system
spec:
  selector:
      matchLabels:
        name: dnstest
  template:
    metadata:
      labels:
        name: dnstest
    spec:
      tolerations:
      - operator: Exists
      containers:
      - image: busybox:1.28
        imagePullPolicy: Always
        name: alpine
        command: ["sh", "-c", "tail -f /dev/null"]
        terminationMessagePath: /dev/termination-log
EOF
```
* Check to see if RKE2 CoreDNS has valid DNS Nameservers and Search Domains
  - Note, the pod will terminate on it's own.

```bash
kubectl -n kube-system run -i --restart=Never --rm test-${RANDOM} --image=ubuntu --overrides='{"kind":"Pod", "apiVersion":"v1", "spec": {"dnsPolicy":"Default"}}' -- sh -c 'cat /etc/resolv.conf'
```

* Now run the job

```bash
export DOMAIN=rancher.labhub1.intelsat; echo "=> Start DNS resolve test"; kubectl -n kube-system get pods -l name=dnstest --no-headers -o custom-columns=NAME:.metadata.name,HOSTIP:.status.hostIP | while read pod host; do kubectl -n kube-system exec $pod -- /bin/sh -c "nslookup $DOMAIN > /dev/null 2>&1"; RC=$?; if [ $RC -ne 0 ]; then echo $host cannot resolve $DOMAIN; fi; done; echo "=> End DNS resolve test"
```

## Enable Log Queries for RKE2 CoreDNS

* This is useful to actually see the qeries of DNS via log data

```bash
kubectl get configmap -n kube-system rke2-coredns-rke2-coredns -o json | sed -e 's_loadbalance_log\\n    loadbalance_g' | kubectl apply -f -
```