#!/bin/bash

set -euo pipefail

# disable swap off
sudo swapoff -a
#sudo sed -i '/ swap / s/^\\(.*\\)$/#\\1/g' /etc/fstab
sudo sed -i '/ swap /s/^\(.*\)$/#\1/g' /etc/fstab
sudo rm -rf /swapfile

# install kubernetes repository
cat <<EOF | sudo tee -a /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kube*
EOF

# install kubeadm, kubelet, kubectl
sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

# enable kubelet
sudo systemctl enable --now kubelet

# enable network bridge
cat <<'EOF' | sudo tee -a /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system

# install docker
sudo yum install -y yum-utils device-mapper-persistent-data lvm2
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
VERSION=$(yum list docker-ce --showduplicates | sort -r | grep 17.03 | head -1 | awk '{print $2}')
sudo yum install -y --setopt=obsoletes=0 docker-ce-$VERSION docker-ce-selinux-$VERSION
sudo systemctl enable docker && sudo systemctl start docker
sudo usermod -aG docker vagrant

# cgoup
sudo mkdir -p /etc/docker
sudo cat > /etc/docker/daemon.json <<'EOF'
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
sudo mkdir -p /etc/systemd/system/docker.service.d

# Restart Docker
sudo systemctl daemon-reload
sudo systemctl restart docker

# get private network IP addr and set bind it to kubelet
IPADDR=$(ip a show eth1 | grep inet | grep -v inet6 | awk '{print $2}' | cut -f1 -d/)
sudo sed -i "/KUBELET_EXTRA_ARGS=/c\KUBELET_EXTRA_ARGS=--node-ip=$IPADDR" /etc/sysconfig/kubelet

# restart kubelet
sudo systemctl daemon-reload
sudo systemctl restart kubelet

