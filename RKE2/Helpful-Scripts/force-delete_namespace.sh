#!/bin/bash
export NAMESPACE="namespace"
kubectl get namespace $NAMESPACE -o json   | tr -d "\n" | sed "s/\"finalizers\": \[[^]]\+\]/\"finalizers\": []/"   | kubectl replace --raw /api/v1/namespaces/$NAMESPACE/finalize -f -