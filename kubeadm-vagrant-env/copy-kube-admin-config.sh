#!/bin/bash

echo "Copying kube admin config from kmaster to local machine..."

# Set cluster nodes address at local /etc/hosts
if ! grep -q kmaster /etc/hosts; then
echo "Setting nodes hosts in /etc/hosts..."
sudo cat >> /etc/hosts <<EOF
172.27.0.100 kmaster.example.com kmaster
172.27.0.101 kworker1.example.com kworker1
172.27.0.102 kworker2.example.com kworker2
EOF
fi

# Install kubectl
if ! which kubectl; then
  echo "Installing kubectl..."
  curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl" > /dev/null 2>&1
  chmod +x ./kubectl
  sudo mv ./kubectl /usr/local/bin/kubectl
fi

mkdir -p $HOME/.kube
echo "Installing sshpass..."
sudo apt install -y -q sshpass > /dev/null 2>&1
echo "Copying Kubernetes admin.conf..."
sshpass -p "kubeadmin" scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@kmaster.example.com:/etc/kubernetes/admin.conf $HOME/.kube/config
echo "Done!"

kubectl get nodes
