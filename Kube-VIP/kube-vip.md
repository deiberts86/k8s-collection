# Install KubeVIP and KubeVIP Cloud Provider

## Install Script via Manifest

Requirements:
- kubectl
- active kubernetes cluster with the proper kubeconfig | context (what cluster do you want to deploy to?)

Reference:
[KubeVIP with Manifest](https://kube-vip.io/docs/installation/daemonset/)

```bash
kubectl apply -f -<<EOF
---
# Apply Kube-VIP Daemonset for virtual IP
apiVersion: v1
kind: ServiceAccount
metadata:
  name: kube-vip
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
  name: system:kube-vip-role
rules:
  - apiGroups: [""]
    resources: ["services", "services/status", "nodes", "endpoints"]
    verbs: ["list","get","watch", "update"]
  - apiGroups: ["coordination.k8s.io"]
    resources: ["leases"]
    verbs: ["list", "get", "watch", "update", "create"]
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: system:kube-vip-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:kube-vip-role
subjects:
- kind: ServiceAccount
  name: kube-vip
  namespace: kube-system
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: kube-vip-ds
  namespace: kube-system
spec:
  selector:
    matchLabels:
      name: kube-vip-ds
  template:
    metadata:
      labels:
        name: kube-vip-ds
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: node-role.kubernetes.io/master
                operator: Exists
            - matchExpressions:
              - key: node-role.kubernetes.io/control-plane
                operator: Exists
      containers:
      - args:
        - manager
        env:
        - name: vip_arp
          value: "true"
        - name: port
          value: "6443"
        - name: vip_interface
          value: ens33
        - name: vip_cidr
          value: "32"
        - name: cp_enable
          value: "true"
        - name: cp_namespace
          value: kube-system
        - name: vip_ddns
          value: "false"
        - name: svc_enable
          value: "true"
        - name: vip_leaderelection
          value: "true"
        - name: vip_leaseduration
          value: "5"
        - name: vip_renewdeadline
          value: "3"
        - name: vip_retryperiod
          value: "1"
        - name: address
          value: 192.168.30.50
        image: ghcr.io/kube-vip/kube-vip:v0.6.4
        imagePullPolicy: Always
        name: kube-vip
        resources: {}
        securityContext:
          capabilities:
            add:
            - NET_ADMIN
            - NET_RAW
            - SYS_TIME
      hostNetwork: true
      serviceAccountName: kube-vip
      tolerations:
      - effect: NoSchedule
        operator: Exists
      - effect: NoExecute
        operator: Exists
  updateStrategy: {}
status:
  currentNumberScheduled: 0
  desiredNumberScheduled: 0
  numberMisscheduled: 0
  numberReady: 0
---
# Apply Kube-VIP Cloud Provider Deployment
apiVersion: v1
kind: ServiceAccount
metadata:
  name: kube-vip-cloud-controller
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
  name: system:kube-vip-cloud-controller-role
rules:
  - apiGroups: ["coordination.k8s.io"]
    resources: ["leases"]
    verbs: ["get", "create", "update", "list", "put"]
  - apiGroups: [""]
    resources: ["configmaps", "endpoints","events","services/status", "leases"]
    verbs: ["*"]
  - apiGroups: [""]
    resources: ["nodes", "services"]
    verbs: ["list","get","watch","update"]
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: system:kube-vip-cloud-controller-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:kube-vip-cloud-controller-role
subjects:
- kind: ServiceAccount
  name: kube-vip-cloud-controller
  namespace: kube-system
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kube-vip-cloud-provider
  namespace: kube-system
spec:
  replicas: 1
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      app: kube-vip
      component: kube-vip-cloud-provider
  strategy:
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 25%
    type: RollingUpdate
  template:
    metadata:
      labels:
        app: kube-vip
        component: kube-vip-cloud-provider
    spec:
      containers:
      - command:
        - /kube-vip-cloud-provider
        - --leader-elect-resource-name=kube-vip-cloud-controller
        image: ghcr.io/kube-vip/kube-vip-cloud-provider:v0.0.7
        name: kube-vip-cloud-provider
        imagePullPolicy: Always
      dnsPolicy: ClusterFirst
      restartPolicy: Always
      terminationGracePeriodSeconds: 30
      serviceAccountName: kube-vip-cloud-controller
      tolerations:
      - key: node-role.kubernetes.io/master
        effect: NoSchedule
      - key: node-role.kubernetes.io/control-plane
        effect: NoSchedule
      affinity:
        nodeAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 10
            preference:
              matchExpressions:
              - key: node-role.kubernetes.io/control-plane
                operator: Exists
          - weight: 10
            preference:
              matchExpressions:
              - key: node-role.kubernetes.io/master
                operator: Exists
---
# Apply ConfigMap | Reserve in your IPAM to prevent these IPs from being used by something else!
apiVersion: v1
data:
  cidr-kube-system: 192.168.1.55/32
  range-kube-system: 192.168.1.56-192.168.1.60
kind: ConfigMap
metadata:
  name: kubevip
  namespace: kube-system
...
EOF
```

## Install with Helm

Requirements:
- Helm
- active kubernetes cluster with the proper kubeconfig | context (what cluster do you want to deploy to?)

References:
[KubeVIP with Helm](https://github.com/kube-vip/helm-charts)
[KubeVIP Helm Chart Releases](https://github.com/kube-vip/helm-charts/releases)

---
Prepare your values.yaml files:

#### Kube-VIP Daemonset Values

```bash
cat > kube-vip_daemonset-values.yaml <<EOF
# Default values for kube-vip.
# This is a YAML-formatted file.
# Declare variables to be passed into your templates.

image:
  repository: ghcr.io/kube-vip/kube-vip
  pullPolicy: Always
  # Overrides the image tag whose default is the chart appVersion.
  tag: "v0.6.4"

config:
  address: "192.168.1.50"

env:
  vip_interface: "ens33"
  vip_arp: "true"
  lb_enable: "true"
  lb_port: "6443"
  vip_cidr: "32"
  cp_enable: "true"
  svc_enable: "true"
  svc_election: "false"
  vip_leaderelection: "true"

envValueFrom: {}
  # Specify environment variables using valueFrom references (EnvVarSource)
  # For example we can use the IP address of the pod itself as a unique value for the routerID
#bgp_routerid:
#  fieldRef:
#    fieldPath: status.podIP

envFrom: []
  # Specify an externally created Secret(s) or ConfigMap(s) to inject environment variables
  # For example an externally provisioned secret could contain the password for your upstream BGP router, such as
  #
  # apiVersion: v1
  # data:
  #   bgp_peers: "<address:AS:password:multihop>"
  # kind: Secret
  #   name: kube-vip
  #   namespace: kube-system
  # type: Opaque
  #
#- secretKeyRef:
#    name: kube-vip

imagePullSecrets: []
nameOverride: ""
fullnameOverride: ""

serviceAccount:
  # Specifies whether a service account should be created
  create: true
  # Annotations to add to the service account
  annotations: {}
  # The name of the service account to use.
  # If not set and create is true, a name is generated using the fullname template
  name: ""

podAnnotations: {}

podSecurityContext: {}
# fsGroup: 2000

securityContext:
  capabilities:
    add:
      - NET_ADMIN
      - NET_RAW
      - SYS_TIME

resources: {}
  # We usually recommend not to specify default resources and to leave this as a conscious
  # choice for the user. This also increases chances charts run on environments with little
  # resources, such as Minikube. If you do want to specify resources, uncomment the following
  # lines, adjust them as necessary, and remove the curly braces after 'resources:'.
# limits:
#   cpu: 100m
#   memory: 128Mi
# requests:
#   cpu: 100m
#   memory: 128Mi

nodeSelector: {}

tolerations:
  - effect: NoSchedule
    key: node-role.kubernetes.io/control-plane
    operator: Exists
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      - matchExpressions:
        - key: node-role.kubernetes.io/master
          operator: Exists
      - matchExpressions:
        - key: node-role.kubernetes.io/control-plane
          operator: Exists
EOF
```

#### Kube-VIP Cloud Provider Values

```bash
cat > kube-vip_cloud-provider-values.yaml <<EOF
# Default values for kube-vip-cloud-provider.
# This is a YAML-formatted file.
# Declare variables to be passed into your templates.

replicasCount: 1

image:
  repository: kubevip/kube-vip-cloud-provider
  pullPolicy: IfNotPresent
  # Overrides the image tag whose default is the chart appVersion.
  tag: "v0.0.7"

resources:
  requests:
    cpu: 50m
    memory: 64Mi
  limits:
    cpu: 100m
    memory: 128Mi

tolerations:
  - key: node-role.kubernetes.io/master
    effect: NoSchedule
  - key: node-role.kubernetes.io/control-plane
    effect: NoSchedule

affinity:
  nodeAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 10
        preference:
          matchExpressions:
            - key: node-role.kubernetes.io/control-plane
              operator: Exists
      - weight: 10
        preference:
          matchExpressions:
            - key: node-role.kubernetes.io/master
              operator: Exists
EOF
```

#### Put it all together
Note, create your configmap ahead of time that's referenced in the instructions above.  Doing so will allow for faster deployment of load balancer if needed.

- With Internet Access:

```bash
helm repo add kube-vip https://kube-vip.github.io/helm-charts; helm repo update
curl -L -o kube-vip-0.4.4.tgz https://github.com/kube-vip/helm-charts/releases/download/kube-vip-0.4.4/kube-vip-0.4.4.tgz
helm upgrade -i kube-vip-daemon ./kube-vip-0.4.4.tgz --namespace kube-system --values kube-vip_daemonset-values.yaml
helm upgrade -i kube-vip-cloud-provider ./kube-vip-0.4.4.tgz --namespace kube-system --values kube-vip_cloud-provider-values.yaml
helm ls -A
```

- AirGap:
  - Note, have not tested this part as of yet.
```bash
curl -L -o kube-vip-0.4.4.tgz https://github.com/kube-vip/helm-charts/releases/download/kube-vip-0.4.4/kube-vip-0.4.4.tgz
```

Move your values.yaml files and helm tarball to your AirGap network then execute on a bastion host:

```bash
helm upgrade -i kube-vip-daemon ./kube-vip-0.4.4.tgz --namespace kube-system --values kube-vip_daemonset-values.yaml
helm upgrade -i kube-vip-cloud-provider ./kube-vip-0.4.4.tgz --namespace kube-system --values kube-vip_cloud-provider-values.yaml
helm ls -A
```