# Install `cert-manager`

```sh
helm upgrade -i \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.13.0 \
  --set installCRDs=true
```

# Create CA Issuer Certificates

```sh
kubectl apply -f -<<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: selfsigned-issuer
spec:
  selfSigned: {}
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: test-cluster-ca
  namespace: cert-manager
spec:
  isCA: true
  commonName: test-cluster-ca
  secretName: root-secret
  privateKey:
    algorithm: ECDSA
    size: 256
  issuerRef:
    name: selfsigned-issuer
    kind: ClusterIssuer
    group: cert-manager.io
---
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: test-cluster-ca-issuer
spec:
  ca:
    secretName: root-secret
EOF
```

### Update your CA Cert on your hosts for Insecure Registry to work within Rancher for pulling images locally.

1. Login to your BastionHost server (jumpbox)
2. Export your kubeconfig and validate you're using the right configuration context
3. execute this command to get your `cert-manager` generated CA certificate
   ```sh
   cd /home/ranchuser
   sudo -s
   export KUBECONFIG=${Path/to/your/kubeconfig}
   kubectl -n cert-manager get secret root-secret -o jsonpath='{.data.tls\.crt}' | base64 -d | tee ca-cert.pem
   ```
4. Copy that configuration and run an ansible job to update your ca-trust store on all servers.

`Update to a Trusted CA signed certificate in the future and you woudn't need to do these steps above.`

### Annotate NGINX Ingress When Needed

```sh
apiVersion: v1
kind: Ingress
metadata:
  annotations:
    cert-manager.io/cluster-issuer: test-cluster-ca-issuer
```