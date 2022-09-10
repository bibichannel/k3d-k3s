#!/bin/sh

export CLUSTER_NAME=$1
export SERVERS=$2
export AGENTS=$3
echo $CLUSTER_NAME-$SERVERS-$AGENTS

k3d cluster create $CLUSTER_NAME --servers $SERVERS --agents $AGENTS --k3s-arg "--disable=traefik@server:0" --k3s-arg "--disable=servicelb@server:0" --no-lb --wait

CIDR_BLOCK=$(docker network inspect k3d-$CLUSTER_NAME | jq '.[0].IPAM.Config[0].Subnet' | tr -d '"')
CIDR_BASE_ADDR=${CIDR_BLOCK%???}
INGRESS_FIRST_ADDR=$(echo $CIDR_BASE_ADDR | awk -F'.' '{print $1,$2,0,240}' OFS='.')
INGRESS_LAST_ADDR=$(echo $CIDR_BASE_ADDR | awk -F'.' '{print $1,$2,0,250}' OFS='.')
INGRESS_RANGE=$INGRESS_FIRST_ADDR-$INGRESS_LAST_ADDR
echo $INGRESS_RANGE

# Switch context current cluster
kubectl config use-context k3d-$CLUSTER_NAME

# install metallb
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

export filename=values.yaml
cat << EOF > $filename
apiVersion: metallb.io/v1beta1
kind: AddressPool
metadata:
  namespace: kube-system
  name: metallb-config
spec:
  protocol: layer2
  addresses:     
  - $INGRESS_RANGE
EOF

helm upgrade --install --debug --namespace kube-system metallb bitnami/metallb

# install ingress nginx
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx --create-namespace --debug

# Sign ip address pools for metallb
echo
echo -----------------------------------
echo "Sign ip address pools for metallb"
echo "kubectl apply -f values.yaml"
