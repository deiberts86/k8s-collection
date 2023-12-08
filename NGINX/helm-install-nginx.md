# Install NGINX
- The purpose of this is to install a secondary ingress/ingress-class to be dedicated for SSL-PASSTHROUGH and forward headers. You can also do this for other options if desired.

## Requirements
1. Have a bastion host (jumpbox)
2. Ensure Helm is installed
3. Ensure kubectl is installed
4. Ensure you have a load-balancer service strategy

## Installation Process
1. Login to your bastion host and export your kubeconfig to the cluster you want to leverage.  To test, you can execute `kubectl get nodes` or `helm ls -A`.  If you get an error, this is due to not having the `kube-config` available or not exported properly to your cluster you're trying to reach. You will have to adjust the server address in your `kube-config` to point to your load-balancer or VIP if using Kube-VIP.
2. Once you do get a successful output, now it's time to install the additional NGINX daemonset.
3. Add the helm repo on your bastion host:

```sh
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
```
4. Ensure that you have a load-balancer IP address reserved. Leverage MetalLB or KubeVIP for bare-metal or whatever your external load-balancer is I.E. F5, AWS, etc. Once reserved, you want to ensure you define your new NGINX Daemonset to be as a service load-balancer. 
5. Now to the installation of NGINX-Ingress as a one-liner:

```sh
helm upgrade --install nginx-secondary ingress-nginx/ingress-nginx --set controller.ingressClass="nginx-secondary" --set controller.ingressClassResource.default=false --set controller.ingressClassResource.name="nginx-secondary" --set controller.service.type=LoadBalancer --set controller.kind=DaemonSet --set controller.config.use-forwarded-headers=true --set controller.config.extraArgs.enable-ssl-passthrough=true --namespace nginx --create-namespace
```

7. Or create your own values.yaml file for easier deployment. Note, you can add more values as needed. Examples provided in the `helm-values-example` folder in this repo.

8. Create your `nginx-values.yaml` file.

```sh
cat > nginx-values.yaml <<EOF
controller:
  admissionWebhooks:
    createSecretJob:
      securityContext:
        allowPrivilegeEscalation: false
  kind: DaemonSet
  config:
    use-forwarded-headers: true
    extraArgs:
      enable-ssl-passthrough: true
  ingressClass: nginx-secondary
  ingressClassResource:
    defaults: false
  ingressClassResource:
    name: nginx-secondary
  service:
    type: LoadBalancer
EOF
```
9. Now to use your new values file.

```sh
helm upgrade -i nginx-secondary ingress-nginx/ingress-nginx --create-namespace --namespace nginx --values nginx-values.yaml
```

- Note: Keep in mind that if you want the daemonset deployed, you need to ensure that `daemonset` is set with `controller.kind=DaemonSet`

10. Once successful, you should have a dedicated NGINX ingressClass just for SSL PASSTHROUGH and forward headers.

- Check Daemonset, ingresClass, and service:

```sh
kubectl -n nginx get svc # you should see nginx-controller with your load-balancer IP and nginx controller admission
kubectl -n nginx get pods -o wide # you should see pods on all of your workers / untainted nodes
kubectl get ingressClass # you should see your new "nginx-secondary" ingressClass
```

11. If your checks all pass and you have a valid external-IP for your service, you should now be able to use this `nginx-secondary` ingressClass.

12. Add your network policy for your ingress.

```sh
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: nginx-secondary-default-net-policy
  namespace: nginx
spec:
  ingress:
    - ports:
        - port: 80
          protocol: TCP
        - port: 443
          protocol: TCP
  podSelector:
    matchExpressions:
      - key: app.kubernetes.io/instance
        operator: In
        values:
          - nginx-secondary
    matchLabels:
      app.kubernetes.io/instance: nginx-secondary
  policyTypes:
    - Ingress
status: {}
```
