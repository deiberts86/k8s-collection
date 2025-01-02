**Setup Minio-Operator**
```bash
helm repo add minio-operator https://operator.min.io --force-update
helm search repo minio-operator
helm upgrade -i operator minio-operator/operator \
  --create-namespace \
  --namespace minio-operator
```
- Now let's create a way to get TO the operator UI