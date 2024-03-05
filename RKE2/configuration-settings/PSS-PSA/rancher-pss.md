# Rancher-PSS Exemption File

```sh
cat > /etc/rancher/rke2/rancher-pss.yaml <<EOF
---
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
...
EOF
# Replace the default PSS admission within the config.yaml
sed -i 's/rke2-pss\.yaml/rancher-pss.yaml/g' /etc/rancher/rke2/config.yaml
```