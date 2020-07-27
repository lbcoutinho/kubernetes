#!/bin/bash

# Join worker nodes to the Kubernetes cluster
echo "Joining node to Kubernetes Cluster..."
yum install -y -q sshpass > /dev/null 2>&1
sshpass -p "kubeadmin" scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no kmaster.example.com:/join-cluster.sh /join-cluster.sh 2>/dev/null
bash /join-cluster.sh > /dev/null 2>&1

echo "Done!"