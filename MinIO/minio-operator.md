# Install MINIO-Operator

## **Tools needed**
- kubectl
- helm
- yq ["Download **yq** here from Github"](https://github.com/mikefarah/yq/#install)
  - You can also do a "snap install yq" if on Ubuntu Systems


### **Pull Charts**

```sh
curl -O https://raw.githubusercontent.com/minio/operator/master/helm-releases/operator-5.0.9.tgz
curl -O https://raw.githubusercontent.com/minio/operator/master/helm-releases/tenant-5.0.9.tgz
```

### **Deploy Operator**
```sh
 helm upgrade -i minio-operator ./operator-5.0.9.tgz --namespace minio-operator --create-namespace
```

### **Configure Operator**

* Only use `yq` if you need to adjust the service to NodePort
```sh
kubectl get service console -n minio-operator -o yaml > service.yaml
yq e -i '.spec.type="NodePort"' service.yaml
yq e -i '.spec.ports[0].nodePort = PORT_NUMBER' service.yaml
```
---------

* Update replica count
```sh
kubectl get deployment minio-operator -n minio-operator -o yaml > operator.yaml
yq -i -e '.spec.replicas |= 1' operator.yaml
```
---------

* Create your ingress
  - Note: Using Self-Signed Certificates but custom certs can be used
- Install Cert-manager and create a self-signed Cluster issuer CA

```sh
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: selfsigned
  namespace: cert-manager
spec:
  selfSigned: {}
```
- Create your ingress and annotate your `selfsigned` cluster-issuer

```sh
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    cert-manager.io/cluster-issuer: selfsigned
  name: minio-operator-ingress
  namespace: minio-operator
spec:
  ingressClassName: nginx
  rules:
    - host: fqdn-site-name
      http:
        paths:
          - backend:
              service:
                name: console
                port:
                  number: 9090
            path: /
            pathType: Prefix
  tls:
    - hosts:
        - fqdn-site-name
      secretName: string
```
### **Grab Your JWT Token**

* Export the following environment variable with kubectl command to retrieve JWT token

```sh
export SA_TOKEN=$(kubectl -n minio-operator  get secret console-sa-secret -o jsonpath="{.data.token}" | base64 --decode)
echo $SA_TOKEN
```

### **Navigate to your MinIO Operator site through your ingress**

* Go to your new ingress site you created and it should look something like this: https://fqdn-site-name/
  - Note: You should see a pretty nice webpage and you should have only one field to put in the JWT Token

### **OPTIONAL Install of Tenant**

* Note: `Tenant-ns` is whatever you want it to be.  If you want to make more tenants, simply re-run this command but ensure the names are not identical and optionally choose different namespace as well.

```sh
helm upgrade -i Tenant-ns ./tenant-5.0.9.tgz --namespace Tenant-ns
```

* Expose myminio-console for tenant
  - Note: Follow the similar process for creating an ingress for more longterm solutions

```sh
kubectl --namespace Tenant-ns port-forward svc/myminio-console 9443:9443
```

