#!/bin/bash
JENKINS_ADMIN_USER="admin"
JENKINS_ADMIN_PASSWORD="admin"

# Install required plugins using Jenkins CLI
wget http://localhost:8080/jnlpJars/jenkins-cli.jar -O /tmp/jenkins-cli.jar
sleep 30  # Wait for Jenkins startup

java -jar /tmp/jenkins-cli.jar -s http://localhost:8080/ -auth ${JENKINS_ADMIN_USER}:${JENKINS_ADMIN_PASSWORD} install-plugin \
  git pipeline job-dsl workflow-aggregator matrix-auth docker-plugin docker-workflow blueocean credentials-binding \
  sonar kubernetes pipeline-stage-view quality-gates slack email-ext configuration-as-code webhook-step maven-plugin \
  jacoco junit

# Restart Jenkins
sudo systemctl restart jenkins
