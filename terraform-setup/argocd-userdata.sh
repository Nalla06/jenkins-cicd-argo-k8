#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status
exec > >(tee -i /var/log/minikube_setup.log) 2>&1  # Log output

echo "==== Updating System ===="
sudo apt-get update -y
sudo apt-get upgrade -y

echo "==== Installing Required Packages ===="
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release

echo "==== Installing Docker ===="
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com | sh
    sudo usermod -aG docker $USER
    newgrp docker
    sudo systemctl enable docker
    sudo systemctl start docker
else
    echo "Docker is already installed."
fi

echo "==== Installing Minikube ===="
curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
chmod +x minikube
sudo mv minikube /usr/local/bin/

echo "==== Installing kubectl ===="
curl -LO "https://dl.k8s.io/release/$(curl -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

echo "==== Starting Minikube ===="
minikube start --driver=docker

echo "==== Installing Helm ===="
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

echo "==== Installing ArgoCD ===="
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "==== Waiting for ArgoCD to be Ready ===="
sleep 60

echo "==== Retrieving ArgoCD Admin Password ===="
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode)
echo "ArgoCD Admin Password: $ARGOCD_PASSWORD"

# Save to a file for easy access
echo "$ARGOCD_PASSWORD" > /home/ubuntu/argocd_admin_password.txt
chmod 600 /home/ubuntu/argocd_admin_password.txt

echo "==== Password saved to /home/ubuntu/argocd_admin_password.txt ===="

echo "==== Exposing ArgoCD API ===="
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'

echo "==== Installation Complete! ===="
