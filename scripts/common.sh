#!/bin/bash
_cluster_domain=$(kubectl get ingresses.config.openshift.io/cluster -o jsonpath='{.spec.domain}')

install_argo(){    
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
}

pre_install(){
    kubectl create namespace argocd || true
    oc adm policy add-scc-to-group privileged system:authenticated
}