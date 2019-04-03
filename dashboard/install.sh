#!/bin/sh

basepath=$(cd `dirname $0`; pwd)
echo "current path: ${basepath}"

#导入镜像
load_images() {
   docker load < $basepath/kubernetes-dashboard_v1.8.1.tar
}

#部署dashboard
deploy() {
    nodename=$(kubectl get nodes | grep master | awk '{print $1}')
    kubectl label node $nodename role=master
    kubectl create -f $basepath/kubernetes-dashboard.yaml
    kubectl create clusterrolebinding cluster-system-anonymous --clusterrole=cluster-admin --user=system:anonymous
}

echo -e "\033[32m{`date`}[开始]正在执行安装.............................\033[0m"

load_images
deploy

echo -e "\033[32m{`date`}[结束]安装完成.................................\033[0m"

