# Install Kubeseal (work in progress)

requirements:
- brew (macOS only)
- chocolaty (windowsOS only)
- helm
- kubectl
- a kubernetes cluster (minikube will work too)

## Kubernetes Installation ##
Add the helm repo on your admin workstation or admin laptop.
- helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets

Install sealed-secrets repo to kubernetes:
- helm install sealed-secrets-controller --namespace kube-system sealed-secrets/sealed-secrets

Validate that your pod is running:
- kubectl -n kube-system get pods | grep sealed

## Administrator's Workstation or Laptop Installation ##

MacOS:
- brew install kubeseal
check version:
- kubeseal --version

WindowsOS:
- choco install kubeseal -y
check version:
- .\kubeseal --version

## Seal a Secret and send to Kubernetes ##

references:
https://www.arthurkoziel.com/encrypting-k8s-secrets-with-sealed-secrets/