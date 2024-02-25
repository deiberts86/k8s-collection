# Install `Harbor`

`Harbor` is also installed via `Helm`. First, add the repo:

```sh
helm repo add harbor https://helm.goharbor.io
helm repo update
```

Now install:

```sh
helm upgrade \
  harbor harbor/harbor \
  --install \
  --namespace harbor \
  --create-namespace \
  --version 1.14.0 \
  --set externalURL=https://harbor.10-7-2-66.sslip.io \
  --set expose.tls.certSource=secret \
  --set expose.tls.secret.secretName="harbor.local-tls" \
  --set expose.ingress.hosts.core="harbor.10-7-2-66.sslip.io" \
  --set expose.ingress.annotations."cert-manager\.io/cluster-issuer"="<name>" \
  --set persistence.persistentVolumeClaim.database.size=5Gi \
  --set persistence.persistentVolumeClaim.registry.size=30Gi
```
```sh
helm upgrade -i harbor harbor/harbor --create-namespace --namespace harbor --version 1.14.0 --set externalURL=https://harbor.10-7-2-66.sslip.io --set expose.tls.certSource=secret --set expose.tls.secret.secretName="harbor.local-tls" --set expose.ingress.hosts.core="harbor.10-7-2-63.sslip.io" --set expose.ingress.hosts.notary="notary.harbor.10-7-2-66.sslip.io" --set expose.ingress.annotations."cert-manager\.io/cluster-issuer"="<name>" --set persistence.persistentVolumeClaim.database.size=5Gi  --set persistence.persistentVolumeClaim.registry.size=30Gi
```

Grab the bootstrap admin password via:

```sh
kubectl get secret -n harbor harbor-core -otemplate='{{.data.HARBOR_ADMIN_PASSWORD | base64decode}}'
```

The username is `admin`.


### Create Rancher MCM NavLink

```sh
apiVersion: ui.cattle.io/v1
kind: NavLink
metadata:
  name: harvester01-harbor
spec:
  group: "Harbor"
  toURL: https://rancher.10-7-2-160.sslip.io/k8s/clusters/c-m-xlsdhj5j/api/v1/namespaces/harbor/services/http:harbor-portal:80/proxy/account/sign-in
```