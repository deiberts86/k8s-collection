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
5. Now to the installation of NGINX-Ingress:

```sh
helm upgrade --install nginx-secondary ingress-nginx/ingress-nginx --set controller.ingressClass="nginx-secondary" --set controller.ingressClassResource.default=false --set controller.ingressClassResource.name="nginx-secondary" --set controller.service.type=LoadBalancer --set controller.kind=DaemonSet --set controller.config.use-forwarded-headers=true --set controller.config.extraArgs.enable-ssl-passthrough=true --namespace nginx --create-namespace
```
- Note, this can be simplified with a `values.yaml` with all the appropriate flags needed. Also keep in mind that if you want the daemonset deployed, you need to ensure that `daemonset` is set with `controller.kind=DaemonSet`

6. Once successful, you should have a dedicated NGINX ingressClass just for SSL PASSTHROUGH and forward headers.

- Check Daemonset, ingresClass, and service:

```sh
kubectl -n nginx get svc # you should see nginx-controller with your load-balancer IP and nginx controller admission
kubectl -n nginx get pods -o wide # you should see pods on all of your workers / untainted nodes
kubectl get ingressClass # you should see your new "nginx-secondary" ingressClass
```

7. If your checks all pass and you have a valid external-IP for your service, you should now be able to use this `nginx-secondary` ingressClass.