# Harbor on Kubernetes

Harbor is a self-hosted container registry that has a GUI and docker registry endpoint. Harbor also supports OCI artifacts and scanning services. Harbor also has the ability to be used with `cosign` to sign images.

## Requirements

Certain requirements needs to be meet:

- `A valid Kubernetes Cluster`
- `Cert-manager (optional)`
  - If you do not want to use Cert-manager, you will need to bring your own TLS certificate
- `StorageClass to support stateful storage`

Tools required:

- kubectl
- helm
- valid kubeconfig context

## Installation Process

`Harbor` is also installed via `Helm`. First, add the repo:

```sh
helm repo add harbor https://helm.goharbor.io --force-update
```

Now install:

```sh
helm upgrade \
  harbor harbor/harbor \
  --install \
  --namespace harbor \
  --create-namespace \
  --version 1.18.3 \
  --set externalURL=https://harbor.homelab \
  --set expose.tls.certSource=secret \
  --set expose.tls.secret.secretName="harbor.local-tls" \
  --set expose.ingress.hosts.core="harbor.homelab" \
  --set expose.ingress.annotations."cert-manager\.io/cluster-issuer"="<name>" \
  --set persistence.persistentVolumeClaim.database.size=5Gi \
  --set persistence.persistentVolumeClaim.registry.size=30Gi
```

Grab the bootstrap admin password via:

```sh
kubectl get secret -n harbor harbor-core -otemplate='{{.data.HARBOR_ADMIN_PASSWORD | base64decode}}'
```

The username is `admin`.
