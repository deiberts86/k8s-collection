# Cilium with GatewayAPI (Ingress Replacement)
- We will use HubbleUI as an example

- Reference:
  - [GatewayAPI](https://gateway-api.sigs.k8s.io/)
  - [Cilium GatewayAPI Docs](https://docs.cilium.io/en/v1.15/network/servicemesh/gateway-api/gateway-api/#gs-gateway-api)
- Requirements:
  - Cilium Cluster with following parameters enabled:
    ```yaml
    kubeProxyReplacement: "true"
    envoy:
      enabled: true
      securityContext:
        capabilities:
          keepCapNetBindService: true
    envoyConfig:
      enabled: true
    gatewayAPI:
      enabled: true
    l7Proxy: true
    loadBalancer:
      l7:
        backend: envoy
    ```

## Add Required CRDs (Cilium Version 1.15.x)
- These CRDs should be added first before attempting to add GatewayAPI resources.
```sh
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.0.0/config/crd/standard/gateway.networking.k8s.io_gatewayclasses.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.0.0/config/crd/standard/gateway.networking.k8s.io_gateways.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.0.0/config/crd/standard/gateway.networking.k8s.io_httproutes.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.0.0/config/crd/standard/gateway.networking.k8s.io_referencegrants.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.0.0/config/crd/standard/gateway.networking.k8s.io_grpcroutes.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.0.0/config/crd/experimental/gateway.networking.k8s.io_tlsroutes.yaml
```

## Add Required CRDs (Cilium Version 1.16.x)
- These CRDs should be added first before attempting to add GatewayAPI resources.
```sh
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.1.0/config/crd/standard/gateway.networking.k8s.io_gatewayclasses.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.1.0/config/crd/standard/gateway.networking.k8s.io_gateways.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.1.0/config/crd/standard/gateway.networking.k8s.io_httproutes.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.1.0/config/crd/standard/gateway.networking.k8s.io_referencegrants.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.1.0/config/crd/standard/gateway.networking.k8s.io_grpcroutes.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.1.0/config/crd/experimental/gateway.networking.k8s.io_tlsroutes.yaml
```

## Create GatewayClass
- Only do this if the experimental gatewayClass isn't built for you (observed behavior)
```sh
apiVersion: gateway.networking.k8s.io/v1beta1
kind: GatewayClass
metadata:
  name: cilium
spec:
  controllerName: io.cilium/gateway-controller
```

## Add Gateway and HTTPRoute
- Create your Gateway and HTTPRoute
  - Ensure you have a secret to reference as well to secure the endpoint.
  - You can also annotate your Gateway with Cert-manager to automatically create your certificates on your behalf.
    ```sh
    apiVersion: gateway.networking.k8s.io/v1
    kind: Gateway
    metadata:
      name: tls-gateway
      namespace: kube-system
      annotations:
        cert-manager.io/cluster-issuer: <YOUR-ISSUER>
    ```
```sh
kubectl apply -f -<<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: default-gateway
  namespace: kube-system
spec:
  gatewayClassName: cilium
  listeners:
  - name: hubble-gateway
    protocol: HTTPS
    port: 443
    hostname: "<HOSTNAME>"
    tls:
      certificateRefs:
      - kind: Secret
        name: hubble-tls
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: hubble-route
  namespace: kube-system
spec:
  parentRefs:
  - name: default-gateway
  hostnames:
  - "<HOSTNAME>"
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: hubble-ui
      port: 80
EOF
```
