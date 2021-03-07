#!/bin/bash
## RBAC account creator
## AUTHOR: MPL (mpl@i3dlabs.com)
## Purpose: Create a full access account to ONLY ONE namespace in Kubernetes
## Assumes: Ubuntu 20.04 minimal, kubernetes cluster up and running and you
###         have full control over the cluster.
## License: CC Attribution 4.0 International (CC BY 4.0)
set -e
set -v
echo "New Namespace: " 
read NS 
echo "New Namespace Username: " 
read US
echo "Kube cluster API endpoint: [ex: https://localhost:6443] " 
read CLU_EP
echo "Kube cluster common name: " 
read CLU_NAME

kubectl create ns $NS

cat > access-$NS-$US.yaml <<EOF
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: $NS-$US
  namespace: $NS

---
kind: Role
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: $NS-$US-full-access
  namespace: $NS
rules:
- apiGroups: ["", "extensions", "apps"]
  resources: ["*"]
  verbs: ["*"]
- apiGroups: ["batch"]
  resources:
  - jobs
  - cronjobs
  verbs: ["*"]

---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: $NS-$US-view
  namespace: $NS
subjects:
- kind: ServiceAccount
  name: $NS-$US
  namespace: $NS
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: $NS-$US-full-access
EOF

kubectl create -f access-$NS-$US.yaml

TOKEN_ID=`kubectl get secret -A |grep $NS-$US|awk '{print $2}'`

USER_TOKEN=`kubectl get secret $TOKEN_ID -n $NS -o "jsonpath={.data.token}" | base64 -d`
USER_CERT=`kubectl get secret $TOKEN_ID -n $NS -o "jsonpath={.data['ca\.crt']}"`

echo "---> Your generated kubeconfig file is kubeconfig-$NS-$US"

cat > kubeconfig-$NS-$US <<EOF
apiVersion: v1
kind: Config
preferences: {}

clusters:
- cluster:
    certificate-authority-data: $USER_CERT
    server: $CLU_EP
  name: $CLU_NAME

users:
- name: $US
  user:
    as-user-extra: {}
    client-key-data: $USER_CERT
    token: $USER_TOKEN

contexts:
- context:
    cluster: $CLU_NAME
    namespace: $NS
    user: $US
  name: $NS

current-context: $NS
EOF
