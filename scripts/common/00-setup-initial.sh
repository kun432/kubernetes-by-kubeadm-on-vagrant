#!/bin/bash

set -euo pipefail

cat <<EOF | sudo tee -a /etc/hosts
10.240.0.10 controller-0
10.240.0.11 controller-1
10.240.0.12 controller-2
10.240.0.20 worker-0
10.240.0.21 worker-1
10.240.0.22 worker-2
EOF

# disable SELinux
sudo setenforce 0
sudo sed -i -e "s/^SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config

# disable firewalld
sudo systemctl stop firewalld
sudo systemctl disable firewalld
