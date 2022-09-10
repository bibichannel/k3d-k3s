#!/bin/sh

set -e
sudo apt-get update 

# install nesscessary tools 
if which jq 2> /dev/null; then 
        echo "==> jq is already installed"
else sudo apt install jq -y; fi

# install k3d
if which k3d 2> /dev/null; then 
        echo "==> k3d is already installed"
else wget -q -O - https://raw.githubusercontent.com/rancher/k3d/main/install.sh | bash; fi

# install kubectl
if which kubectl 2> /dev/null; then 
        echo "==> kubectl is already installed"
else 
	curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
	chmod +x kubectl
	sudo  mv kubectl /usr/local/bin
fi

# Install package manager of kubernetes: helm 3
if which helm 2> /dev/null; then 
        echo "==> helm is already installed"
else 
	curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
	chmod 700 get_helm.sh
	./get_helm.sh
	rm get_helm.sh
fi

echo "Finish!"
