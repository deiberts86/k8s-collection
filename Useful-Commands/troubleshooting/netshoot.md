# NetShoot Kubernetes Troubleshooting Tool
  - Github page: [NetShoot](https://github.com/nicolaka/netshoot) 

## Deploy the Application

```bash
kubectl apply -f -<<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-netshoot
  namespace: kube-system
  labels:
    app: nginx-netshoot
spec:
  replicas: 1
  selector:
    matchLabels:
        app: nginx-netshoot
  template:
    metadata:
      labels:
        app: nginx-netshoot
    spec:
      containers:
      - name: nginx
        image: nginx:1.14.2
        ports:
        - containerPort: 80
      - name: netshoot
        image: nicolaka/netshoot
        command: ["/bin/bash"]
        args: ["-c", "while true; do ping localhost; sleep 60;done"]
EOF
```
- This deployment will create a POD with two containers.  NGINX and NetShoot containers will be created.
- Wait for the containers to be built and EXEC into the pod directly to leverage commands for testing.  Ensure you're using the NetShoot Pod itself, not NGINX!

## Commands to Use

* Test Cluster DNS to Upstream Rancher

```bash
drill -V 5 rancher.site.domain
```

* Test 