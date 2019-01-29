#!/bin/sh

if [ -z "$1" ]
then
    echo 'Error: 缺少参数：主机名.'
    exit 1
fi

hs=$1
echo "hostname: ${hs}"

basepath=$(cd `dirname $0`; pwd)
echo "current path: ${basepath}"

#设置主机名
set_hostname() {
    if grep -q ${hs} /etc/hostname ;then
        echo
    else
        echo "${hs}" > /etc/hostname
    fi
    if grep -q ${hs} /etc/hosts ;then
        echo
    else
        echo "127.0.0.1 ${hs}" >> /etc/hosts
    fi
}

#安装docker
install_docker() {
    rpm -ihv $basepath/master/docker-ce-selinux-17.03.2.ce-1.el7.centos.noarch.rpm
    rpm -ivh $basepath/master/docker-ce-17.03.2.ce-1.el7.centos.x86_64.rpm

    #设置镜像源
    curl -sSL https://get.daocloud.io/daotools/set_mirror.sh | sh -s http://a58c8480.m.daocloud.io
    systemctl start docker && systemctl enable docker
}

#生成互信key
gen_sshkey() {
    ssh-keygen
}

#关闭防火墙
set_firewall() {
    systemctl stop firewalld && systemctl disable firewalld
    sed -i "s/^SELINUX=enforcing/SELINUX=disabled/g" /etc/sysconfig/selinux 
    sed -i "s/^SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config 
    sed -i "s/^SELINUX=permissive/SELINUX=disabled/g" /etc/sysconfig/selinux 
    sed -i "s/^SELINUX=permissive/SELINUX=disabled/g" /etc/selinux/config  
    setenforce 0
}

#设置转发
set_bridge() {
    NET_BRIDGE_CONF_FILE="/etc/sysctl.conf"
    if test -f ${NET_BRIDGE_CONF_FILE}
    then
        cp  ${NET_BRIDGE_CONF_FILE} "${NET_BRIDGE_CONF_FILE}.bak"
        if grep -q net.bridge.bridge-nf-call-ip6tables "${NET_BRIDGE_CONF_FILE}.bak";then
            sed -i 's/net.bridge.bridge-nf-call-ip6tables = 0/net.bridge.bridge-nf-call-ip6tables = 1/g' /etc/sysctl.conf
        else
            sed -i '$a net.bridge.bridge-nf-call-ip6tables = 1' /etc/sysctl.conf
        fi
        if grep -q net.bridge.bridge-nf-call-iptables "${NET_BRIDGE_CONF_FILE}.bak";then
                sed -i 's/net.bridge.bridge-nf-call-iptables = 0/net.bridge.bridge-nf-call-iptables = 1/g' /etc/sysctl.conf
        else
            sed -i '$a net.bridge.bridge-nf-call-iptables = 1' /etc/sysctl.conf
        fi
        rm -rf "${NET_BRIDGE_CONF_FILE}.bak"
    fi
    sysctl -p
}

#关闭交换分区
close_swap() {
    swapoff -a
    FSTAB_CONF_FILE="/etc/fstab"
    if test -f ${FSTAB_CONF_FILE}
    then
        cp  ${FSTAB_CONF_FILE} "${FSTAB_CONF_FILE}.bak"
        if grep -Ev '^$|^#' "${FSTAB_CONF_FILE}.bak" | grep -q swap ;then
            echo
        else
            sed -i 's/.*swap.*/#&/' /etc/fstab
        fi
        rm -rf "${FSTAB_CONF_FILE}.bak"
    fi
}

#导入镜像
load_images() {
    docker load < $basepath/master/docker_images/etcd-amd64_v3.1.10.tar
    docker load < $basepath/master/docker_images/flannel_v0.9.1-amd64.tar
    docker load < $basepath/master/docker_images/k8s-dns-dnsmasq-nanny-amd64_v1.14.7.tar
    docker load < $basepath/master/docker_images/k8s-dns-kube-dns-amd64_1.14.7.tar
    docker load < $basepath/master/docker_images/k8s-dns-sidecar-amd64_1.14.7.tar
    docker load < $basepath/master/docker_images/kube-apiserver-amd64_v1.9.0.tar
    docker load < $basepath/master/docker_images/kube-controller-manager-amd64_v1.9.0.tar
    docker load < $basepath/master/docker_images/kube-scheduler-amd64_v1.9.0.tar
    docker load < $basepath/master/docker_images/kube-proxy-amd64_v1.9.0.tar
    docker load < $basepath/master/docker_images/pause-amd64_3.0.tar
    docker load < $basepath/master/docker_images/kubernetes-dashboard_v1.8.1.tar
}

#安装安装kubelet kubeadm kubectl包
install_k8s() {
    rpm -ivh $basepath/master/socat-1.7.3.2-2.el7.x86_64.rpm
    rpm -ivh $basepath/master/kubernetes-cni-0.6.0-0.x86_64.rpm $basepath/master/kubelet-1.9.9-9.x86_64.rpm $basepath/master/kubectl-1.9.0-0.x86_64.rpm
    rpm -ivh $basepath/master/kubeadm-1.9.0-0.x86_64.rpm

    #启动kubelete
    systemctl enable kubelet && sudo systemctl start kubelet
}

#重新设置cgroup driver
set_cgroup_driver() {
    cgroupDriver=$(docker info | grep Cg)
    driver=${cgroupDriver##*: }
    echo "driver is ${driver}"
    
    sed -i "s/KUBELET_CGROUP_ARGS=--cgroup-driver=systemd/KUBELET_CGROUP_ARGS=--cgroup-driver=${driver}/g" /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
}

#初始化
kubeadm_init() {
    systemctl daemon-reload && systemctl restart kubelet
    kubeadm reset
    kubeadm init --kubernetes-version=v1.9.0 --pod-network-cidr=10.244.0.0/16

    mkdir -p $HOME/.kube
    cp -f /etc/kubernetes/admin.conf $HOME/.kube/config
    chown $(id -u):$(id -g) $HOME/.kube/config
    export KUBECONFIG=/etc/kubernetes/admin.conf
    if grep -q KUBECONFIG ~/.bash_profile ;then
        echo
    else
        echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> ~/.bash_profile
    fi

    source ~/.bash_profile
}

#部署网络
deploy_net() {
    kubectl create -f $basepath/master/kube-flannel.yml
}

echo -e "\033[32m{`date`}[开始]正在执行安装.............................\033[0m"

set_hostname
install_docker
set_firewall
set_bridge
close_swap
load_images
install_k8s
set_cgroup_driver
kubeadm_init
deploy_net

echo -e "\033[32m{`date`}[结束]安装完成.................................\033[0m"

