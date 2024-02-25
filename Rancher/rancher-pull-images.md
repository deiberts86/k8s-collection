# Pull and Push Rancher Related Containers to Private Repository
- Note: This is restrictive and really meant for deployments that doesn't have internet access. Otherwise, leverage a proxy-cache.

## Requirements:
- Required software:
  - skopeo 
- login to jumpbox (bastion host) and sudo su your account to be root.
  - Ensure you have enough disk space
  - You will need to change your Default Registry and setup registries.yaml files to point your dedicated harbor repo. This will be done after your images makes it to the repository of your choice.
--------

## `Prep and Pull Image Lists`
```sh
export RKE2_VER=v1.24.16+rke2r1
export RANCHER_VER=v2.7.1
export RKE2_VER_DASH=`echo $RKE2_VER | sed s/+/-/`
mkdir -p /var/tmp/rancher-temp
cd /var/tmp/rancher-temp
curl -L https://github.com/rancher/rancher/releases/download/${RANCHER_VER}/rancher-images.txt | sed 's/docker.io\///g' > /var/tmp/rancher-temp/rancher-images.txt
curl -L https://github.com/rancher/rke2/releases/download/${RKE2_VER}/rke2-images.linux-amd64.txt | sed 's/docker.io\///g' >> /var/tmp/rancher-temp/rancher-images.txt
echo "rancher/system-agent-installer-rke2:${RKE2_VER_DASH}" >> /var/tmp/rancher-temp/rancher-images.txt
sort -u /var/tmp/rancher-temp/rancher-images.txt -o /var/tmp/rancher-temp/rancher-images.txt
```

## `Push Images to Private Registry`

- Login to the repository first before moving further!
  - Note: You can use your own token login or a robot account for this

```console
skopeo login --tls-verify=false harbor.registry.com
```

### `Create /bin/bash Script`

```console
vi /var/tmp/rancher-temp/pull-rancher-images.sh
```
- paste contents below and save file

```sh
#!/bin/bash
for i in `cat /var/tmp/rancher-temp/*.txt`; do 
  IMAGE_TAG=${i#*:}
  NO_TAG=${i%:*}
  REPO=${NO_TAG#*/}
  IMAGE_NAME=$(basename $REPO)
  echo "Moving ${i} to the registry"
  skopeo copy --override-os=linux --dest-tls-verify=false docker://$i docker://harbor.registry.com/core-libraries/rancher/${REPO}:${IMAGE_TAG}
  echo ""
done
```

### `Execute Shell Script`

```sh
# Give new shell script executable rights
chmod +x /var/tmp/rancher-temp/pull-rancher-images.sh
# Execute Script (note: this will take a while)
sh /var/tmp/rancher-temp/pull-rancher-images.sh
```
- Ideally run this either first thing in the morning or late in the afternoon
- Check the Harbor repo you're pointing to and ensure that your files shows up properly.