#!/bin/bash

# read global configuration
source config

# remove all files
rm -rf tmp; mkdir -p tmp/gitpod
rm -rf manifests/gitpod; mkdir -p manifests/gitpod

# GitPods installer initial config.yaml
CFG=tmp/config.yaml

# write default config file
gitpod-installer config init -c $CFG --overwrite

#
# apply fixes
#
yq e -i '.domain = "'"${DOMAIN}"'"' $CFG
yq e -i '.certificate.name = "https-certificates"' $CFG

yq e -i '.observability.logLevel = "trace"' $CFG
yq e -i '.workspace.runtime.containerdSocket = "/run/k3s/containerd/containerd.sock"' $CFG
yq e -i '.workspace.runtime.containerdRuntimeDir = "/var/lib/rancher/k3s/agent/containerd/io.containerd.runtime.v2.task/k8s.io/"' $CFG
yq e -i '.workspace.pvc.size = "10Gi"' $CFG
yq e -i '.workspace.resources.requests.memory = "500Mi"' $CFG
yq e -i '.workspace.resources.requests.cpu = "500m"' $CFG
yq e -i '.workspace.timeoutDefault = "720m"' $CFG

#
# Enable SSH Gateway
# ------------------
#
# Generate new key without passphrase (-N "")
#
rm -rf host.key
ssh-keygen -t rsa -q -N "" -f tmp/host.key

# create secret yaml
kubectl create secret generic ssh-gateway-host-key -n $NAMESPACE --from-file=tmp/host.key --dry-run=client --output=yaml > manifests/ssh-gateway-host-key.yaml

# append configuration settings for SSH gateway
yq e -i '.sshGatewayHostKey.kind = "secret" | .sshGatewayHostKey.name = "ssh-gateway-host-key"' $CFG

# render manifests and create copy for diffing
gitpod-installer render --use-experimental-config --config $CFG --output-split-files tmp/gitpod -n $NAMESPACE
for f in tmp/gitpod/*.yaml; do yq -i '.' "$f"; done
cp -r tmp/gitpod tmp/org

#
# remove all node selectors
#
for f in tmp/gitpod/*.yaml; do yq -i '(del .spec.template.spec.affinity)' "$f"; done

# dump diff

# finaly copy files
cp -r tmp/gitpod manifests