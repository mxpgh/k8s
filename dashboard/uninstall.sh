#!/bin/sh

basepath=$(cd `dirname $0`; pwd)
echo "current path: ${basepath}"

uninstall_dashboard() {
   kubectl delete -f $basepath/kubernetes-dashboard.yaml
}

echo -e "\033[32m{`date`}[开始]正在执行卸载.............................\033[0m"

uninstall_dashboard

echo -e "\033[32m{`date`}[结束]卸载完成..................................\033[0m"
