# Install with a Yum Repository
- You can have satellite server pull this repo and have servers point to a satellite provided repo.
- Ensure to change the RKE2_MINOR version to what you want.
- Ensure you change the LINUX_MAJOR version to what you want.

## Repositories
```sh
export RKE2_MINOR=28
export LINUX_MAJOR=9 # or 8 or 9 etc
cat << EOF > /etc/yum.repos.d/rancher-rke2-1-${RKE2_MINOR}-latest.repo
[rancher-rke2-common-latest]
name=Rancher RKE2 Common Latest
baseurl=https://rpm.rancher.io/rke2/latest/common/centos/${LINUX_MAJOR}/noarch
enabled=1
gpgcheck=1
gpgkey=https://rpm.rancher.io/public.key

[rancher-rke2-1-${RKE2_MINOR}-latest]
name=Rancher RKE2 1.${RKE2_MINOR} Latest
baseurl=https://rpm.rancher.io/rke2/latest/1.${RKE2_MINOR}/centos/${LINUX_MAJOR}/x86_64
enabled=1
gpgcheck=1
gpgkey=https://rpm.rancher.io/public.key
EOF
```