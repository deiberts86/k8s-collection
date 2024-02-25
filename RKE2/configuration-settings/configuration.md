# config.yaml for RKE2-Servers
```yaml
tls-san:
  - YourVIPAddressHere
  - YourShortNameHere
  - YourIPHere
node-taint:
  - "CriticalAddonsOnly=true:NoExecute"
selinux: true
profile: "cis-1.23"
secrets-encryption: true
write-kubeconfig-mode: "0640"
pod-security-admission-config-file: /etc/rancher/rke2/rancher-pss.yaml
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
```

# config.yaml for RKE2-Agents

```yaml
server: https://vipaddr.local:9345
token: 
selinux: true
profile: "cis-1.23"
kube-apiserver-arg:
- authorization-mode=RBAC,Node
kubelet-arg:
- protect-kernel-defaults=true
- read-only-port=0
- authorization-mode=Webhook
write-kube-config-mode: 0640
```

# Your pod Security Admission Configuration

```yaml
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

# Audit Policy
- add more if necessary.  This is for STIG

```yaml
apiVersion: audit.k8s.io/v1
kind: Policy
metadata:
  creationTimestamp: null
rules:
- level: RequestResponse
```