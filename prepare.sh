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

# replace selector only if exists in YAML files
#LABEL="kubernetes.io/hostname"
#VALUE="aks-central-90269204-vmss00001z"
#for f in tmp/gitpod/*.yaml; do  yq -i '(select(.spec.template.spec.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution) | .spec.template.spec.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution) |= (del(.nodeSelectorTerms[]), .nodeSelectorTerms[0].matchExpressions[0].key = "'$LABEL'", .nodeSelectorTerms[0].matchExpressions[0].values[0] = "'$VALUE'", .nodeSelectorTerms[0].matchExpressions[0].operator = "In") ' "$f"; done

# delete 
for f in tmp/gitpod/*.yaml; do  yq -i 'del(.spec.template.spec.affinity.nodeAffinity)' "$f"; done

# dump diff
diff -u tmp/org tmp/gitpod

# finaly copy files
cp -r tmp/gitpod manifests