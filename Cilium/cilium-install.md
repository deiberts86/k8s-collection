# Cilium
- This is to install Cilium with RKE2

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
cat > /etc/sysctl.d/60-rke2.conf <<EOF
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

## Install Cilium

- Prepare files
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
      enforce: "restricted"
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

- RKE2 config.yaml
```sh
export TOKEN=$(openssl rand -hex 16)
export VIPSAN=<VIP-SAN>
export VIP=<VIP>
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
selinux: true
profile: "cis"
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
```

- rke2-cilium-config.yaml
```sh
mkdir -p /var/lib/rancher/rke2/server/manifests/
cat << EOF >  /var/lib/rancher/rke2/server/manifests/rke2-cilium-config.yaml
apiVersion: helm.cattle.io/v1
kind: HelmChartConfig
metadata:
  name: rke2-cilium
  namespace: kube-system
spec:
  valuesContent: |-
    bgp:
      enabled: false
    cni:
      chainingMode: "none"
    bpf:
      masquerade: true
      preallocateMaps: true
      tproxy: true
    bpfClockProbe: true
    global:
      clusterCIDR: 10.42.0.0/16
      clusterCIDRv4: 10.42.0.0/16
      clusterDNS: 10.43.0.10
      clusterDomain: cluster.local
      rke2DataDir: /var/lib/rancher/rke2
      serviceCIDR: 10.43.0.0/16
      systemDefaultIngressClass: cilium
    hubble:
      enabled: true
      metrics:
        enabled:
        - dns
        - drop
        - tcp
        - flow
        - port-distribution
        - icmp
        - httpV2:exemplars=true;labelsContext=source_ip,source_namespace,source_workload,destination_ip,destination_namespace,destination_workload,traffic_direction
      relay:
        enabled: true
      ui:
        enabled: true
        service:
          type: ClusterIP
    ingressController:
      enabled: true
      loadbalancerMode: shared
    k8sClientRateLimit:
      burst: 100
      qps: 50
    k8sServiceHost: 127.0.0.1
    k8sServicePort: "6443"
    kubeProxyReplacement: true
    l2announcements:
      enabled: true
      leaseDuration: "300s"
      leaseRenewDeadline: "30s"
      leaseRetryPeriod: "10s"
    l7Proxy: true
    operator:
      prometheus:
        enabled: true
      replicas: 1
      rollOutPods: true
    prometheus:
      enabled: true
    rollOutCiliumPods: true
```


## Start RKE2 Server
```sh
systemctl enable --now rke2-server 
```

## RKE2 Agents
- Same process as before but the `/etc/rancher/rke2/config.yaml` will be different.

```sh
export VIPSAN=<VIP>
export NODEIP=$(nmcli -g IP4.ADDRESS device show eth0 | head -n 1 | cut -d'/' -f1)
export NODEEXTIP=$(nmcli -g IP4.ADDRESS device show eth0 | head -n 1 | cut -d'/' -f1)
mkdir -p /etc/rancher/rke2
cat > /etc/rancher/rke2/config.yaml <<EOF
server: "https://$VIPSAN:9345"
token: "YOURTOKENHERE"
node-ip: "$NODEIP"
node-external-ip: "$NODEEXTIP"
profile: "cis"
selinux: true
kube-apiserver-arg:
- authorization-mode=RBAC,Node
kubelet-arg:
- anonymous-auth=false
- authorization-mode=Webhook
- protect-kernel-defaults=true
EOF
```
