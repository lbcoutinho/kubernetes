#!/bin/bash

echo "Initializing Kubernetes cluster..."
# Initialize Kubernetes
echo "(1/4): Initialize Kubernetes Cluster"
kubeadm init --apiserver-advertise-address=172.27.0.100 --pod-network-cidr=192.168.0.0/16 >> /root/kubeinit.log 2>/dev/null

# Copy Kube admin config
echo "(2/4): Copy kube admin config to Vagrant user .kube directory"
mkdir /home/vagrant/.kube
cp /etc/kubernetes/admin.conf /home/vagrant/.kube/config
chown -R vagrant:vagrant /home/vagrant/.kube

# Deploy Calico network
echo "(3/4): Deploy Calico network"
su - vagrant -c "kubectl apply -f https://docs.projectcalico.org/v3.11/manifests/calico.yaml > /dev/null 2>&1"

# Generate Cluster join command
echo "(4/4): Generate and save cluster join command to /join-cluster.sh"
kubeadm token create --print-join-command > /join-cluster.sh

echo "Done!"