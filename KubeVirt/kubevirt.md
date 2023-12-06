# KubeVirt

## References
- [KubeVirt Architecture](https://kubevirt.io/user-guide/architecture/)
- [Install KubeVirt](https://kubevirt.io/user-guide/operations/installation/)
- [Create a Virtual Machine](https://kubevirt.io/labs/kubernetes/lab1.html)
- [How to Install virtctl](https://kubevirt.io/user-guide/operations/virtctl_client_tool/)
- [Use CDI](https://kubevirt.io/user-guide/operations/containerized_data_importer/)
- [KubeVirt Lifecycle of VMs](https://kubevirt.io/user-guide/virtual_machines/lifecycle/)

---
## Setup Requirements
- A bastionHost (Workstation or Jumpbox)
- Recommended to run on Bare-Metal Servers
- Can be run on a VM but requires a few more steps and it's also a performance penalty (nested virtualization)
  - VMware vSphere:
    - Edit your VM options > CPU > Enabled Hardware Virtualization checkbox (Expose hardware assisted virtualization to the guest OS)
    - Note, There is a developer option if needed to test without hardware virtualization
- Your worker nodes should be beefed up with vCPU and Memory to handle your workloads. Plan accordingly based on what's being deployed.
- A Kubernetes cluster to deploy your workloads
- krew (optional)
- multus CNI (recommended but is optional)
- virtctl
- kubectl
- CDI (Container Data Importer)

---
## Environment Tested
- Vsphere 8.x 
- Rocky 9.3 (Blue Onyx) with SELinux enforced
- 4 vCPU with virtualized hardware emulation enabled within vSphere
- 16 Gigabytes of RAM per Host
- 1 Gigabit NIC
- Tested with RKE2 six node cluster with three masters and three workers.

---
## Install `virtctl` Binary
- Login to your BastionHost or Workstation where you will be periodically execute this binary along with kubectl

```bash
KUBEVIRT_VERSION=$(curl -s https://api.github.com/repos/kubevirt/kubevirt/releases/latest | awk -F '[ \t":]+' '/tag_name/ {print $3}'); echo $KUBEVIRT_VERSION
curl -Lo virtctl https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_VERSION}/virtctl-${KUBEVIRT_VERSION}-linux-amd64
chmod +X virtctl; mv virtctl /usr/local/bin
echo 'checking version'
virtctl -version
```

---
## Install KubeVirt
- Create your namespace ahead of time with the proper labels for PSA
  - Note: you will see a error while applying the kubevirt-operator.yaml towards the namespace.  Just ignore.

```bash
KUBEVIRT_VERSION=$(curl -s https://api.github.com/repos/kubevirt/kubevirt/releases/latest | awk -F '[ \t":]+' '/tag_name/ {print $3}'); echo $VERSION
kubectl apply -f -<<EOF
---
apiVersion: v1
kind: Namespace
metadata:
  name: kubevirt
  labels:
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/audit-version: latest
    pod-security.kubernetes.io/enforce: privileged
    pod-security.kubernetes.io/enforce-version: latest
    pod-security.kubernetes.io/warn: restricted
    pod-security.kubernetes.io/warn-version: latest
EOF
kubectl create -f https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_VERSION}/kubevirt-operator.yaml
kubectl create -f https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_VERSION}/kubevirt-cr.yaml
```

---
## Create your First VM and Deploy
- first-test-vm

```bash
kubectl apply -f -<<EOF
---
apiVersion: v1
kind: Namespace
metadata:
  name: linux-vms
  labels:
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/audit-version: latest
    pod-security.kubernetes.io/enforce: privileged
    pod-security.kubernetes.io/enforce-version: latest
    pod-security.kubernetes.io/warn: restricted
    pod-security.kubernetes.io/warn-version: latest
---
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: first-test-vm
  namespace: linux-vms
spec:
  running: false
  template:
    metadata:
      labels:
        kubevirt.io/size: small
        kubevirt.io/domain: first-test-vm
    spec:
      domain:
        devices:
          disks:
          - name: containerdisk
            disk:
              bus: virtio
          - name: cloudinitdisk
            disk:
              bus: virtio
          interfaces:
          - name: default
            masquerade: {}
        resources:
          requests:
            memory: 64M
      networks:
      - name: default
        pod: {}
      volumes:
        - name: containerdisk
          containerDisk:
            image: quay.io/kubevirt/cirros-container-disk-demo
        - name: cloudinitdisk
          cloudInitNoCloud:
            userDataBase64: SGkuXG4=
EOF
```

- To start this VM

```bash
virtctl -n linux-vms start first-test-vm
```

- To console into this VM

```bash
virtctl -n linux-vms console first-test-vm
```

- To delete this VM

```bash
kubectl -n linux-vms delete first-test-vm
```

---
## Install and Use CDI (Containerized Data Importer)
- This is where you can store your images and the purpose of CDI
- StorageClass is required for persistent data. This example will be using Longhorn
- CDI supports `RAW` or `QCOW2` image formats

#### Install CDI

```bash
export VERSION=$(curl -Ls https://github.com/kubevirt/containerized-data-importer/releases/latest | grep -m 1 -o "v[0-9]\.[0-9]*\.[0-9]*"); echo $VERSION
kubectl create -f https://github.com/kubevirt/containerized-data-importer/releases/download/$VERSION/cdi-operator.yaml
kubectl create -f https://github.com/kubevirt/containerized-data-importer/releases/download/$VERSION/cdi-cr.yaml
```

#### Create A DataVolume Towards Your StorageClass
- Note, this will create a scratch PVC to process the data before writing to the target PVC [CDI Scratch Space](https://github.com/kubevirt/containerized-data-importer/blob/main/doc/scratch-space.md)

```bash
kubectl apply -f -<<EOF
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ubuntu-jammy-cloudimg
  namespace: linux-vms
  labels:
    app: containerized-data-importer
  annotations:
    cdi.kubevirt.io/storage.import.endpoint: "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
spec:
  storageClassName: longhorn
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
EOF
```

#### Create Virtual Machine from DataVolume
- This is to create a KubeVirt VM while using the image you just saved in the previous step.
- Cloud-init config is towards the bottom of the script and there are numerous options on how to configure this. For example, use the `whois` apt package to leverage the `mkpasswd` for your hashed password.

```bash
kubectl apply -f -<<EOF
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: ubuntu-jammy-testvm
  namespace: linux-vms
  labels:
    kubevirt.io/os: linux
spec:
  running: true
  template:
    metadata:
      labels:
        kubevirt.io/domain: linux-vms-ubuntu
    spec:
      domain:
        cpu:
          cores: 1
        devices:
          disks:
          - disk:
              bus: virtio
            name: disk0
          - cdrom:
              bus: sata
              readonly: true
            name: cloudinitdisk
        resources:
          requests:
            memory: 256M
      volumes:
      - name: disk0
        persistentVolumeClaim:
          claimName: ubuntu-jammy-cloudimg
      - cloudInitNoCloud:
          userData: |
            #cloud-config
            package_update: true
            package_upgrade: true
            hostname: ubuntu-test
            disable_root: false
            users:
            - name: root
              lock_passwd: false
              shell: /bin/bash
              hashed_passwd: '$6$xDFQIgI1voXeaMvJ$zEsThRpN2cg4n25n5tNzA.KqYNcAS48dLvVKh1rmc/khwVpRJ9UdruiTuKFFZnD0f.RuQdTR97RW4aJcERPVn.'
            late-commands:
            - useradd -m -R /target -u 1001 ubuntu
            - echo "ubuntu:ubuntu" | chroot /target /usr/sbin/chpasswd
            - usermod -R /target -aG sudo ubuntu
        name: cloudinitdisk
EOF
```

---
## Uninstall KubeVirt cleanly
- If you don't follow this approach, you will have some heartburn removing things.

```bash
export RELEASE=v1.1.0
kubectl delete -n kubevirt kubevirt kubevirt --wait=true # --wait=true should anyway be default
kubectl delete apiservices v1.subresources.kubevirt.io # this needs to be deleted to avoid stuck terminating namespaces
kubectl delete mutatingwebhookconfigurations virt-api-mutator # not blocking but would be left over
kubectl delete validatingwebhookconfigurations virt-operator-validator # not blocking but would be left over
kubectl delete validatingwebhookconfigurations virt-api-validator # not blocking but would be left over
kubectl delete -f https://github.com/kubevirt/kubevirt/releases/download/${RELEASE}/kubevirt-operator.yaml --wait=false
kubectl delete crd/cdis.cdi.kubevirt.io -n cdi
```