# HA Proxy with KeepAliveD
<p>
This is the process to setup a highly available load balancer and virtual IP (vIP) to load balance TCP connections to a RKE2 Kubernetes Cluster. Typically, KUBE-VIP would be better suited for on-prem environments but there are use cases to use HAProxy instead of having vIP and Loadbalancer services at the cluster level.
</p>

- Environment:
  - 2 lightweight VMs (Rocky9) running HAProxy
    - 2 vCPU and 4Gi of RAM with 10Gi of Storage
  - 3 VMs (Rocky9) hosting RKE2
    - 4 vCPU and 8Gi of RAM with 30Gi of Storage

## Setup HA PRoxy and KeepAliveD
- On your three HA Proxy nodes, apply the provided shell scripts below.

```sh
dnf upgrade -y; dnf install -y haproxy keepalived
```
**Restart node if needed after update**

- Setup haproxy config on each haproxy node. Adjust fields as needed before applying. Meaning your RKE2 Control Plane IPs should be added here.
```sh
cat > /etc/haproxy/haproxy.cfg <<EOF
global
    log            /dev/log local0 warning
    log            /dev/log local1 notice
    chroot         /var/lib/haproxy
    pidfile        /var/run/haproxy.pid
    stats socket   /var/lib/haproxy/stats mode 660 level admin expose-fd listeners
    stats timeout  30s
    maxconn        4000
    user           haproxy
    group          haproxy
    daemon

defaults
    log global
    option tcplog
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms

frontend kubernetes_https
    bind 0.0.0.0:443
    mode tcp
    default_backend kubernetes_ingress

frontend kubernetes_api
    bind 0.0.0.0:6443
    mode tcp
    option tcplog
    default_backend kubernetes_api_server

frontend kubernetes_join
    bind 0.0.0.0:9345
    mode tcp
    option tcplog
    default_backend kubernetes_rke2_join

backend kubernetes_ingress
    mode tcp
    balance leastconn
    server k8s-nginx-1 <NGINX_NODE_IP1>:443 check
    server k8s-nginx-2 <NGINX_NODE_IP2>:443 check
    server k8s-nginx-3 <NGINX_NODE_IP3>:443 check

backend kubernetes_api_server
    mode tcp
    option tcplog
    option tcp-check
    balance roundrobin
    default-server inter 10s downinter 5s rise 2 fall 2 slowstart 60s
    server k8s-api-1 <K8S_API_NODE_IP1>:6443 check
    server k8s-api-2 <K8S_API_NODE_IP2>:6443 check
    server k8s-api-3 <K8S_API_NODE_IP3>:6443 check

backend kubernetes_rke2_join
    mode tcp
    option tcplog
    option tcp-check
    balance roundrobin
    server k8s-api-1 <K8S_API_NODE_IP1>:9345 check
    server k8s-api-2 <K8S_API_NODE_IP2>:9345 check
    server k8s-api-3 <K8S_API_NODE_IP3>:9345 check
EOF
# Enable HAProxy service now with a symbolic link to start on restart
systemctl enable --now haproxy
```

**KeepAlive Daemon**
- Master setup
```sh
cat > /etc/keepalived/keepalived.conf <<EOF
vrrp_script chk_haproxy {
  script "killall -0 haproxy"
  interval 2
  weight 2
}

vrrp_instance VIP {
    state MASTER
    interface <NETWORK_INTERFACE>
    virtual_router_id 10           # Must be the same on all nodes
    priority 100                   # Highest priority for the master node
    advert_int 1                   # How often to advertise (Every one second)
    authentication {
        auth_type PASS
        auth_pass secret           # Must match on all nodes
    }

    unicast_src_ip <IP_ADDRESS>   # Source IP address of this machine
    unicast_peer {
      <PEER_IP_ADDRESS>           # The IP address of your other Peer for HAProxy
    }

    virtual_ipaddress {
      <VIRTUAL_IP>
    }

    track_script {
      chk_haproxy
    }
}
EOF
systemctl enable --now keepalived
```

- Backup setup
  - Note, lower the priority per backup
```sh
cat > /etc/keepalived/keepalived.conf <<EOF
vrrp_script chk_haproxy {
  script "killall -0 haproxy"
  interval 2
  weight 2
}

vrrp_instance VIP {
    state BACKUP
    interface <NETWORK_INTERFACE>
    virtual_router_id 10          # Must be the same on all nodes
    priority 90                   # Lower priority for the backup node/s
    advert_int 1                  # How often to advertise (Every one second)
    authentication {
        auth_type PASS
        auth_pass secret          # Must match on all nodes
    }

    unicast_src_ip <IP_ADDRESS>   # Source IP address of this machine
    unicast_peer {
      <PEER_IP_ADDRESS>           # The IP address of your other Peer for HAProxy
    }

    virtual_ipaddress {
      <VIRTUAL_IP>
    }

    track_script {
      chk_haproxy
    }
}
EOF
systemctl enable --now keepalived
```

**Keepalived Validation**
- Checking for VIP
```sh
# From master node
nmcli 
# Validate you saw your VIP on your primary interface
```
- Checking for VIP Rollover
- Run a constant ping to the VIP and check out the latency bump when you invoke a rollover
```sh
# From master node
systemctl stop keepalived
# check backup server with the next lowest priority to validate it picked up the VIP.
ssh <user>@second-node
nmcli
# Now turn back on keepalived on the first node
```

## Install RKE2
- Login to your servers and do the following below to install RKE2 and leverage your new KeepAliveD VIP

**Setup Repo**
```sh
export RKE2_MINOR=30
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
# install rke2-server
dnf install -y rke2-server
```

**Setup config.yaml (bootstrap node or node1)**
- adjust your `VIP` in the config.yaml and setup your `pod-security-admission-config-file`
  - Ref for PSA file: https://ranchermanager.docs.rancher.com/reference-guides/rancher-security/psa-restricted-exemptions
```sh
cat > /etc/rancher/rke2/config.yaml <<EOF
tls-san:
- <VIP-HERE>
token: thisIsATest
selinux: true
profile: "cis"
secrets-encryption: true
write-kubeconfig-mode: "0640"
pod-security-admission-config-file: /etc/rancher/rke2/rancher-psact.yaml
kube-controller-manager-arg:
- bind-address=127.0.0.1
- tls-min-version=VersionTLS12
- tls-cipher-suites=TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384
- use-service-account-credentials=true
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
EOF
systemctl enable --now rke2-server
```

**Other Nodes to add configuration**
```sh
cat > /etc/rancher/rke2/config.yaml <<EOF
server: https://VIP:9345
token: thisIsATest
tls-san:
- <VIP-HERE>
selinux: true
profile: "cis"
secrets-encryption: true
write-kubeconfig-mode: "0640"
pod-security-admission-config-file: /etc/rancher/rke2/rancher-psact.yaml
kube-controller-manager-arg:
- bind-address=127.0.0.1
- tls-min-version=VersionTLS12
- tls-cipher-suites=TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384
- use-service-account-credentials=true
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
EOF
systemctl enable --now rke2-server
```



