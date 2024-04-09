# Test Network Overlay Settings
  * This is a swiss-armyknife pod that will be provisioned to test your cluster network

```bash
kubectl apply -f -<<EOF
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: overlaytest
  namespace: kube-system
spec:
  selector:
      matchLabels:
        name: overlaytest
  template:
    metadata:
      labels:
        name: overlaytest
    spec:
      tolerations:
      - operator: Exists
      containers:
      - image: rancherlabs/swiss-army-knife
        imagePullPolicy: Always
        name: overlaytest
        command: ["sh", "-c", "tail -f /dev/null"]
        terminationMessagePath: /dev/termination-log
EOF
```

* Execute the Overlay Test

```bash
#!/bin/bash
echo "=> Start network overlay test"
  kubectl -n kube-system get pods -l name=overlaytest -o jsonpath='{range .items[*]}{@.metadata.name}{" "}{@.spec.nodeName}{"\n"}{end}' |
  while read spod shost
    do kubectl -n kube-system get pods -l name=overlaytest -o jsonpath='{range .items[*]}{@.status.podIP}{" "}{@.spec.nodeName}{"\n"}{end}' |
    while read tip thost
      do kubectl -n kube-system --request-timeout='10s' exec $spod -c overlaytest -- /bin/sh -c "ping -c2 $tip > /dev/null 2>&1"
        RC=$?
        if [ $RC -ne 0 ]
          then echo FAIL: $spod on $shost cannot reach pod IP $tip on $thost
          else echo $shost can reach $thost
        fi
    done
  done
echo "=> End network overlay test"
```