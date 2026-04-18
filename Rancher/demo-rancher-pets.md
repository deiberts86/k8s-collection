# Rancher Pets Demo

Credit to <https://github.com/janeczku/rancher-demo>

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: app-demo
  labels:
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/audit-version: latest
    pod-security.kubernetes.io/enforce: privileged
    pod-security.kubernetes.io/enforce-version: latest
    pod-security.kubernetes.io/warn: restricted
    pod-security.kubernetes.io/warn-version: latest
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: pets
  namespace: app-demo
  labels:
    app: pets
spec:
  replicas: 3
  selector:
    matchLabels:
      app: pets
  template:
    metadata:
      labels:
        app: pets
    spec:
      containers:
      - name: pets
        image: janeczku/rancher-demo:0.5.0
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: pets
  namespace: app-demo
  labels:
    app: pets
spec:
  selector:
    app: pets
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
  type: ClusterIP
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: pets-ingress
  namespace: app-demo
  annotations:
    nginx.ingress.kubernetes.io/forwarded-for-header: "X-Forwarded-For"
    nginx.ingress.kubernetes.io/real-ip-header: "X-Real-IP"
    nginx.ingress.kubernetes.io/proxy-real-ip-cidr: "xxx.xxx.xxx.0/24"  # Adjust to match your HAProxy network
spec:
  rules:
  - host: app.demo
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: pets
            port:
              number: 80
