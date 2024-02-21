# OADP Installation and Test

## Pre-Requisites

Tests have been made with

* OpenShift version 4.14.8_1545
* Operator OADP 1.3.0 (Velero v1.12.1)
* Operator VolSync

## Install the OADP operator

We will install this operator using the command line

![operator](images/operator-selection.png)

1. Find the OADP operator you want to install from OperatorHub

    ```sh
    oc get packagemanifests | grep oadp
    ```

1. Inspect your desired Operator to verify its supported install modes and available channels.

    ```sh
    oc describe packagemanifests redhat-oadp-operator
    ```

1. Verify that the cluster service version (CSV)

    ```sh
    oc describe packagemanifests redhat-oadp-operator -n openshift-marketplace | grep CSV
    ```

1. Create a new Project

    ```sh
    oc new-project openshift-adp
    ```

1. Install the Red Hat OADP operator

    ```sh
    oc apply -f - <<EOF
    ---
    apiVersion: operators.coreos.com/v1alpha1
    kind: Subscription
    metadata:
      name: redhat-oadp-operator
      namespace: openshift-adp
    spec:
      channel: oadp-operator.v1.3.0
      installPlanApproval: Automatic 
      name: redhat-oadp-operator
      source: redhat-operators
      sourceNamespace: openshift-marketplace
    EOF
    ```

## Steps

1. Edit the file `ibmcos-bucket-creds.json`. Replace the values with your own values from earlier steps and enter it in the value field.

    ```sh
    [default]
    aws_access_key_id=<INSERT_VALUE>
    aws_secret_access_key=<INSERT_VALUE>
    ```

    > Note: Do not use quotes while putting values in place of INSERT_VALUE Placeholders.

2. Create the Bucket access credential Kube Secret with NAME “cloud-credentials” and KEY as “cloud”

    ```sh
    oc create secret generic cloud-credentials -n openshift-adp --from-file cloud=ibmcos-bucket-creds.json
    ```

3. Create RESTIC Credentials used for Object Storage Data encryption by Restic

    ```sh
    oc apply -f dm-credential.yaml
    ```

4. Create DataProtectionApplication CR to configure OADP for the cluster. Update COS bucket URL and bucket name (in BOLD below)

    ```sh
    oc apply -f oadp-dpa-ibmcos.yaml
    ```

5. Verify OADP Pods running successfully under “openshift-adp” Namespace

    ```sh
    oc get all -n openshift-adp
    ```

6. Modify VolumeSnapshotClass

    ```sh
    oc patch volumesnapshotclass ocs-storagecluster-rbdplugin-snapclass --type=merge -p '{"deletionPolicy": "Retain"}'
    ```

7. xx

    ```sh
    oc label volumesnapshotclass ocs-storagecluster-rbdplugin-snapclass velero.io/csi-volumesnapshot-class="true"
    ```

## Create a sample application with an ODF PVC

1. Create a sample ODF PVC

    ```sh
    oc apply -f odf-pvc.yaml
    ```

1. Create a sample application with an ODF PVC

    ```sh
    oc apply -f odf-pod.yaml
    ```

1. Verify the Application is Running

    ```sh
    oc exec -it odf-pod -- sh
    df -h
    echo “hello123” >/test/hello123.txt
    ```

## Create a Backup

1. Create a Backup CR to take the Application Namespace backup onto the Object storage.

    ```sh
    oc apply -f mybackup.yaml
    ```

1. XX

## Resources

* [Git repo for ODAP Operator](https://github.com/openshift/oadp-operator)