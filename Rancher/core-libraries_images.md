# Tools Images
--------------
- Copy the contents below to bastionhost VM (jumpbox) in /var/tmp/rancher-temp/tools-images.txt
  - Add any other images you want with the name:tag format

```sh
cat > /var/tmp/tools-images.txt <<EOF >
ghcr.io/kube-vip/kube-vip:v0.7.1
ghcr.io/kube-vip/kube-vip-cloud-provider:v0.0.9
EOF
```

### `Create /bin/bash Script`

```console
vi /var/tmp/rancher-temp/pull-tools-images.sh
```
- paste contents below and save file

```sh
#!/bin/bash
for i in `cat /var/tmp/rancher-temp/tool-images.txt`; do 
  IMAGE_TAG=${i#*:}
  NO_TAG=${i%:*}
  REPO=${NO_TAG#*/}
  IMAGE_NAME=$(basename $REPO)
  echo "Moving ${i} to the registry"
  skopeo copy --override-os=linux --dest-tls-verify=false docker://$i docker://harbor.registry.com/core-libraries/${REPO}:${IMAGE_TAG}
  echo ""
done
```
### `Execute Shell Script`

```sh
# Give new shell script executable rights
chmod +x /var/tmp/rancher-temp/pull-tools-images.sh
# Execute Script (note: this will take a while)
sh /var/tmp/rancher-temp/pull-tools-images.sh
```