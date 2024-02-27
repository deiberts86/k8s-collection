# Fix for False Positive CoreDNS Alerts from Prometheus

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: monitoring-network-coredns-policy
  namespace: kube-system
spec:
  ingress:
  - ports:
    - port: 9153
      protocol: TCP
    from:
      - namespaceSelector:
          matchLabels:
            kubernetes.io/metadata.name: cattle-monitoring-system
  podSelector:
    matchLabels:
      k8s-app: kube-dns
      app.kubernetes.io/name : rke2-coredns
  policyTypes:
  - Ingress
```

# Fix for Ingress NGINX Alerts from Prometheus

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: monitoring-network-nginx-policy
  namespace: kube-system
spec:
  ingress:
  - ports:
    - port: 10254
      protocol: TCP
    from:
      - namespaceSelector:
          matchLabels:
            kubernetes.io/metadata.name: cattle-monitoring-system
  podSelector:
    matchLabels:
      app.kubernetes.io/instance: rke2-ingress-nginx
      app.kubernetes.io/name: rke2-ingress-nginx
  policyTypes:
  - Ingress
```
