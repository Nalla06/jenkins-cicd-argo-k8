#!/bin/bash

# Update system
sudo apt-get update -y

# Install necessary packages
sudo apt-get install -y openjdk-17-jdk maven git curl wget unzip ufw

# Install Docker
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER  # Add user to the docker group

# Install Jenkins
curl -fsSL https://pkg.jenkins.io/debian/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update -y
sudo apt-get install -y jenkins

# Start and enable Jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Open necessary firewall ports
sudo ufw allow 8080  # Jenkins UI
sudo ufw allow 50000 # Jenkins agent
sudo ufw allow 22    # SSH
sudo ufw enable

# Install Kubernetes (Minikube)
curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
chmod +x minikube
sudo mv minikube /usr/local/bin/

# Install kubectl (Kubernetes CLI)
curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Start Minikube
sudo minikube start --driver=docker

# Install Helm (Kubernetes Package Manager)
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Expose ArgoCD API
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

# Wait for ArgoCD to be ready
echo "Waiting for ArgoCD to be ready..."
sleep 60

# Get ArgoCD admin password
ARGOCD_ADMIN_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode)
echo "ArgoCD Admin Password: $ARGOCD_ADMIN_PASSWORD"

# Install SonarQube Scanner (for Maven)
sudo apt-get install -y sonar-scanner

# Install Jenkins Plugins Automatically
echo "Installing Jenkins plugins..."
JENKINS_CLI="http://localhost:8080/jnlpJars/jenkins-cli.jar"

# Wait until Jenkins CLI is available
until curl -sL "$JENKINS_CLI" -o jenkins-cli.jar; do
    echo "Waiting for Jenkins CLI to be available..."
    sleep 10
done

# Install necessary plugins
java -jar jenkins-cli.jar -s http://localhost:8080/ -auth admin:$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword) install-plugin \
  git pipeline job-dsl workflow-aggregator matrix-auth docker-plugin docker-workflow blueocean credentials-binding sonar kubernetes pipeline-stage-view quality-gates

# Restart Jenkins to apply plugins
sudo systemctl restart jenkins

echo "Installation completed!"
