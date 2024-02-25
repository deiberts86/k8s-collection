# IPVS for Kube-Proxy

## IPVS (IP Virtual Server) versus IPTables
Images sourced from Kubernetes.io


![IPTables](/IPVS/images/iptables-img.png) | ![IPVS](/IPVS/images/ipvs-img.png)


### `Kube-Proxy with IPTables mode:`

<p>By default, kube-proxy in older versions of Kubernetes (before version 1.14) used IPTables as the default mode for service implementation. In this mode, kube-proxy creates IPTables rules to achieve service abstraction. Each service's cluster IP is represented as an IPTables rule. Traffic destined for the service's cluster IP is redirected to the appropriate backend pods based on IPTables rules.</p>

### `Kube-Proxy with IPVS mode:`

<p>Starting from Kubernetes version 1.14, IPVS support was introduced as an alternative mode for kube-proxy. In IPVS mode, kube-proxy utilizes the IPVS kernel module for load balancing instead of IPTables. IPVS provides potentially better performance and scalability for load balancing compared to IPTables due to its efficient handling of network connections.</p>

### `Differences in kube-proxy modes (IPVS vs. IPTables):`

Mechanism:
<p>In IPTables mode, kube-proxy uses IPTables rules to manage traffic routing and load balancing for services.In IPVS mode, kube-proxy utilizes the IPVS kernel module directly for load balancing, which can provide improved performance and scalability.</p>

Performance:
<p>IPVS mode generally offers better performance for load balancing compared to IPTables, especially in scenarios with a large number of services or high traffic.</p>

Compatibility:
<p>Not all kernel versions or configurations support IPVS, so compatibility should be checked before using IPVS mode. IPTables mode is more widely supported across various Linux distributions and kernel versions.</p>

Configuration Complexity:

<p>IPVS mode might require additional kernel modules or configurations to be enabled for full functionality, whereas IPTables mode is usually more straightforward in terms of setup.</p>

- Note: IPVS should definitely be used if you're using thousands of services within your clusters.

---
References:
- [IPVS vs. IPTables pt.1](https://github.com/kubernetes/kubernetes/blob/master/pkg/proxy/ipvs/README.md)
- [IPVS vs. IPTables pt.2](https://www.tigera.io/blog/comparing-kube-proxy-modes-iptables-or-ipvs/)
- [DNS NodeLocal Cache](https://docs.rke2.io/networking?_highlight=ipvs#nodelocal-dnscache)
- [Kubernetes.io Blog](https://kubernetes.io/blog/2018/07/09/ipvs-based-in-cluster-load-balancing-deep-dive/#IPTables-ipset-in-ipvs-proxier)
- [Virtual IPs and Service Proxies](https://kubernetes.io/docs/reference/networking/virtual-ips/)
- [Kube-Proxy Flags](https://kubernetes.io/docs/reference/command-line-tools-reference/kube-proxy/)
- [Conntrack Module ipv4](https://cateee.net/lkddb/web-lkddb/NF_CONNTRACK_IPV4.html)
- [Conntrack Module ipv6](https://cateee.net/lkddb/web-lkddb/NF_CONNTRACK_IPV6.html)

---
Requirements:
- Linux Host must support IPVS
- Must have root permissions to Linux host
- Reconfigure kube-proxy ahead of time or reconfigure current hosts and restart Kubernetes services

---
Environment tested:
- VMware vSphere Environment
- Rocky 9.3 x86_64 (amd64) Linux OS with SELinux enforced
  - 4 vCPU
  - 8 Gigabytes of RAM per host
  - 100 GB of HDD space
  - 1 vNIC per host
- RKE2 Kubernetes version 1.26.10+rke2r2
  - RKE2 hardening procedure was done in accordance with DISA STIG.
- Rancher MCM as local management cluster (two clusters)
  - Created downstream cluster through Rancher MCM with Vsphere Cloud Provider cluster management
  - Passed Kube-Proxy arguments through the yaml directly within Rancher MCM console
  - DNS Node Local Cache was enabled for CoreDNS as an `additional manifest` option and enforced IPVS for DNS
  - CIS Profile 1.23 with SELinux enabled

## Enable Required Kernel Modules

- Automate this process for easier deployment. Login to your Linux host and run the following below to enable the required Kernel Modules to allow IPVS and net filter connection tracking.

```bash
cat > /etc/modules <<EOF
ip_vs
ip_vs_rr
ip_vs_wrr
ip_vs_lc
ip_vs_wlc
ip_vs_lblc
ip_vs_lblcr
ip_vs_sh
ip_vs_dh
ip_vs_sed
ip_vs_nq
nf_conntrack_ipv4 
nf_conntrack_ipv6
EOF
modprobe ip_vs
modprobe ip_vs_rr
modprobe ip_vs_wrr
modprobe ip_vs_lc
modprobe ip_vs_wlc
modprobe ip_vs_lblc
modprobe ip_vs_lblcr
modprobe ip_vs_sh
modprobe ip_vs_dh
modprobe ip_vs_sed
modprobe ip_vs_nq
modprobe nf_conntrack_ipv4
modprobe nf_conntrack_ipv6
```

OR

```bash
cat > /etc/modules-load.d/ipvs.conf <<EOF
ip_vs
ip_vs_rr
ip_vs_wrr
ip_vs_lc
ip_vs_wlc
ip_vs_lblc
ip_vs_lblcr
ip_vs_sh
ip_vs_dh
ip_vs_sed
ip_vs_nq
nf_conntrack_ipv4 
nf_conntrack_ipv6
EOF
modprobe ip_vs
modprobe ip_vs_rr
modprobe ip_vs_wrr
modprobe ip_vs_lc
modprobe ip_vs_wlc
modprobe ip_vs_lblc
modprobe ip_vs_lblcr
modprobe ip_vs_sh
modprobe ip_vs_dh
modprobe ip_vs_sed
modprobe ip_vs_nq
modprobe nf_conntrack_ipv4
modprobe nf_conntrack_ipv6
```

## Edit your Kube-Proxy
For `k3s` or `RKE2` Kubernetes Deployment. Restart of your service for Kubernetes will needed if you `imported` your cluster into Rancher MCM.

To take advantage of IPVS, you will need to edit the Kube-Proxy parameters of your `config.yaml` file. These parameters will tell Kube-Proxy to leverage IPVS instead of IPTables. There are numerous scheduler options to choose from for IPVS which includes Round Robin, Least Connect, Destination Hashing, Source Hashing, etc. Referenced documentation is available at the beginning of this readme document.

Here are a few examples below:

- Enforce Strict ARP with scheduler with `lc` (Least Connect) load balancing protocol. 

```bash
kube-proxy-arg:
- proxy-mode=ipvs
- ipvs-strict-arp=true
- ipvs-scheduler=lc
```

- IPVS Timeout Tuning for UDP or TCP traffic with `rr` (Round Robin) load balancing protocol.

```bash
kube-proxy-arg:
- proxy-mode=ipvs
- ipvs-strict-arp=true
- ipvs-scheduler=rr
- ipvs-tcp-timeout=120s
- ipvs-udp-timeout=120s
- ipvs-tcpfin-timeout=1m
```
