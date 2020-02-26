#!/bin/bash

set -euo pipefail

# https://qiita.com/Esfahan/items/1b5b3a74dcd86fd30e5c

sudo yum update -y
sudo yum install -y rpcbind nfs-utils

EXPORTS_FILE='/etc/exports'
DEFINITION='/var/share/nfs 10.240.0.0/24(rw,no_root_squash)'

sudo mkdir -p /var/share/nfs

sudo cat ${EXPORTS_FILE} | grep -w "${DEFINITION}" > /dev/null 2>&1
if [ $? = 1 ]; then
  echo "${DEFINITION}" | sudo tee -a ${EXPORTS_FILE}
  sudo exportfs -ra
  sudo exportfs -v
else
  echo 'Alreday defined.'
fi

IDMAPD_FILE='/etc/idmapd.conf'
ORIGINAL='#Domain = local\.domain\.edu'
REPLACED='Domain = local\.domain\.edu'

sudo sed -i -e "s/${ORIGINAL}/${REPLACED}/g" ${IDMAPD_FILE}

sudo systemctl start rpcbind
sudo systemctl start nfs-server
sudo systemctl start nfs-lock
sudo systemctl start nfs-idmap
sudo systemctl enable nfs-server
