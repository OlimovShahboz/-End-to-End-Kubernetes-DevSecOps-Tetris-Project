#!/bin/bash
set -euo pipefail
exec > >(tee -a /var/log/tools-install.log) 2>&1
export DEBIAN_FRONTEND=noninteractive

# Versions (one place to change them)
JENKINS_VERSION="2.568.3"
TERRAFORM_VERSION="1.14.9"
KUBECTL_VERSION="v1.33.5"
TRIVY_VERSION="0.72.0"
SONARQUBE_TAG="26.1.0.118079-community"

# Base packages
apt-get update
apt-get install -y ca-certificates curl wget gnupg unzip fontconfig
install -d -m 0755 /etc/apt/keyrings

# Java 21 (Jenkins 2.555+ requires 21 or 25)
apt-get install -y openjdk-21-jre
java --version

# Jenkins LTS (stable repo, 2026 signing key)
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key \
  -o /etc/apt/keyrings/jenkins-keyring.asc
echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" \
  > /etc/apt/sources.list.d/jenkins.list
apt-get update
apt-get install -y jenkins="${JENKINS_VERSION}"
apt-mark hold jenkins

# Docker (Ubuntu's own package)
apt-get install -y docker.io
usermod -aG docker jenkins
usermod -aG docker ubuntu
systemctl enable --now docker
systemctl restart jenkins     # so Jenkins picks up the docker group

# SonarQube (container)
echo "vm.max_map_count=524288" > /etc/sysctl.d/99-sonarqube.conf
sysctl --system
docker run -d --name sonarqube --restart unless-stopped \
  -p 9000:9000 "sonarqube:${SONARQUBE_TAG}"

# Terraform (zip from HashiCorp, checksum verified)
cd /tmp
curl -fsSLO "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
curl -fsSLO "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS"
grep "terraform_${TERRAFORM_VERSION}_linux_amd64.zip" "terraform_${TERRAFORM_VERSION}_SHA256SUMS" | sha256sum --check
unzip -o "terraform_${TERRAFORM_VERSION}_linux_amd64.zip" terraform
install -o root -g root -m 0755 terraform /usr/local/bin/terraform
terraform version

# kubectl (checksum verified)
curl -fsSLO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
curl -fsSLO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl.sha256"
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client

# AWS CLI v2
curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o awscliv2.zip
unzip -q -o awscliv2.zip
./aws/install --update
aws --version

# Trivy (.deb from the official GitHub release, not the apt repo)
cd /tmp
curl -fsSLO "https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-64bit.deb"
dpkg -i "trivy_${TRIVY_VERSION}_Linux-64bit.deb"
trivy --version

echo "tools-install finished OK"