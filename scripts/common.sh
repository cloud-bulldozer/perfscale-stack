#!/bin/bash
_cluster_domain=$(kubectl get ingresses.config.openshift.io/cluster -o jsonpath='{.spec.domain}')

install_argo(){    
    helm repo add argo https://argoproj.github.io/argo-helm 
    helm upgrade --install argocd argo/argo-cd --namespace argocd
}

pre_install(){
    kubectl create namespace argocd || true
    oc adm policy add-scc-to-group privileged system:authenticated
}