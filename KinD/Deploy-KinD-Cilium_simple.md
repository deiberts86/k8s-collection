# Deploy KinD with Cilium Simple Setup (Cilium CLI)
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
    - Docker or Podman
    - Cilium CLI (Required if Using Cilium CNI)

- References:
  - [KinD](https://kind.sigs.k8s.io/)
  - [Cilium CLI Install](https://docs.cilium.io/en/stable/gettingstarted/k8s-install-default/)

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
#
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

```sh
cilium install
cilium status --wait
cilium hubble enable --ui
# Confirmation that Cilium, Cilium-Operator, and Hubble are Happy
cilium status
```
![Cilium Status](/KinD/pictures/cilium-with-ciliumcli.png)

- Cilium Connectivity Validation Testing
```sh
cilium connectivity test --request-timeout 30s --connect-timeout 10s
```