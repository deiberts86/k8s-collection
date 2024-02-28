# RKE2 NGINX Ingress Options
  - Note, this is downstream from the main NGINX Product.  These options should work with the standard NGINX deployment as well. Just adjust name and namespace accordingly.

#### Disable Weak Ciphers
- Use your own Cipher suite as desired

```sh
apiVersion: helm.cattle.io/v1
kind: HelmChartConfig
metadata:
  name: rke2-ingress-nginx
  namespace: kube-system
spec:
  valuesContent: |-
    controller:
      config:
        disable-access-log: "false"
        ssl-ciphers: ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384 
        ssl-protocols: TLSv1.3
        ssl-prefer-server-ciphers: off
```

#### Enable Transactional Logging
- Granular logging of transactions for ingress

```sh
apiVersion: helm.cattle.io/v1
kind: HelmChartConfig
metadata:
  name: rke2-ingress-nginx
  namespace: kube-system
spec:
  valuesContent: |-
    controller:
      config:
        enable-access-log-for-default-backend: true
```

#### Enable HSTS Protocol
- Turns on HTTP Strict Transfer Protocol

```sh
apiVersion: helm.cattle.io/v1
kind: HelmChartConfig
metadata:
  name: rke2-ingress-nginx
  namespace: kube-system
spec:
  valuesContent: |-
    controller:
      config:
        hsts: "true"
        hsts-include-subdomains: "true"
        hsts-max-age: 15550000 # 180 Days for Example
        hsts-preload: "false"
```

#### Enable SSL-Passthrough
- Used for containers that require TLS termination at the pod directly.

```sh
apiVersion: helm.cattle.io/v1
kind: HelmChartConfig
metadata:
  name: rke2-ingress-nginx
  namespace: kube-system
spec:
  valuesContent: |-
    controller:
      config:
        use-forwarded-headers: "true"
      extraArgs:
        enable-ssl-passthrough: "true"
```

#### NGINX extra controller args example:

```sh
apiVersion: helm.cattle.io/v1
kind: HelmChartConfig
metadata:
  name: rke2-ingress-nginx
  namespace: kube-system
spec:
  valuesContent: |-
    controller:
      config:
        force-ssl-redirect: true
        proxy-body-size: 0
        proxy-read-timeout: 1800
        proxy-request-buffering: 'off'
        proxy-send-timeout: 1800
```

#### Disable Host Ports
- Disable if you don't want port 80 or 443 exposed on the host directly.

```sh
apiVersion: helm.cattle.io/v1
kind: HelmChartConfig
metadata:
  name: rke2-ingress-nginx
  namespace: kube-system
spec:
  valuesContent: |-
    controller:
      kind: DaemonSet
      daemonset:
        useHostPort: false
```

#### Enable Load Balancer Servies and Publish

```sh
apiVersion: helm.cattle.io/v1
kind: HelmChartConfig
metadata:
  name: rke2-ingress-nginx
  namespace: kube-system
spec:
  valuesContent: |-
    controller:
      publishService:
        enabled: true
      service:
        enabled: true
```

#### Change Default Certificate for Ingress
- Used to be a trusted certificate regardless if backend service is unreachable.

```sh
apiVersion: helm.cattle.io/v1
kind: HelmChartConfig
metadata:
  name: rke2-ingress-nginx
  namespace: kube-system
spec:
  valuesContent: |-
    controller:
      extraArgs:
        # create tls-secret in your default namespace and set your "namespace/secret-name"
        default-ssl-certificate: default/rke2-cert-nginx
```

#### Enable Snippets | [Snippets How-to](https://docs.nginx.com/nginx-ingress-controller/configuration/ingress-resources/advanced-configuration-with-snippets/)
- This is an advance option and can have security implications.

```sh
apiVersion: helm.cattle.io/v1
kind: HelmChartConfig
metadata:
  name: rke2-ingress-nginx
  namespace: kube-system
spec:
  valuesContent: |-
    controller:
      enableSnippets:
        enabled: true
```
OR
```sh
apiVersion: helm.cattle.io/v1
kind: HelmChartConfig
metadata:
  name: rke2-ingress-nginx
  namespace: kube-system
spec:
  valuesContent: |-
    controller:
      allowSnippetAnnotations: "true"
```

#### Add Kubernetes Tolerations
- Useful if you want to isolate or force deploy this application on a specific tainted node/s.

```sh
apiVersion: helm.cattle.io/v1
kind: HelmChartConfig
metadata:
  name: rke2-ingress-nginx
  namespace: kube-system
spec:
  valuesContent: |-
    controller:
      tolerations:
        - key: "key"
          operator: "Exists"
          effect: "NoSchedule"
```

#### Enable Metrics for Prometheus Scraping

```sh
apiVersion: helm.cattle.io/v1
kind: HelmChartConfig
metadata:
  name: rke2-ingress-nginx
  namespace: kube-system
spec:
  valuesContent: |-
    controller:
      metrics:
        service:
          annotations:
            prometheus.io/scrape: "true"
            prometheus.io/port: "10254"
```
