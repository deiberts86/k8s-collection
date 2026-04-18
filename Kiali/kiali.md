# Install Kiali Operator

```sh
# Install Helm Repo
helm repo add kiali https://kiali.org/helm-charts --force-update
# Install Kiali Operator and operator will install Kiali in the 'cr.namespace'
helm upgrade -i \
  --set cr.create=true \
  --set cr.namespace=istio-system \
  --set cr.spec.auth.strategy="anonymous" \
  --set cr.spec.external_services.grafana.enabled=true \
  --set cr.spec.external_services.grafana.in_cluster_url="http://grafana.monitoring.svc.cluster.local:3000" \
  --set cr.spec.external_services.prometheus.url="http://monitoring-kube-prometheus-prometheus.monitoring.svc.cluster.local:9090" \
  --namespace kiali-operator \
  --create-namespace \
  kiali-operator \
  kiali/kiali-operator
```
