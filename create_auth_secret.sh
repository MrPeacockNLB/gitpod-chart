#!/bin/bash

# read global configuration
source config

#
# Configure public GitHub authentication provider
# -----------------------------------------------
#

# append configuration settings for provider secret
#
# authProviders:
#   - kind: secret
#     name: public-github
#
yq e -i '.authProviders[0].kind = "secret" | .authProviders[0].name = "public-github"' $CFG

#
#id: Public-GitHub
#host: github.com
#type: GitHub
#oauth:
#  clientId: xxx
#  clientSecret: xxx
#  callBackUrl: https://$DOMAIN/auth/github.com/callback
#  settingsUrl: xxx
CLIENT_ID="12343bd32ad04b0022a5a21c56789"
CLIENT_SECRET="3c6dec1115838a64fb590022ce821336d0d865b8"
CALLBACKURL="https://$DOMAIN/auth/github.com/callback"
yq -n '.id = "public-github" | .host = "github.com" | .type = "GitHub"' > tmp/public-github.yaml
yq e -i '.oauth.clientId = "'$CLIENT_ID'"' tmp/public-github.yaml
yq e -i '.oauth.clientSecret = "'$CLIENT_SECRET'"' tmp/public-github.yaml
yq e -i '.oauth.callBackUrl = "'$CALLBACKURL'"' tmp/public-github.yaml
yq e -i '.oauth.settingsUrl = "'$SETTINGSURL'"' tmp/public-github.yaml
kubectl create secret generic public-github -n $NAMESPACE --from-file=tmp/public-github.yaml --dry-run=client --output=yaml > manifests/public-github.yaml