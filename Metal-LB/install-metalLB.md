# Install and Configure metalLB
- References:
  - [Install-metalLB](https://metallb.universe.tf/installation/)
  - [Layer2-Config/advertisement](https://metallb.universe.tf/configuration/_advanced_l2_configuration/)
  - [Advanced-AddressPools](https://metallb.universe.tf/configuration/_advanced_ipaddresspool_configuration/)

- Requirements:
  - kubectl
  - helm
  - active kubernetes cluster with the proper kubeconfig | context (what cluster do you want to deploy to?)

## Install metalLB

- via helm

```bash
helm repo add metallb https://metallb.github.io/metallb
helm repolist update
kubectl apply -f -<<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: metallb-system
  labels:
    field.cattle.io/projectId: p-npspz
    kubernetes.io/metadata.name: metallb-system
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/audit-version: latest
    pod-security.kubernetes.io/enforce: privileged
    pod-security.kubernetes.io/enforce-version: latest
    pod-security.kubernetes.io/warn: restricted
    pod-security.kubernetes.io/warn-version: latest
EOF
helm upgrade -i metallb metallb/metallb --namespace metallb-system
kubectl apply -f -<<EOF
---
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
  namespace: metallb-system
spec:
  addresses:
    - 192.168.1.50/32
# lock down to a specific namespace (recommended approach)
  serviceAllocation:
    namespaces:
      - kube-system
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: first-pool-l2
  namespace: metallb-system
spec:
  ipAddressPools:
  - first-pool
EOF
```

#### Create a secondary Pool
- Example: For a Range of IP addresses for a particular namespace

```bash
kubectl apply -f -<<EOF
---
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: neuvector-pool
  namespace: metallb-system
spec:
  addresses:
    - 192.168.1.100-192.168.1.105
# lock down to a specific namespace (recommended approach)
  serviceAllocation:
    namespaces:
      - cattle-neuvector-system
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: neuvector-pool-l2
  namespace: metallb-system
spec:
  ipAddressPools:
  - neuvector-pool
EOF
```