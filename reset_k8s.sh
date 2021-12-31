#!/usr/bin/env bash
set -e

docker ps -a --format '{{.Names}}' | grep '^k8s' | xargs -r docker stop
docker ps -a --format '{{.Names}}' | grep '^k8s' | xargs -r docker rm
mount | grep '/var/lib/kubernetes' | awk '{print $3}' | xargs -r umount
mount | grep '/var/lib/kubelet' | awk '{print $3}' | xargs -r umount
rm -rf /var/lib/kubernetes/ /var/lib/etcd/ /var/lib/cfssl/ /var/lib/kubelet/ /var/lib/cni || true
rm -rf /etc/kube-flannel/ /etc/kubernetes/ || true

echo ">>> Done"
