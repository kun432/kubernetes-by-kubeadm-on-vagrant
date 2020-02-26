#!/bin/bash

set -euo pipefail

NFS_SERVER='10.240.0.30'
REMOTE_VOLUME='/var/share/nfs'
LOCAL_VOLUME='/mnt/nfs'

sudo yum install rpcbind nfs-utils -y
#sudo mkdir -p ${LOCAL_VOLUME}
#sudo mount -t nfs ${NFS_SERVER}:${REMOTE_VOLUME} ${LOCAL_VOLUME}

