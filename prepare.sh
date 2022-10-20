#!/bin/bash

# read global configuration
source config

# remove all files
rm -rf tmp; mkdir tmp

# write default config file
gitpod-installer config init -c tmp/config.yaml --overwrite