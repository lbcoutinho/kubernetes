#!/bin/bash

echo "Copying kube admin config from kmaster to local machine..."

mkdir -p $HOME/.kube
sudo apt install -y -q sshpass > /dev/null 2>&1
sshpass -p "kubeadmin" scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@kmaster.example.com:/home/vagrant/.kube/config $HOME/.kube/config 2>/dev/null
echo "Done!"

kubectl get nodes