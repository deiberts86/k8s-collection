# HA Proxy with KeepAliveD
<p>
This is the process to setup a highly available load balancer and virtual IP (vIP) to load balance TCP connections to a RKE2 Kubernetes Cluster. Typically, KUBE-VIP would be better suited for on-prem environments but there are use cases to use HAProxy instead of having vIP and Loadbalancer services at the cluster level.
</p>

- Environment:
  - 3 lightweight VMs (Rocky9) running HAProxy
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
    log /dev/log local0
    log /dev/log local1 notice
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners
    stats timeout 30s
    user haproxy
    group haproxy
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
    default_backend kubernetes_api_server

backend kubernetes_ingress
    mode tcp
    balance roundrobin
    server k8s-nginx-1 <NGINX_NODE_IP1>:443 check
    server k8s-nginx-2 <NGINX_NODE_IP2>:443 check
    server k8s-nginx-3 <NGINX_NODE_IP3>:443 check

backend kubernetes_api_server
    mode tcp
    balance roundrobin
    server k8s-api-1 <K8S_API_NODE_IP1>:6443 check
    server k8s-api-2 <K8S_API_NODE_IP2>:6443 check
    server k8s-api-3 <K8S_API_NODE_IP3>:6443 check
EOF

# Setup HAProxy User to leverage SOCK
mkdir -p /run/haproxy
chown haproxy:haproxy /run/haproxy
chmod 777 /run/haproxy
# Adjust SELinux if you're running in Enforcing mode
semanage fcontext -a -t haproxy_var_run_t "/var/run/haproxy(/.*)?"
restorecon -R /var/run/haproxy
# Restart systemctl daemon
systemctl daemon-reload
# Enable HAProxy service now with a symbolic link to start on restart
systemctl enable --now haproxy
```

**KeepAlive Daemon**
- Master setup
```sh
cat > /etc/keepalived/keepalived.conf <<EOF
vrrp_instance VI_1 {
    state MASTER
    interface <NETWORK_INTERFACE>
    virtual_router_id 10           # Must be the same on all nodes
    priority 100                   # Highest priority for the master node
    advert_int 1                   # How often to advertise (Every one second)
    authentication {
        auth_type PASS
        auth_pass secret           # Must match on all nodes
    }
    virtual_ipaddress {
        <VIRTUAL_IP>
    }
}
EOF
systemctl enable --now keepalived
```

- Backup setup
  - Note, lower the priority per backup
```sh
cat > /etc/keepalived/keepalived.conf <<EOF
vrrp_instance VI_1 {
    state BACKUP
    interface <NETWORK_INTERFACE>
    virtual_router_id 10          # Must be the same on all nodes
    priority 90                   # Lower priority for the backup node/s
    advert_int 1                  # How often to advertise (Every one second)
    authentication {
        auth_type PASS
        auth_pass secret          # Must match on all nodes
    }
    virtual_ipaddress {
        <VIRTUAL_IP>
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
```sh
# From master node
systemctl stop keepalived
# check backup server with the next lowest priority to validate it picked up the VIP.
ssh <user>@second-node
nmcli
# Now turn back on keepalived on the first node
```
