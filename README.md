# Volsync demo

This example will spin up two lima vm's, each with its own k3s cluster.
The end state is replication of the data in a pvc between the two cluseters using volsync.
In this example the method used is rsync over ssh.

### Running

`cd scripts`
`bash setup.sh`

This will create the vm's (requires lima installed). Deploy volsync and metallb as well as the resources required for everything to work.

#### manual steps required

##### editing the ssh key secret

A ssh key is needed for sender pod to be able to ssh into reciver pod. The ssh key is created as a secret in the reciver cluster. This key is copied over to the sender cluster by the script, but requires some editing. The script will open the secrit in a editor.

- Remove all fields in metadata except name and namespace ( see comment at end of secret file when it is open in editor)
- Save and let script continue.

##### get external ip of destination service in reciver cluster

We need this for the ReplicationSource to tell it where to connect
(see printout at end of setup script)

##### insert adress in ReplicationSource resource in sender

Use ip from step above in the spec.rsync.address when editing this resource
(see printout at end of setup script)

### Components

#### Data generation

The source cluster will deploy a busybox pod which will write the current timestamp to a file in the "test-pvc" volume every minute.

#### volsync

Each cluster will deploy volsync and the csi snapshotter. The sender cluster will have a ReplicationSource resource
telling volsync how and where to sync the "test-pvc" volume. The reciver will have a ReplicationDestination to tell volsync how to recive the data.

#### metallb

deployed on the reciver to get a external ip for the destination service so the destination pod cat be reached from the other cluster

### cleanup

`cd scripts`
`bash cleanup.sh`
