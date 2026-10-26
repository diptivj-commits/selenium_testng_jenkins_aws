#!/usr/bin/env bash
# Run on Ubuntu 24.04 x86_64 EC2. Installs software; does not create AWS resources.
set -euo pipefail
[[ $(dpkg --print-architecture) == amd64 ]] || { echo 'Use an x86_64/amd64 instance'; exit 1; }
sudo apt-get update
sudo apt-get install -y fontconfig openjdk-21-jdk maven git curl unzip ca-certificates gnupg
sudo install -d -m 0755 /etc/apt/keyrings
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key | sudo tee /etc/apt/keyrings/jenkins-keyring.asc >/dev/null
echo 'deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/' | sudo tee /etc/apt/sources.list.d/jenkins.list >/dev/null
sudo apt-get update
sudo apt-get install -y jenkins
work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT
curl -fsSL https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -o "$work_dir/chrome.deb"
chmod 755 "$work_dir"
chmod 644 "$work_dir/chrome.deb"
sudo apt-get install -y "$work_dir/chrome.deb"
if ! command -v aws >/dev/null; then
  curl -fsSL https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o "$work_dir/aws.zip"
  unzip -q "$work_dir/aws.zip" -d "$work_dir"
  sudo "$work_dir/aws/install"
fi
sudo systemctl enable --now jenkins
java -version
mvn -version
google-chrome --version
aws --version
echo 'Unlock Jenkins: sudo cat /var/lib/jenkins/secrets/initialAdminPassword'
