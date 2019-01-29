#!/bin/sh

echo -e "\033[32m{`date`}[开始]初始化环境.............................\033[0m"

basepath=$(cd `dirname $0`; pwd)

cp $basepath/daemon.json /etc/docker/
systemctl restart docker

set_bridge() {
	NET_BRIDGE_CONF_FILE="/etc/sysctl.conf"
    if sudo test -f ${NET_BRIDGE_CONF_FILE}
    then
        sudo cp  ${NET_BRIDGE_CONF_FILE} "${DOCKER_DAEMON_JSON_FILE}.bak"
        if sudo grep -q net.bridge.bridge-nf-call-ip6tables "${NET_BRIDGE_CONF_FILE}.bak";then
            sudo cat "${NET_BRIDGE_CONF_FILE}.bak" | sed -n "s/net.bridge.bridge-nf-call-ip6tables=0/net.bridge.bridge-nf-call-ip6tables=1/g" | sudo tee ${NET_BRIDGE_CONF_FILE}
        else
            sudo cat "${NET_BRIDGE_CONF_FILE}.bak" | sed -n "s/net.bridge.bridge-nf-call-ip6tables=1/net.bridge.bridge-nf-call-ip6tables=1/g" | sudo tee ${NET_BRIDGE_CONF_FILE}
        fi
		
		 if sudo grep -q net.bridge.bridge-nf-call-iptables "${NET_BRIDGE_CONF_FILE}.bak";then
            sudo cat "${NET_BRIDGE_CONF_FILE}.bak" | sed -n "s/net.bridge.bridge-nf-call-iptables=0/net.bridge.bridge-nf-call-iptables=1/g" | sudo tee ${NET_BRIDGE_CONF_FILE}
        else
            sudo cat "${NET_BRIDGE_CONF_FILE}.bak" | sed -n "s/net.bridge.bridge-nf-call-iptables=1/net.bridge.bridge-nf-call-iptables=1/g" | sudo tee ${NET_BRIDGE_CONF_FILE}
        fi
		rm -rf "${DOCKER_DAEMON_JSON_FILE}.bak"
    fi

echo "
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
" >> /etc/sysctl.conf
sysctl -p
}


chmod +x $basepath/kubelet.service
chmod +x $basepath/bin/*
chmod +x $basepath/cni/*

mkdir -p /opt/cni/bin
mkdir -p /etc/kubernetes/pki
mkdir -p /etc/kubernetes/manifests
mkdir -p /etc/systemd/system/kubelet.service.d


cp $basepath/kubelet.service /etc/systemd/system/
cp $basepath/10-kubeadm.conf /etc/systemd/system/kubelet.service.d/
cp $basepath/bin/* /usr/bin
cp $basepath/cni/* /opt/cni/bin


docker load < $basepath/docker_images/pause-arm_3.0.tar
docker load < $basepath/docker_images/flannel_v0.9.1-arm.tar
docker load < $basepath/docker_images/kube-proxy-amd64_v1.9.0.tar

kubeadm join --token ae6e41.801840e491054fb5 192.168.1.130:6443 --discovery-token-unsafe-skip-ca-verification

echo -e "\033[32m{`date`}[结束]初始化环境.............................\n\n\n\n\n\n\033[0m"




