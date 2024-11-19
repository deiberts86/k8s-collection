# Deploy KinD with Helm
- Description:
  - kind is a tool for running local Kubernetes clusters using Docker container “nodes”.
kind was primarily designed for testing Kubernetes itself, but may be used for local development or CI.

- Requirements:
  - A Linux x86_64 or ARM64 Virtual Machine or Bare-metal machine
    - Should have at least 4vCPU and 8GiB of RAM
  - Windows Desktop with Powershell
  - MacOS
  - Software:
    - kubectl
    - Helm
    - Docker or Podman
    - Cilium CLI (Required if Using Cilium CNI)

- References:
  - [KinD](https://kind.sigs.k8s.io/)
  - [Cilium Kube-Proxy Replacement](https://docs.cilium.io/en/stable/network/kubernetes/kubeproxy-free/#kubeproxy-free)

# INSTALL KinD

## Install on Linux
```sh
# For AMD64 / x86_64
[ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.23.0/kind-linux-amd64
# For ARM64
[ $(uname -m) = aarch64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.23.0/kind-linux-arm64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
```

## Setup KinD
- Using Cilium CNI for this example

```sh
dnf install -y docker
systemctl enable --now docker
# OR
systemctl enable --now podman
# Install Cilium CLI
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable-v0.14.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
# Install Helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
# Configure kind-config
cat > kind-config-no-proxy.yaml <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
- role: worker
networking:
  disableDefaultCNI: true
  kubeProxyMode: none
EOF
kind create cluster --config=kind-config-no-proxy.yaml
```

- You should see "Creating cluster "kind" ...
```sh
kubectl get nodes
kubectl get pods -A
# Confirm Kube-Proxy is NOT configured
kubectl get --all-namespaces daemonsets | grep kube-proxy
kubectl get --all-namespaces pods | grep kube-proxy
kubectl get --all-namespaces configmaps |grep kube-proxy
```
- You should see three nodes and all of your pods.  Note, Kubernetes will be "NotReady" state until the Cilium CNI is installed.

- Installing Cilium with Cilium CLI with Kube-Proxy replacement
```sh
cilium install
# Confirmation that Cilium is deployed
cilium status
```

![Cilium KubeProxy Replacement](/KinD/pictures/cilium-kube-proxy-replacement.png)

## Cilium Connectivity Testing

```sh
cilium connectivity test --connect-timeout 30s --request-timeout 10s
```

## Deploy Application for Testing KubeProxy Replacement

- Deploy NGINX
```sh
kubectl apply -f -<<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-nginx
spec:
  selector:
    matchLabels:
      run: my-nginx
  replicas: 2
  template:
    metadata:
      labels:
        run: my-nginx
    spec:
      containers:
        - name: my-nginx
          image: nginx
          ports:
            - containerPort: 80
EOF
kubectl get pods -l run=my-nginx -o wide
kubectl expose deployment my-nginx --type=NodePort --port=80
kubectl get svc my-nginx
kubectl -n kube-system exec ds/cilium -- cilium service list
```

- Install curl inside of cilium
```sh
kubectl -n kube-system exec -ti ds/cilium -- /bin/bash
apt update
apt install curl
# Check your service endpoint for proper port
curl http:‌//localhost:31848
```

## Confirm IPTables Aren't Being Used for Service Definitions
- From your KinD cluster host

```sh
iptables-save | grep KUBE-SVC
```