# Deploy KinD Cilium Muliti-Cluster with ClusterMesh
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
  - [Cilium ClusterMesh](https://docs.cilium.io/en/stable/network/clustermesh/clustermesh/)

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
- NOTE: You might need to adjust sysctl controls for fs.inotify.max_user_watchers

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
# Adjust sysctl controls
sysctl -w fs.inotify.max_user_watches=2099999999
sysctl -w fs.inotify.max_user_instances=2099999999
sysctl -w fs.inotify.max_queued_events=2099999999
# Configure Your Multicluster Kind Clusters (Starwars themed...)
cat > kind-cluster-01.yaml <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: alliance-sector-01
nodes:
  - role: control-plane
  - role: worker
networking:
  disableDefaultCNI: true
  kubeProxyMode: none
  serviceSubnet: "10.11.0.0/16"
  podSubnet: "10.10.0.0/16"
EOF
cat > kind-cluster-02.yaml <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: alliance-sector-02
nodes:
  - role: control-plane
  - role: worker
networking:
  disableDefaultCNI: true
  kubeProxyMode: none
  serviceSubnet: "10.21.0.0/16"
  podSubnet: "10.20.0.0/16"
EOF
kind create cluster --config=kind-cluster-01.yaml
kind create cluster --config=kind-cluster-02.yaml
```

- You should see "Creating cluster" for both clusters

```sh
kubectl config get-contexts
export CLUSTER1=kind-alliance-sector-01
export CLUSTER2=kind-alliance-sector-02
```

- You should see two Kubernetes clusters and the default cluster selected would be the last one implemented (number 2). Ensure you exported your Kubeconfig contexts

## Installing Cilium with encryption and inherit CA cert from first cluster
```sh
cilium install --context $CLUSTER1 --cluster-name sector-01 --cluster-id 1 --encryption wireguard --helm-set "l7Proxy=false"
cilium status --context $CLUSTER1
cilium install --context $CLUSTER2 --cluster-name sector-02 --cluster-id 2 --encryption wireguard --helm-set "l7Proxy=false" --inherit-ca $CLUSTER1
cilium status --context $CLUSTER2
```

![cilium-ClusterMesh_status1](/KinD/pictures/cilium-clusterMesh_status1.png)

## Enabling the Cluster Mesh
```sh
cilium clustermesh enable --service-type NodePort --context $CLUSTER1
cilium clustermesh enable --service-type NodePort --context $CLUSTER2
# Check Cluster Mesh API Servers with Cilium CLI status per context
cilium status --context $CLUSTER1
cilium status --context $CLUSTER2
# You can check the actual ClusterMesh Status as well
cilium clustermesh status --context $CLUSTER1
cilium clustermesh status --context $CLUSTER2
# Time to Join each cluster together now all validation checks are done
cilium clustermesh connect --context $CLUSTER1 --destination-context $CLUSTER2
# The result will restart Cilium agents and the commands below can wait for it to confirm completion
cilium clustermesh status --context $CLUSTER2 --wait
cilium clustermesh status --context $CLUSTER1 --wait
```

![cilium-ClusterMesh_status2](/KinD/pictures/cilium-clusterMesh_status2.png)
![cilium-ClusterMesh_status3](/KinD/pictures/cilium-clusterMesh_status3.png)

## Deploy Demo App
```sh
kubectl apply --context $CLUSTER1 -f https://raw.githubusercontent.com/cilium/cilium/HEAD/examples/kubernetes/clustermesh/global-service-example/cluster1.yaml
kubectl apply --context $CLUSTER2 -f https://raw.githubusercontent.com/cilium/cilium/HEAD/examples/kubernetes/clustermesh/global-service-example/cluster2.yaml
# Get Global Annaotation setting
kubectl get service/rebel-base --context $CLUSTER2 -o json | jq .metadata.annotations
# Repeat these next two commands a few times to watch it change between contexts (Loadbalancing)
kubectl --context $CLUSTER1 exec -ti deployment/x-wing -- curl rebel-base
kubectl --context $CLUSTER2 exec -ti deployment/x-wing -- curl rebel-base
```

## Setup Cluster Affinity
```sh
# Update Annotations for Cluster 1 to use an Affinity of "local"
kubectl --context=$CLUSTER1 annotate service rebel-base service.cilium.io/affinity=local --overwrite
# Scale back cluster1 deployment rebel-base to zero to pickup new affinity
kubectl --context $CLUSTER1 scale --replicas=0 deploy/rebel-base
kubectl --context $CLUSTER1 scale --replicas=2 deploy/rebel-base
# Update Annotation for Cluster2 similar to Cluster1
kubectl --context=$CLUSTER2 annotate service rebel-base service.cilium.io/affinity=local --overwrite
# Scale back cluster1 deployment rebel-base to zero to pickup new affinity
kubectl --context $CLUSTER2 scale --replicas=0 deploy/rebel-base
kubectl --context $CLUSTER2 scale --replicas=2 deploy/rebel-base
```