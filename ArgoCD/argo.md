# Install ArgoCD

## Requirements
- Jumpbox (bastion host)
- kubectl
- helm
- kubernetes clsuter

## Reference
- [artifacthub.io](https://artifacthub.io/packages/helm/argo/argocd-apps)
- [argocd docs](https://argo-cd.readthedocs.io/en/stable/)

## Install

Login to your Jumpbox and configure your kubectl context to point to the right Kubernetes cluster. Then execute the following to install with Helm.

```sh
helm repo add argo https://argoproj.github.io/argo-helm --force-update
cat > argo_values.yaml <<EOF
server:
  ingress:
    enabled: true
    ingressClassName: "nginx"
    annotations:
      cert-manager.io/cluster-issuer: selfsigned-cluster-issuer
      nginx.ingress.kubernetes.io/ssl-passthrough: "true"
      nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
    hosts:
      - argocd.10-7-2-155.sslip.io
    https: true
    tls:
    - secretName: argo-tls
      hosts:
      - argocd.10-7-2-155.sslip.io
configs:
  params:
    server.insecure: "false"
EOF
helm upgrade -i argocd argo/argo-cd --namespace argocd --create-namespace --values argo_values.yaml
```

Ensure you can reach your website through the ingressClass named 'nginx'.  The provided values is a basic setup. Navigate through the other folders for additional options to add. Refer to the documentation for more...
