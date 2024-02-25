#!/bin/bash

# Set env variable for crictl binary
export CRI_CONFIG_FILE=/var/lib/rancher/rke2/agent/etc/crictl.yaml

# Get the list of exited container IDs
ids=$(crictl ps -a | grep -i exited | awk '{print $1}')
if [ -z "$ids" ]; then
  echo "No exited containers found."
else
  # Iterate over the list and remove containers
  while read -r id; do
    crictl rm "$id"
  done <<< "$ids"
fi