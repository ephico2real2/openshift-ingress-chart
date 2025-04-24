# get credentials
crc console --credentials

To login as a regular user, run 'oc login -u developer -p developer https://api.crc.testing:6443'.
To login as an admin, run 'oc login -u kubeadmin -p BUYEc-kMPXc-pE7JZ-5KVQk https://api.crc.testing:6443'


# To upgrade
oc patch clusterversion version --type json -p '[{"op": "remove", "path": "/spec/overrides"}]'


oc get pods --all-namespaces --no-headers | grep "ContainerStatusUnknown" | awk '{print $1 " " $2}' | while read namespace pod; do oc delete pod "$pod" -n "$namespace"; done


