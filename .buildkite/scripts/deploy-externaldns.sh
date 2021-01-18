#!/bin/bash
set -e

helm repo add bitnami https://charts.bitnami.com/bitnami
helm install \
  --generate-name \
  --values values.yaml \
  bitnami/external-dns