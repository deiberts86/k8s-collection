# Installation of Rancher MCM packages via Helm
- Your PSA exemption should already be declared within the `/etc/rancher/rke2/rancher-pss.yaml` location. If not, you will need to pre-seed your namespaces.

```sh
helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
helm repo update
helm upgrade -i rancher rancher-stable/rancher --create-namespace --namespace cattle-system --set hostname=rancher.10-7-2-70.sslip.io--set rancherImage=harbor.10-7-2-65.sslip.io/rancher/rancher
```