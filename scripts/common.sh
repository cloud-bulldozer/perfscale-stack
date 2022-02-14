#!/bin/bash
_cluster_domain=$(kubectl get ingresses.config.openshift.io/cluster -o jsonpath='{.spec.domain}')

install_argo(){    
    if [[ ! $(kubectl get ns argocd --ignore-not-found) ]]; then
        helm repo add argo https://argoproj.github.io/argo-helm 
        helm upgrade --install argocd argo/argo-cd --namespace argocd
    else
        printf "\nArgoCD namespace found, skipping install"
    fi
}

pre_install(){
    if [[ ! $(kubectl get ns argocd --ignore-not-found) ]]; then
        kubectl create namespace argocd || true
        oc adm policy add-scc-to-group privileged system:authenticated
    fi
}

apply_cluster(){
    envsubst < $GIT_ROOT/clusters/$cluster.yaml | kubectl apply -f -
}

install_argo_cli(){
    VERSION=$(curl --silent "https://api.github.com/repos/argoproj/argo-cd/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
    curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/download/$VERSION/argocd-linux-amd64
    chmod +x /usr/local/bin/argocd

    _argo_url=$(oc get route/argocd-server -o jsonpath='{.spec.host}' -n argocd)
    _argo_user="admin"
    _argo_password=$(kubectl get secret/argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 --decode)
    argocd login $_argo_url --insecure --username $_argo_user --password $_argo_password
}

wait_for_sync(){
    # all clusters deploy the perfscale app
    argocd app wait -l argocd.argoproj.io/instance=perfscale --sync

    if [[ "$cluster" == "observability" ]]; then 
        argocd app wait -l argocd.argoproj.io/instance=observability --health
    fi
  
}

wait_for_health(){
    # all clusters deploy the perfscale app
    argocd app wait -l argocd.argoproj.io/instance=perfscale --health

    if [[ "$cluster" == "observability" ]]; then
        printf "\n Waiting for observability" 
        argocd app wait -l argocd.argoproj.io/instance=observability --health
    fi
   
}

output_argo_info () {

    _argo_url=$(oc get route/argocd-server -o jsonpath='{.spec.host}' -n argocd)
    _argo_user="admin"
    _argo_password=$(kubectl get secret/argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 --decode)

    printf "\n\n ArgoCD Configs"
    printf "\n Host: $_argo_url \n User: $_argo_user \n Password: $_argo_password"
}


output_cluster_info() {
    printf "\n Outputting Info about Apps this repo maintains"
    printf "\n Note: This will attempt to get info from all possible apps, even if the cluster doesnt have it. In those cases there will be blank data"

    output_argo_info

    if [[ $(kubectl get ns airflow --ignore-not-found) ]]; 
    then
        _airflow_url=$(oc get route/airflow -o jsonpath='{.spec.host}' -n airflow)
        _airflow_user="admin"
        _airflow_password="REDACTED"

        printf "\n\n Airflow Configs (Password was user defined so this script doesn't know it!)"
        printf "\n Host: $_airflow_url \n User: $_airflow_user \n Password: $_airflow_password \n"
    else
        printf "\n\n Airflow not found in this cluster"
    fi

    if [[ $(kubectl get ns grafana --ignore-not-found) ]]; 
    then
        _grafana_url=$(oc get route/grafana -o jsonpath='{.spec.host}' -n grafana)
        printf "\n\n Grafana Configs"
        printf "\n Host: $_grafana_url"
    else
        printf "\n\n Grafana not found in this cluster \n"
    fi

    if [[ $(kubectl get ns perf-results --ignore-not-found) ]]; 
    then
        _elastic_url=$(oc get route/perf-results-elastic -o jsonpath='{.spec.host}' -n perf-results)
        _kibana_url=$(oc get route/perf-results-kibana -o jsonpath='{.spec.host}' -n perf-results)
        _es_user="elastic"
        _es_password=$(kubectl get secret/perf-results-es-elastic-user -n perf-results -o jsonpath='{.data.elastic}' | base64 --decode)

        printf "\n\n ElasticSearch and Kibana Configs "
        printf "\n ES Host: $_elastic_url \n Kibana Host: $_kibana_url \n User: $_es_user \n Password: $_es_password \n"
    else
        printf "\n Elasticsearch and Kibana not found in this cluster \n"
    fi

    if [[ $(kubectl get ns thanos --ignore-not-found) ]]; 
    then
        _thanos_receiver=$(oc get route/thanos -o jsonpath='{.spec.host}' -n thanos)
        _thanos_query=$(oc get route/thanos-query -o jsonpath='{.spec.host}' -n thanos)
        _thanos_ruler=$(oc get route/thanos-ruler -o jsonpath='{.spec.host}' -n thanos)
        _thanos_query_ui=$(oc get route/thanos-query-frontend -o jsonpath='{.spec.host}' -n thanos)
        _thanos_bucketweb=$(oc get route/thanos-bucketweb -o jsonpath='{.spec.host}' -n thanos)

        printf "\n\n Thanos Configs "
        printf "\n Receiver Host (hosts receive endpoint at /api/v1/receive): $_thanos_receiver \n Query API Host: $_thanos_query \n Ruler Host: $_thanos_ruler \n Bucket Explorer UI (Shows TSDB Block Data): $_thanos_bucketweb \n Query UI (Frontend for Query): $_thanos_query_ui"
    else
        printf "\n Thanos not found in this cluster \n"
    fi

    if [[ $(kubectl get ns loki --ignore-not-found) ]]; 
    then
        _loki=$(oc get route/loki -o jsonpath='{.spec.host}' -n loki)

        printf "\n\n Loki Configs "
        printf "\n Host (hosts push endpoint at /api/v1/push): $_loki"
    else
        printf "\n Loki not found in this cluster \n"
    fi

    if [[ $(kubectl get ns vault --ignore-not-found) ]]; 
    then
        _vault=$(oc get route/vault -o jsonpath='{.spec.host}' -n vault)

        printf "\n\n Vault Configs "
        printf "\n Host: $_vault"
        printf "\n Check Shared Infra docs for login access"
    else
        printf "\n Vault not found in this cluster \n"
    fi
}
