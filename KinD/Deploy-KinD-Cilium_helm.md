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
  - [Cilium with Helm](https://docs.cilium.io/en/stable/installation/k8s-install-helm/#k8s-install-helm)

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
cat > kind-config.yaml <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
  - role: worker
  - role: worker
networking:
  disableDefaultCNI: true
EOF
kind create cluster --config=kind-config.yaml
```
- You should see "Creating cluster "kind" ...
```sh
kubectl get nodes
kubectl get pods -A
```
- You should see three nodes and all of your pods.  Note, Kubernetes will be "NotReady" state until the Cilium CNI is installed.

- Installing Cilium with Helm this time and enabling Metrics
```sh
helm repo add cilium https://helm.cilium.io --force-update
helm upgrade -i cilium cilium/cilium --version 1.15.6 --namespace kube-system --set operator.replicas=1
cilium status --wait

# Confirmation that Cilium is deployed with Helm
cilium status
helm ls -A
```

![Cilium Status](/KinD/pictures/cilium-with-helm.png)

- Cleanup older pods that was using `HOST NETWORK` from a previous Cilium Install
```sh
kubectl get pods --all-namespaces -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,HOSTNETWORK:.spec.hostNetwork --no-headers=true | grep '<none>' | awk '{print "-n "$1" "$2}' | xargs -L 1 kubectl delete pod
```