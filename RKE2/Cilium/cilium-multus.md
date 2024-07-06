# RKE2 Cilium with Multus
- References: 
  - [RKE2 Docs](https://docs.rke2.io/)

- Requirements:
  - You need to supplement your VIP with a loadbalancer FQDN and IP
  - Once the node is bootstrapped, you need to ensure you add the `server` field on other nodes and point to LB FQDN or IP.
  - rke2-selinux binary needs to added if AIRGAP is required.
  - Whenever you make a change to Cilium you should `rollout restart` all Cilium related pods

## Systems Prep
```sh
echo "disable and stop firewalld and nm-cloud-setup services"
systemctl disable --now firewalld
systemctl mask firewalld 
systemctl disable --now nm-cloud-setup.service
systemctl disable --now nm-cloud-setup.timer
echo "enable iscsi daemon to support Longhorn"
systemctl enable --now iscsid
echo "Kernel modules required by kubernetes and istio-init, required for selinux enforcing instances using istio-init."
echo "Add kernel modules"
cat > /etc/modules <<EOF
br_netfilter
overlay
xt_REDIRECT
xt_owner
xt_statistic
EOF
echo "sysctl rules for CIS profile and kernel tuning"
cat > /etc/sysctl.d/60-k3s.conf <<EOF
# SWAP settings
vm.swappiness=0
vm.panic_on_oom=0
vm.overcommit_memory=1
kernel.panic=10
kernel.panic_on_oops=1
vm.max_map_count = 262144
# Have a larger connection range available
net.ipv4.ip_local_port_range=1024 65000
# Increase max connection
net.core.somaxconn=10000
# Reuse closed sockets faster
net.ipv4.tcp_tw_reuse=1
net.ipv4.tcp_fin_timeout=15
# The maximum number of "backlogged sockets".  Default is 128.
net.core.somaxconn=4096
net.core.netdev_max_backlog=4096
# 16MB per socket - which sounds like a lot,
# but will virtually never consume that much.
net.core.rmem_max=16777216
net.core.wmem_max=16777216
# Various network tunables
net.ipv4.tcp_max_syn_backlog=20480
net.ipv4.tcp_max_tw_buckets=400000
net.ipv4.tcp_no_metrics_save=1
net.ipv4.tcp_rmem=4096 87380 16777216
net.ipv4.tcp_syn_retries=2
net.ipv4.tcp_synack_retries=2
net.ipv4.tcp_wmem=4096 65536 16777216
# ip_forward and tcp keepalive for iptables
net.ipv4.tcp_keepalive_time=600
net.ipv4.ip_forward=1
# ip_forward for NFTables
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
# monitor file system events
fs.inotify.max_user_instances=8192
fs.inotify.max_user_watches=1048576
EOF
echo "Restart sysctl"
sysctl -p > /dev/null 2>&1
```

## Add RKE2 Repo
```sh
export RKE2_MINOR=28
export LINUX_MAJOR=9 # or 8 or 9 etc
cat << EOF > /etc/yum.repos.d/rancher-rke2-1-${RKE2_MINOR}-latest.repo
[rancher-rke2-common-latest]
name=Rancher RKE2 Common Latest
baseurl=https://rpm.rancher.io/rke2/latest/common/centos/${LINUX_MAJOR}/noarch
enabled=1
gpgcheck=1
gpgkey=https://rpm.rancher.io/public.key

[rancher-rke2-1-${RKE2_MINOR}-latest]
name=Rancher RKE2 1.${RKE2_MINOR} Latest
baseurl=https://rpm.rancher.io/rke2/latest/1.${RKE2_MINOR}/centos/${LINUX_MAJOR}/x86_64
enabled=1
gpgcheck=1
gpgkey=https://rpm.rancher.io/public.key
EOF
```

## Add Rancher Pod Security Admission and Audit Policy
```sh
mkdir -p /etc/rancher/rke2/
cat > /etc/rancher/rke2/rancher-psact.yaml <<EOF
apiVersion: apiserver.config.k8s.io/v1
kind: AdmissionConfiguration
plugins:
- name: PodSecurity
  configuration:
    apiVersion: pod-security.admission.config.k8s.io/v1beta1
    kind: PodSecurityConfiguration
    defaults:
      #other options: baseline, restricted
      enforce: "privileged"
      #other options: version-1.26, version-1.27, version-1.28
      enforce-version: "latest"
      audit: "restricted"
      audit-version: "latest"
      warn: "restricted"
      warn-version: "latest"
    exemptions:
      usernames: []
      runtimeClasses: []
      namespaces: [calico-apiserver,
                   calico-system,
                   cattle-alerting,
                   cattle-csp-adapter-system,
                   cattle-elemental-system,
                   cattle-epinio-system,
                   cattle-externalip-system,
                   cattle-fleet-local-system,
                   cattle-fleet-system,
                   cattle-gatekeeper-system,
                   cattle-global-data,
                   cattle-global-nt,
                   cattle-impersonation-system,
                   cattle-istio,
                   cattle-istio-system,
                   cattle-logging,
                   cattle-logging-system,
                   cattle-monitoring-system,
                   cattle-neuvector-system,
                   cattle-prometheus,
                   cattle-resources-system,
                   cattle-sriov-system,
                   cattle-system,
                   cattle-ui-plugin-system,
                   cattle-windows-gmsa-system,
                   cert-manager,
                   cis-operator-system,
                   fleet-default,
                   ingress-nginx,
                   istio-system,
                   kube-node-lease,
                   kube-public,
                   kube-system,
                   longhorn-system,
                   rancher-alerting-drivers,
                   security-scan,
                   tigera-operator]
EOF
cat << EOF > /etc/rancher/rke2/audit.yaml
apiVersion: audit.k8s.io/v1
kind: Policy
metadata:
  name: rke2-audit-policy
rules:
  - level: Metadata
    resources:
    - group: ""
      resources: ["secrets"]
  - level: RequestResponse
    resources:
    - group: ""
      resources: ["*"]
EOF
```

## Configuration YAML for RKE2 bootstrap node
```sh
export TOKEN=$(openssl rand -hex 16)
export VIPSAN=vip.192-168-30-55.sslip.io
export VIP=192.168.30.55
export NODEIP=$(nmcli -g IP4.ADDRESS device show eth0 | head -n 1 | cut -d'/' -f1)
export NODEEXTIP=$(nmcli -g IP4.ADDRESS device show eth0 | head -n 1 | cut -d'/' -f1)
export API_SERVER_IP=127.0.0.1
export API_SERVER_PORT=6443
cat << EOF > /etc/rancher/rke2/config.yaml
cni:
- multus
- cilium
node-ip: "$NODEIP"
node-external-ip: "$NODEEXTIP"
cluster-cidr: "10.42.0.0/16"
service-cidr: "10.43.0.0/16"
cluster-dns: 10.43.0.10
disable-cloud-controller: true
disable-kube-proxy: true
disable:
- rke2-ingress-nginx
- rke2-metrics-server
- rke2-canal
egress-selector-mode: "disabled"
selinux: true
  #profile: "cis-1.23"
secrets-encryption: true
write-kubeconfig-mode: "0640"
etcd-snapshot-schedule-cron: "0 */4 * * *"
etcd-snapshot-retention: 18
pod-security-admission-config-file: "/etc/rancher/rke2/rancher-psact.yaml"
audit-policy-file: "/etc/rancher/rke2/audit.yaml"
kube-controller-manager-arg:
- bind-address=127.0.0.1
- tls-min-version=VersionTLS12
- tls-cipher-suites=TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384
- use-service-account-credentials=true
- allocate-node-cidrs=true
kube-scheduler-arg:
- tls-min-version=VersionTLS12
- tls-cipher-suites=TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384
kube-apiserver-arg:
- tls-min-version=VersionTLS12
- tls-cipher-suites=TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384
- audit-log-path=/var/lib/rancher/rke2/server/logs/audit.log
- anonymous-auth=false
- authorization-mode=RBAC,Node
- audit-log-maxage=30
- audit-log-mode=blocking-strict
kubelet-arg:
- anonymous-auth=false
- read-only-port=0
- authorization-mode=Webhook
- streaming-connection-idle-timeout=5m
- protect-kernel-defaults=true
token: "$TOKEN"
tls-san:
- $VIPSAN
- $VIP
EOF
mkdir -p /var/lib/rancher/rke2/server/manifests/
cat << EOF >  /var/lib/rancher/rke2/server/manifests/rke2-cilium-config.yaml
apiVersion: helm.cattle.io/v1
kind: HelmChartConfig
metadata:
  name: rke2-cilium
  namespace: kube-system
spec:
  valuesContent: |-
    bpf:
      clockProbe: true
      masquerade: true
      preallocateMaps: true
      tproxy: true
      waitForMount: true
    cni:
      exclusive: false
    global:
      containerRuntime:
        integration: "containerd"
        socketPath: "/var/run/rke2/containerd/containerd.sock"
    hubble:
      enabled: true
      metrics:
        enabled:
        - "dns"
        - "drop"
        - "tcp"
        - "flow"
        - "port-distribution"
        - "icmp"
        - "httpV2:exemplars=true;labelsContext=source_ip,source_namespace,source_workload,destination_ip,destination_namespace,destination_workload,traffic_direction"
    relay:
      enabled: true
    ui:
      enabled: true
      service:
        type: "ClusterIP"
    ingressController:
      enabled: true
      loadbalancerMode: "shared"
    ipam:
      operator:
        clusterPoolIPv4PodCIDRList: "10.42.0.0/16"
    ipv4NativeRoutingCIDR: "10.42.0.0/16"
    k8sServiceHost: "$API_SERVER_IP"
    k8sServicePort: "$API_SERVER_PORT"
    kubeProxyReplacement: true
    routingMode: "tunnel"
    operator:
      prometheus:
        enabled: true
    replicas: 2
    prometheus:
      enabled: true
EOF
```

## Start RKE2 Server
```sh
systemctl enable --now rke2-server 
```

## RKE2 Agents
- Same process as before but the `/etc/rancher/rke2/config.yaml` will be different.

```sh
export VIPSAN=vip.192-168-30-55.sslip.io
export NODEIP=$(nmcli -g IP4.ADDRESS device show eth0 | head -n 1 | cut -d'/' -f1)
export NODEEXTIP=$(nmcli -g IP4.ADDRESS device show eth0 | head -n 1 | cut -d'/' -f1)
server: "https://$VIPSAN:9345"
# Grab from bootstrap node
token: "YOURTOKENHERE"
node-ip: "$NODEIP"
node-external-ip: "$NODEEXTIP"
profile: "cis-1.23"
selinux: true
kube-apiserver-arg:
- authorization-mode=RBAC,Node
kubelet-arg:
- anonymous-auth=false
- authorization-mode=Webhook
- protect-kernel-defaults=true
```

## Helpful Commands
- Leverage Cilium 
```sh
# Restart Cilium related pods
kubectl -n kube-system rollout restart deploy/cilium-operator; kubectl -n kube-system rollout restart ds/cilium; kubectl -n kube-system rollout restart ds/envoy
# Delete pods after major Cilium Changes
kubectl get pods --all-namespaces -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,HOSTNETWORK:.spec.hostNetwork --no-headers=true | grep '<none>' | awk '{print "-n "$1" "$2}' | xargs -L 1 -r kubectl delete pod
# View Cilium status and BPF status
kubectl -n kube-system exec ds/cilium -- cilium status
kubectl -n kube-system exec ds/cilium -- cilium-dbg status --all-controllers --all-health --all-redirects --verbose
# Cilium Monitor (Similar to TCPDump)
kubectl -n kube-system exec ds/cilium -- cilium-dbg monitor
# View Cilium services being used
kubectl -n kube-system exec ds/cilium -- cilium service list
# BPF List
kubectl -n kube-system exec ds/cilium -- cilium-dbg endpoint list
# View DNS with Hubble
kubectl -n kube-system exec ds/cilium -- hubble observe --follow --protocol dns
# Validate iptables isn't used for KubeProxy
iptables-save | grep KUBE-SVC
```

- Cilium CLI based commands

```sh
# View Currnet Cilium Config
cilium config view
# View Status
cilium status
# View Status and wait
cilium status --wait
```