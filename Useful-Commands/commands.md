For loop cleanup
```sh
kubectl get pods -n cattle-system | grep Image | awk ' { print $1 } ' | while read line; do kubectl delete pod $line -n cattle-system; done
```

```sh
cat image.list | while read line; do docker tag $line <private-registry>; done
```