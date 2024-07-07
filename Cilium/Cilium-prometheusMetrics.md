# Cilium with Prometheus Metrics
- References:
  - [Prometheus Metric Endpoints](https://docs.cilium.io/en/v1.13/observability/metrics/#exported-metrics-by-default)

- Requirements:
  - Helm installed Cilium on a Kubernetes Cluster
  Software:
    - kubectl
    - jq

- Cleanup everything for Cilium Network Policies before starting
```sh
kubectl delete --all CiliumNetworkPolicies
```


## Deploy Demo `TIEFIGHTER` Application
```sh
kubectl create -f https://raw.githubusercontent.com/cilium/cilium/HEAD/examples/minikube/http-sw-app.yaml
# Apply new Network Policy
kubectl apply -f https://raw.githubusercontent.com/cilium/cilium/HEAD/examples/minikube/sw_l3_l4_l7_policy.yaml
```

## Enable Cilium Metrics Collection
```sh
helm upgrade -i cilium cilium/cilium --namespace=kube-system --reuse-values --set prometheus.enabled=true --set operator.prometheus.enabled=true
# grab a sample pod name to replace cilium-$name
kubectl -n kube-system get pods | grep cilium
# You should see Prometheus.io/port and /scrape set
kubectl -n kube-system get pod/cilium-578dj -o json | jq .metadata.annotations
# This command below will grab the endpoint IP of the container
kubectl -n kube-system get pod/cilium-578dj -o json | jq .status.podIP
# You will need to plugin the IP of your previous output where the http:// is
kubectl exec -it pod/tiefighter -- curl http:‌//10.89.0.4:9962/metrics
```

## Enable Hubble Metrics
```sh
helm upgrade -i cilium cilium/cilium --version 1.15.6 --namespace kube-system --reuse-values --set hubble.enabled=true --set hubble.metrics.enabled="{dns,drop,tcp,flow,port-distribution,httpV2}"
kubectl rollout restart daemonset/cilium -n kube-system
```

## Enable Hubble with Flow Context Metrics
```sh
helm upgrade -i cilium cilium/cilium --version 1.15.6 --namespace kube-system --reuse-values --set hubble.enabled=true --set hubble.metrics.enabled="{dns,drop:sourceContext=pod;destinationContext=pod,tcp,flow,port-distribution,httpV2}"
kubectl rollout restart daemonset/cilium -n kube-system
```

## Enable Prometheus Addon with Grafana
```sh
kubectl apply -f https://raw.githubusercontent.com/cilium/cilium/HEAD/examples/kubernetes/addons/prometheus/monitoring-example.yaml
kubectl -n cilium-monitoring port-forward service/grafana --address 0.0.0.0 --address :: 3000:3000
```

## Results
![Grafana Dashboard](/Cilium/pictures/Cilium-Grafana-Dashboard.png)