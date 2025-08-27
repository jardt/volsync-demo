#!/bin/bash

#snapshot controller

#Install Snapshot and Volume Group Snapshot CRDs:
kubectl kustomize https://github.com/kubernetes-csi/external-snapshotter/client/config/crd | kubectl create -f -
#Install Common Snapshot Controller:
kubectl -n kube-system kustomize https://github.com/kubernetes-csi/external-snapshotter/deploy/kubernetes/snapshot-controller | kubectl create -f -
#Install CSI Driver:
kubectl kustomize https://github.com/kubernetes-csi/external-snapshotter/deploy/kubernetes/csi-snapshotter | kubectl create -f -


#install helm

sudo snap install helm --classic

cp /etc/rancher/k3s/k3s.yaml ~/.kube/config

#volsync

helm repo add backube https://backube.github.io/helm-charts/
helm install --create-namespace -n volsync-system volsync backube/volsync
