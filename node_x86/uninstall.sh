#!/bin/sh

#卸载docker
uninstall_docker() {
    systemctl stop docker

    rpm -e docker-ce-selinux
    rpm -e docker-ce
}

#卸载kubelet kubeadm kubectl包
uninstall_k8s() {
    systemctl stop kubelet
    kubeadm reset

    yum -y remove kubelet
    yum -y remove kubeadm
    yum -y remove kubectl
}

echo -e "\033[32m{`date`}[开始]正在执行卸载.............................\033[0m"

uninstall_docker
uninstall_k8s

echo -e "\033[32m{`date`}[结束]卸载完成..................................\033[0m"