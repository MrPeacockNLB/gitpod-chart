#!/bin/bash

# read global configuration
source config

# remove all files
rm -rf tmp; mkdir tmp
rm -rf manifests/gitpod; mkdir -p manifests/gitpod

# GitPods installer initial config.yaml
CFG=tmp/config.yaml

# write default config file
gitpod-installer config init -c $CFG --overwrite