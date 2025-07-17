# Install Gitea with Helm
Requirements:
- Ensure you have a DNS record built for gitea.example.com
- Export KUBECONFIG for harvester cluster
  ```sh
  export KUBECONFIG=<path-to-harvester-kubeconfig>
  ```

## Create namespace
```sh
kubectl apply -f -<<EOF
---
apiVersion: v1
kind: Namespace
metadata:
  name: gitea
  labels:
    kubernetes.io/metadata.name: gitea
    name: gitea
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/audit-version: latest
    pod-security.kubernetes.io/enforce: privileged
    pod-security.kubernetes.io/enforce-version: latest
    pod-security.kubernetes.io/warn: restricted
    pod-security.kubernetes.io/warn-version: latest
...
EOF
```

## Pre-create admin account As A Secret

```sh
kubectl apply -f -<<EOF
apiVersion: v1
data:
  password: <base64'ed password>
  username: <base64'ed username>
kind: Secret
metadata:
  name: admin-account
  namespace: gitea
EOF
```

## Create Your Values File
- gitea-values.yaml

```sh
cat > gitea-values.yaml <<EOF
clusterDomain: cluster.local
gitea:
  actions:
    ENABLED: true
  admin:
    existingSecret: admin-account
    passwordMode: initialOnlyRequireReset
  metrics:
    enabled: true
    serviceMonitor:
      enabled: false
  config:
    migrations:
      ALLOWED_DOMAINS: '*'
    server:
      ENABLE_PPROF: false
      DOMAIN: gitea.example.com
      ROOT_URL: https://gitea.example.com/
    service:
      DISABLE_REGISTRATION: true

redis:
  enabled: false

postgresql:
  enabled: false
  persistence:
    size: 10Gi

postgresql-ha:
  enabled: true
  persistence:
    size: 10Gi

redis-cluster:
  enabled: true

persistence:
  enabled: true
  #storageClass: harv-longhorn
  #claimName: <name>

global:
  imageRegistry: "harbor.example.com"
  imagePullSecrets: []
  storageClass: ""
  hostAliases: []

image:
  repository: gitea/gitea
  tag: ""
  pullPolicy: IfNotPresent
  rootless: true
ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: harvester-taclan-issuer
  hosts:
    - host: gitea.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: gitea-tls-secret
      hosts:
        - gitea.example.com
EOF
```

## Tie It Together
```sh
helm login -u <username> -p <password> https://harbor.example.com
helm repo add gitea oci://<chart-path> -n gitea -f gitea_values.yaml
```

## Check Your Gitea Website
- [Gitea Ingress](https://gitea.example.com)