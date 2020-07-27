#!/bin/bash

echo "Installing Kubernetes..."
# Update hosts file
echo "(1/13): Update /etc/hosts file"
cat >> /etc/hosts <<EOF
172.27.0.100 kmaster.example.com kmaster
172.27.0.101 kworker1.example.com kworker1
172.27.0.102 kworker2.example.com kworker2
EOF

# Install docker from Docker-ce repository
echo "(2/13): Install docker container engine"
yum install -y -q yum-utils device-mapper-persistent-data lvm2 > /dev/null 2>&1
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo > /dev/null 2>&1
yum -y -q update > /dev/null 2>&1
yum install -y -q containerd.io docker-ce docker-ce-cli > /dev/null 2>&1

# Set up the Docker daemon
echo "(3/13): Set up the Docker daemon"
mkdir /etc/docker
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
EOF
mkdir -p /etc/systemd/system/docker.service.d

# Start and Enable docker service
echo "(4/13): Start and enable docker service"
systemctl daemon-reload
systemctl enable --now docker > /dev/null 2>&1

# Disable swap
echo "(5/13): Disable and turn off SWAP"
sed -i '/swap/d' /etc/fstab
swapoff -a

# Load br_netfilter explicitly
echo "(6/13): Load br_netfilter"
modprobe br_netfilter

# Stop and disable firewalld to avoid having to open all required ports
# https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#check-required-ports
echo "(7/13): Stop and Disable firewalld"
systemctl disable firewalld >/dev/null 2>&1
systemctl stop firewalld

# Add sysctl settings to ensure iptables can correctly see bridged traffic
echo "(8/13): Set iptables in sysctl settings"
cat >> /etc/sysctl.d/kubernetes.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system > /dev/null 2>&1

# This is required to allow containers to access the host filesystem, which is needed by pod networks for example.
# You have to do this until SELinux support is improved in the kubelet.
echo "(9/13): Disable SELinux"
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
# sed -i --follow-symlinks 's/^SELINUX=enforcing/SELINUX=disabled/' /etc/sysconfig/selinux

# Add yum repo file for Kubernetes
echo "(10/13): Add yum repo file for kubernetes"
cat >> /etc/yum.repos.d/kubernetes.repo <<EOF
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF

# Install Kubernetes
echo "(11/13): Install Kubernetes (kubeadm, kubelet and kubectl)"
yum install -y -q kubelet kubeadm kubectl --disableexcludes=kubernetes > /dev/null 2>&1
systemctl enable --now kubelet > /dev/null 2>&1

# Enable SSH password authentication
echo "(12/13): Enable SSH password authentication"
sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl reload sshd

# Set Root password
echo "(13/13): Set root password"
echo "kubeadmin" | passwd --stdin root > /dev/null 2>&1

# Update vagrant user's bashrc file
echo "export TERM=xterm" >> /etc/bashrc

echo "Done!"