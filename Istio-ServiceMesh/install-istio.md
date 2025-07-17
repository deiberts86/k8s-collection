# Install ISTIO
- This process will install ISTIO CRDs, ISTIOD, ISTIO-CNI, and ISTIO Gateway

- Requirements:
  - Bastionhost with Kubeconfig already pre-configured
  - helm

## Process
1. Grab Helm repo from upstream ISTIO
```sh
# Install ISTIO repo
helm repo add istio https://istio-release.storage.googleapis.com/charts --force-update
# Search to validate and see other products within this repo
helm search repo istio
```

2. Install CRDs
```sh
# Install CRDs via Helm
helm upgrade -i istio-base istio/base --namespace istio-system --set defaultRevision=default --create-namespace
# Validate
helm -n istio-system ls
```

3. Install CNI
```sh
# If using RKE2 or K3s, you need to set the 'cni.cniBinDir' and 'cni.cniConfDir' to the paths depicted below. Otherwise, you don't need it.
helm upgrade -i istio-cni istio/cni \
  -n istio-system \
  --set cni.cniBinDir="/opt/cni/bin" \
  --set cni.cniConfDir="/etc/cni/net.d" \
  --set seccompProfile.type=RuntimeDefault \
  --wait
```

4. Install ISTIOD
```sh
helm upgrade -i istiod istio/istiod -n istio-system --set pilot.cni.enabled=true --wait
helm upgrade --install istiod istio/istiod \
  -n istio-system \
  --set global.istioNamespace=istio-system \
  --set meshConfig.meshMTLS.minProtocolVersion=TLSV1_3 \
  --set meshConfig.outboundTrafficPolicy.mode=REGISTRY_ONLY \
  --wait
```

5. Install Gateway
- create your values.yaml file
```sh
cat > gateway-values.yaml <<EOF
rbac:
  enabled: true

serviceAccount:
  create: true
  annotations: {}
  name: "public-gateway-ingressgateway-service-account"

resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 2000m
    memory: 1024Mi

# Labels to apply to all resources
labels:
  # By default, don't enroll gateways into the ambient dataplane
  "istio.io/dataplane-mode": none
  app: public-gateway
  istio: public-gateway-ingressgateway
EOF
```
- Next, install gateway with your values
```sh
helm upgrade -i public-gateway istio/gateway --namespace istio-ingress --create-namespace -f gateway-values.yaml
```

6. Setup `mTLS STICT` by default for ISITO
```yaml
---
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: allow-ingress-gateway-authz-policy
  namespace: istio-ingress
spec:
  selector:
    matchLabels:
      istio: public-gateway-ingressgateway
  action: ALLOW
  rules:
    - {}
---
apiVersion: security.istio.io/v1
kind: PeerAuthentication
metadata:
  name: default
  namespace: istio-system
spec:
  mtls:
    mode: STRICT
```