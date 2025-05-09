#!/bin/bash

# Update system and install essential packages
sudo apt-get update -y
sudo apt-get install -y openjdk-17-jdk maven git curl wget unzip ufw jq xmlstarlet

# Install Docker
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Add user to docker group for permission to run Docker without sudo
sudo usermod -aG docker $USER
echo "Please log out and log back in for Docker group changes to take effect."

# Install SonarQube (Ensure Docker is running first)
sudo systemctl start docker
sudo systemctl enable docker

echo "Pulling SonarQube Docker image..."
sudo docker pull sonarqube

if [ $? -ne 0 ]; then
    echo "Failed to pull SonarQube Docker image. Exiting."
    exit 1
fi

# Run SonarQube in Docker
echo "Starting SonarQube Docker container..."
sudo docker run -d --name sonarqube -p 9000:9000 sonarqube

if [ $? -ne 0 ]; then
    echo "Failed to start SonarQube container. Exiting."
    exit 1
fi

# Install Jenkins
curl -fsSL https://pkg.jenkins.io/debian/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update -y
sudo apt-get install -y jenkins

# Start and enable services
sudo systemctl start docker
sudo systemctl enable docker
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Open firewall ports
sudo ufw allow 8080
sudo ufw allow 22
sudo ufw enable

# Print Jenkins Initial Admin Password
echo "Jenkins Admin Password:"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
