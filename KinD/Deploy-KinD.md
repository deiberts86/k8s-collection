# Deploy Kind
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

## Install on Windows
```powershell
curl.exe -Lo kind-windows-amd64.exe https://kind.sigs.k8s.io/dl/v0.23.0/kind-windows-amd64
Move-Item .\kind-windows-amd64.exe c:\some-dir-in-your-PATH\kind.exe
```

## Install on MacOS
```zsh
# For Intel Macs
[ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.23.0/kind-darwin-amd64
# For M1 / ARM Macs
[ $(uname -m) = arm64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.23.0/kind-darwin-arm64
chmod +x ./kind
mv ./kind /some-dir-in-your-PATH/kind
```

## Setup KinD

```sh
dnf install -y docker
systemctl enable --now docker
# OR
systemctl enable --now podman
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