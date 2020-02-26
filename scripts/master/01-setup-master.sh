#!/bin/bash

set -euo pipefail

KUBERNETES_VERSION=1.17.3
IPADDR=$(ip a show eth1 | grep inet | grep -v inet6 | awk '{print $2}' | cut -f1 -d/)
LBADDR=10.240.0.40
PODCIDR=10.200.0.0/16
HOSTNAME=$(hostname -s)

# kubeadm init
sudo kubeadm init \
  --control-plane-endpoint="${LBADDR}:6443" \
  --apiserver-advertise-address="${IPADDR}" \
  --kubernetes-version="v${KUBERNETES_VERSION}" \
  --pod-network-cidr="${PODCIDR}" \
  --upload-certs | sudo tee -a /etc/kubernetes/kubeadm-init.result

sudo --user=vagrant mkdir -p /home/vagrant/.kube
sudo cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
sudo chown $(id -u vagrant):$(id -g vagrant) /home/vagrant/.kube/config

sudo yum install wget -y
sudo wget https://docs.projectcalico.org/v3.11/manifests/calico.yaml
sed -i 's#value: "192.168.0.0/16"#value: "'${PODCIDR}'"#g' calico.yaml
kubectl apply -f calico.yaml

sudo kubeadm token create --print-join-command > /etc/kubeadm_join_cmd.sh
sudo chmod +x /etc/kubeadm_join_cmd.sh

sudo sed -i "/^[^#]*PasswordAuthentication[[:space:]]no/c\PasswordAuthentication yes" /etc/ssh/sshd_config
sudo systemctl restart sshd

sudo tar cvfz /Vagrant/k8s.tar.gz /etc/kubernetes/pki/ca.crt /etc/kubernetes/pki/ca.key /etc/kubernetes/pki/sa.key /etc/kubernetes/pki/sa.pub /etc/kubernetes/pki/front-proxy-ca.crt /etc/kubernetes/pki/front-proxy-ca.key /etc/kubernetes/pki/etcd/ca.crt /etc/kubernetes/pki/etcd/ca.key /etc/kubernetes/admin.conf
