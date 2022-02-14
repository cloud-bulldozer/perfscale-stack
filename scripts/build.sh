#!/bin/bash
set -a
_user=$(oc whoami)
usage() { echo "Usage: $0 [-c <string> (cluster template to apply -- sailplane or observability)] -w (wait for Apps to turn healthy) ]" 1>&2; exit 1; }
GIT_ROOT=$(git rev-parse --show-toplevel)
source $GIT_ROOT/scripts/common.sh

while getopts c:w flag
do
    case "${flag}" in
        c) cluster=${OPTARG};;
        w | *) wait=true;; 
        *) usage;;
    esac
done

if [[ -z "$cluster" ]]; then 
    usage
fi


pre_install
install_argo

printf "\n\nConfiguring cluster to match the $cluster cluster configuration\n"
apply_cluster

if [[ ! -z "$wait" ]]; then
    printf "\n\nWaiting Enabled, this requires Argo CLI. Installing now...\n"
    install_argo_cli
    printf "\nWaiting for Apps to Sync...\n"
    wait_for_sync
    printf "\nAll Argo Applications are Synced. This means the manifests were applied successfully. Waiting for the Apps to be healthy\n"
    printf "\nWaiting for Apps to be healthy\n"
    wait_for_health
    printf "\nAll Apps are Healthy...\n"
    output_cluster_info
else
    printf "\nWaiting disabled. Script will not wait for Apps to become Healthy.\n"
    printf "\nArgoCD is working in the background to install and maintain your Apps. Check the ArgoCD UI for more info\n"
    output_argo_info
    printf "\n\nSkipping Cluster Output since we didnt wait for apps\n"
fi

