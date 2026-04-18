# RustFS S3 Storage

RustFS is a great replacement for MinIO for self-hosted Kubernetes clusters. Especially for Homelab usage if you don't want to pay for cloud storage.

## Requirements

- Software:
  - kubectl
  - helm
  - awscli

- Infrastructure:
  - a valid Kubernetes cluster with a proper storageClass
  - Determine if you want distributed (High Availability) or Standalone
  - Ingress or GatewayAPI

## Helm Install rustFS

References:

[rustFS Helm Chart on Github](https://github.com/rustfs/helm)

- Recommended to create the secret for rustFS credentials which is nested within the `secret.existingSecret` section within the Helm values.yaml
  - You can do this with SOPs or manually create the secret.

### Add Helm Repo

```sh
# add rustfs helm chart repo
helm repo add rustfs https://rustfs.github.io/helm/ --force-update
# list the latest helm charts
helm search repo rustfs
```

### Create values.yaml

Create your values.yaml file to override the defaults. Tailor this to your environment.

```yaml
mode:
  standalone:
    enabled: true
  distributed:
    enabled: false

replicaCount: 1

image:
  repository: rustfs/rustfs
  pullPolicy: IfNotPresent

config:
  rustfs:
    log_level: "info"
    rust_log: "info"
    domains: "homelab"
    region: "us-east-1"

secret:
  existingSecret: rustfs-credentials

resources:
  requests:
    cpu: "500m"
    memory: "1Gi"
  limits:
    cpu: "2"
    memory: "4Gi"

# Check to ensure you're using a storageClass with "retain" policy
storageclass:
  name: "harvester-csi-retain"
  logStorageSize: "2Gi"
  dataStorageSize: "30Gi"

persistence:
  enabled: true
  size: 100Gi

service:
  type: ClusterIP

ingress:
  enabled: true
  className: "nginx"
  nginxAnnotations:
    nginx.ingress.kubernetes.io/affinity: "cookie"
    nginx.ingress.kubernetes.io/session-cookie-name: "rustfs"
    nginx.ingress.kubernetes.io/session-cookie-expires: "3600"
    nginx.ingress.kubernetes.io/session-cookie-max-age: "3600"
    nginx.ingress.kubernetes.io/session-cookie-hash: "sha1"
  customAnnotations:
    cert-manager.io/cluster-issuer: "homelab-ca"
  hosts:
  - host: rustfs.homelab
    paths:
    - path: /
      pathType: Prefix
  tls:
    enabled: true
    certManager:
      enabled: true

gatewayApi:
  enabled: false
```

### Install rustFS

```sh
helm upgrade -i rustfs rustfs/rustfs \
  -n rustfs --create-namespace \
  -f values.yaml
```
