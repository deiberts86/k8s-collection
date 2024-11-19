# Installation of Rancher MCM packages via Helm
- Your PSA exemption should already be declared within the `/etc/rancher/rke2/rancher-pss.yaml` location. If not, you will need to pre-seed your namespaces.


## Sysctl for CIS
```sh
cat << EOF >> /etc/sysctl.d/60-rke2.conf
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
net.ipv6.ip_forward=1
# ip_forward for NFTables
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-arptables=1
net.bridge.bridge-nf-call-ip6tables=1
# monitor file system events
fs.inotify.max_user_instances=8192
fs.inotify.max_user_watches=1048576
EOF
# Restart sysctl
sysctl -p > /dev/null 2>&1
```

## Pod Security Admission Exclusion
```sh
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
      #other options: version-1.24, version-1.25, version-1.26
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
```

## FA POLICY
```sh
cat <<-EOF >>"/etc/fapolicyd/rules.d/80-rke2.rules"
allow perm=any all : dir=/var/lib/rancher/
allow perm=any all : dir=/opt/cni/
allow perm=any all : dir=/run/k3s/
allow perm=any all : dir=/var/lib/kubelet/
EOF
systemctl restart fapolicyd
```

## INSTALL Rancher
```sh
helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
helm repo update
helm upgrade -i rancher rancher-stable/rancher --create-namespace --namespace cattle-system --set hostname=rancher.10-7-2-11.sslip.io --set ingress.ingressClassName=cilium --version 2.8.5
```