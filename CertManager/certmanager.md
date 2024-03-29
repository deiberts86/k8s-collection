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

### Create Your Secret From Cert-Manager Tied To Your CA

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: example-com
  namespace: sandbox
spec:
  # Secret names are always required.
  secretName: example-com-tls
  duration: 2160h # 90d
  renewBefore: 360h # 15d
  subject:
    organizations:
      - jetstack
  # The use of the common name field has been deprecated since 2000 and is
  # discouraged from being used.
  commonName: example.com
  isCA: false
  privateKey:
    algorithm: RSA
    encoding: PKCS1
    size: 2048
  usages:
    - server auth
    - client auth
  # At least one of a DNS Name, URI, IP address or otherName is required.
  dnsNames:
    - example.com
    - www.example.com
  ipAddresses:
    - 192.168.0.5
  issuerRef:
    name: ca-issuer
    # We can reference ClusterIssuers by changing the kind here.
    # The default value is Issuer (i.e. a locally namespaced Issuer)
    kind: Issuer
    # This is optional since cert-manager will default to this value however
    # if you are using an external issuer, change this to that issuer group.
    group: cert-manager.io
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