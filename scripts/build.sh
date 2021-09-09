#!/bin/bash
set -a
_user=$(oc whoami)
usage() { echo "Usage: $0 [-p <string> (airflow password)]" 1>&2; exit 1; }
GIT_ROOT=$(git rev-parse --show-toplevel)
source $GIT_ROOT/scripts/common.sh


pre_install
install_argo



envsubst < $GIT_ROOT/apps/perfscale.yaml | kubectl apply -f -
envsubst < $GIT_ROOT/apps/observability.yaml | kubectl apply -f -

_argo_url=$(oc get route/argocd -o jsonpath='{.spec.host}' -n argocd)
_argo_user="admin"
_argo_password=$(kubectl get secret/argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 --decode)

echo $_argo_password