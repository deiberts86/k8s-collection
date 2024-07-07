# Cilium Network Policies
- Reference:
  - [Cilium Network Policies](https://docs.cilium.io/en/latest/security/policy/)
  - [Cilium L7 Examples](https://docs.cilium.io/en/latest/security/policy/language/#layer-7-examples)
  - [Graphical Network Policy Tester](https://editor.networkpolicy.io/)

## Examples
- [Example Application Demo](https://docs.cilium.io/en/latest/gettingstarted/demo/#deploy-the-demo-application)

```sh
kubectl create -f https://raw.githubusercontent.com/cilium/cilium/HEAD/examples/minikube/http-sw-app.yaml
kubectl get services
kubectl get pods,CiliumEndpoints
```
- Time to land some crafts

```sh
kubectl exec xwing -- curl -s -XPOST deathstar.default.svc.cluster.local/v1/request-landing
kubectl exec tiefighter -- curl -s -XPOST deathstar.default.svc.cluster.local/v1/request-landing
```

```sh
kubectl apply -f -<<EOF
apiVersion: "cilium.io/v2"
kind: CiliumNetworkPolicy
metadata:
  name: "rule1"
spec:
  description: "L7 policy to restrict access to specific HTTP call"
  endpointSelector:
    matchLabels:
      org: empire
      class: deathstar
  ingress:
  - fromEndpoints:
    - matchLabels:
        org: empire
    toPorts:
    - ports:
      - port: "80"
        protocol: TCP
      rules:
        http:
        - method: "POST"
          path: "/v1/request-landing"
EOF
kubectl describe ciliumnetworkpolicies
```

- Cleanup
```sh
kubectl delete -f https://raw.githubusercontent.com/cilium/cilium/HEAD/examples/minikube/http-sw-app.yaml
kubectl delete cnp rule1
```
