# Useful Commands Towards Rancher Application

## Rebuild Bootstrap Password 
- Useful if it's missing due to initial secret being removed from numerous retries.

```sh
kubectl -n cattle-system exec $(kubectl -n cattle-system get pods -l app=rancher | grep '1/1' | head -1 | awk '{ print $1 }') -- reset-password
```

## Remove Rancher-System-Agent on Failed Cluster Provisioning

```sh
sh /usr/local/bin/rancher-system-agent-uninstall.sh
sh usr/local/bin/rke2-uninstall.sh
```

## Possible Fix for Custom Nodes Not Completing Configuration

```sh
# Validation they even exist
kubectl -n cattle-system get secret | grep cattle-webhook
kubectl get mutatingwebhookconfigurations
kubectl get validatingwebhookconfigurations
# Removal Process to allow it to self-heal
kubectl -n cattle-system delete secret cattle-webhook-ca
kubectl -n cattle-system delete secret cattle-webhook-tls
kubectl delete mutatingwebhookconfigurations rancher.cattle.io 
kubectl delete validatingwebhookconfigurations rancher.cattle.io
kubectl -n cattle-system rollout restart deploy/cattle-cluster-agent
kubectl -n cattle-system rollout restart deploy/rancher-webhook
```