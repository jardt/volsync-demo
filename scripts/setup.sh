#!/bin/bash

if ! command -v limactl > /dev/null; then
    echo "lima needs to be installed"
    exit 1
fi

# create and start vm

limactl create --name=sender template://k3s  --network=lima:user-v2
limactl create --name=reciver template://k3s --network=lima:user-v2 

limactl start sender
limactl start reciver

DIR=$(pwd)

echo $DIR
# istall helm and set up volsync

limactl copy deploy-volsync.sh sender:deploy-volsync.sh
limactl copy deploy-volsync.sh reciver:deploy-volsync.sh
limactl copy deploy-metallb.sh reciver:deploy-metallb.sh

limactl copy ../objects/ip-pool.yaml reciver:ip-pool.yaml

limactl shell reciver -- bash deploy-volsync.sh
limactl shell sender -- bash deploy-volsync.sh
limactl shell reciver -- bash deploy-metallb.sh

limactl copy ../objects/l2announce.yaml reciver:l2announce.yaml

echo "waiting for objects to be ready"
sleep 18

limactl shell reciver -- kubectl apply -f ip-pool.yaml 
limactl shell reciver -- kubectl apply -f l2announce.yaml

limactl copy ../objects/ReplicationDestinaton.yaml reciver:ReplicationDestination.yaml

limactl copy ../objects/busybox-datagenerator.yaml sender:busybox-datagenerator.yaml
limactl copy ../objects/ReplicationSource.yaml sender:ReplicationSource.yaml


limactl shell reciver -- kubectl apply -f ReplicationDestination.yaml
limactl shell sender -- kubectl apply -f busybox-datagenerator.yaml
limactl shell sender -- kubectl apply -f ReplicationSource.yaml

echo "waiting for objects to be ready"
sleep 18

limactl shell reciver -- kubectl get secret volsync-rsync-dst-main-volsync-dest -o yaml > ../copyfolder/volsync-ssh-keys.yaml
echo "#DELETE EVERYTHING EXCEPT DATA, NAMA, NAMESPACE, AND TYPE" >> ../copyfolder/volsync-ssh-keys.yaml
limactl copy  ../copyfolder/volsync-ssh-keys.yaml sender:volsync-ssh-keys.yaml
limactl shell sender -- vim volsync-ssh-keys.yaml

limactl shell sender -- kubectl apply -f volsync-ssh-keys.yaml

echo "###############################################################################"
echo "####################### MANUAL STEPS TO GET THIS WORKING ######################"
echo "###############################################################################"

echo "---"
echo "get external ip for reciver / destination service:"
echo "limactl shell reciver -- kubectl get svc"
echo "---"
echo "edit senders ReplicationSource spec.rsync.adress field with that ip"
echo "limactl shell sender -- kubectl edit ReplicationSource volsync-source"

echo "---"

echo "Now the pvc  in the reciver should have the same data as in the source"
echo "verify with:"
echo "get dest pod name in recever"
echo "limactl shell reciver -- kubectl get pods"
echo "limactl shell reciver -- kubectl exec -it {pod name of volsync dest} -- /bin/sh"
echo "cat the data/data.txt file to see that the data has been synced"

