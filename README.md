# k8s_install_script
k8s二进制安装部署脚本
### 一键安装k8s脚本，支持环境：
- centos 7
- centos 8
- ubuntu 18.x
### 使用帮助 
```
Usage kubesetup.sh -f <Config_File> -c <containerd|docker|init|clean> [-a]
使用说明
-f fileanme   必选项，安装群集时使用指定的文件定义好的参数去初始化群集主机
-c            必选项，表示cluster选项，后面跟的参数为
   containerd 使用 containerd 作为远行时
   docker     使用 docker 作为运行时
   init       只会对配置文件中的主机进行初始化操作，不安装群集
   clean      按照配置文件清理群集，此参数无法与 -a 配合使用
-a            可选项，在已经安装的群集上添加新的主机
-h            帮助
```
### 配置文件示例
```
# 存放生成的文件目录
export WORK_DIR="/root/work/"

# 生成 EncryptionConfig 所需的加密 key
export ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)

# 集群各NODE IP 和对应的主机名数组，用空格分隔
export NODE_IPS=(172.19.0.10 172.19.0.11 172.19.1.12 172.19.1.13 172.19.2.11 172.19.2.12)
export NODE_NAMES=(node1 node2 node3 node4 node5 node6)

# 新增节点时的IP和对应的主机名数组,当使用 -a 选项时读取下面的值，用空格分隔
export NEW_NODE_IPS=()
export NEW_NODE_NAMES=()

# 集群各MASTER IP 和对应的主机名数组，用空格分隔
export MASTER_IPS=(172.19.1.10 172.19.1.11 172.19.2.10)
export MASTER_NAMES=(master1 master2 master3)

# 集群各ETCD IP 和对应的主机名数组，用空格分隔
export ETCD_IPS=(172.19.1.10 172.19.1.11 172.19.2.10)
export ETCD_NAMES=(etcd1 etcd2 etcd3)

# etcd 集群服务地址列表，使用逗号分隔，如"https://172.18.10.50:2379,https://172.18.10.51:2379,https://172.18.10.52:2379"
export ETCD_ENDPOINTS="https://172.19.1.10:2379,https://172.19.1.11:2379,https://172.19.2.10:2379"

# etcd 集群间通信的 IP 和端口, 逗号分隔，如"etcd1=https://172.18.10.50:2380,etcd2=https://172.18.10.51:2380,etcd3=https://172.18.10.52:2380"
export ETCD_NODES="etcd1=https://172.19.1.10:2380,etcd2=https://172.19.1.11:2380,etcd3=https://172.19.2.10:2380"

# kube-apiserver 的反向代理 nginx 172.100.100.100地址端口, 此处建议先使用域名的方式,
export KUBE_APISERVER_IP="172.19.1.10"
export KUBE_APISERVER_DNS_NAME="kube-api.zhuanche.com"
export KUBE_APISERVER="https://${KUBE_APISERVER_DNS_NAME}:6443"

# 节点间互联网络接口名称
export IFACE="eth0"

# etcd 数据目录
export ETCD_DATA_DIR="/data/etcd"

# etcd WAL 目录，建议是 SSD 磁盘分区，或者和 ETCD_DATA_DIR 不同的磁盘分区
export ETCD_WAL_DIR="/data/etcd/wal"

# k8s 各组件数据目录
export K8S_DIR="/data/k8s"
# docker 数据目录
export DOCKER_DIR="/data/k8s/docker"
# containerd 数据目录
export CONTAINERD_DIR="/data/k8s/containerd"

## 以下参数一般不需要修改
# TLS Bootstrapping 使用的 Token，可以使用命令 head -c 16 /dev/urandom | od -An -t x | tr -d ' ' 生成
#export BOOTSTRAP_TOKEN="d65dbd7c45678e755a961233cd23a949"

# 最好使用 当前未用的网段 来定义服务网段和 Pod 网段
# 服务网段，部署前路由不可达，部署后集群内路由可达(kube-proxy 保证)
export SERVICE_CIDR="172.31.0.0/16"

# Pod 网段，建议 /16 段地址，部署前路由不可达，部署后集群内路由可达(flanneld 保证), kube-proxy用此建立iptables
export CLUSTER_CIDR="172.19.0.0/16"

# 服务端口范围 (NodePort Range)
export NODE_PORT_RANGE="30000-32767"

# flanneld 网络配置前缀
export FLANNEL_ETCD_PREFIX="/kubernetes/network"

# kubernetes 服务 IP (一般是 SERVICE_CIDR 中第一个IP)
export CLUSTER_KUBERNETES_SVC_IP="172.31.0.1"

# 集群 DNS 服务 IP (从 SERVICE_CIDR 中预分配)
export CLUSTER_DNS_SVC_IP="172.31.0.2"

# 集群 DNS 域名（末尾不带点号）
export CLUSTER_DNS_DOMAIN="cluster.local"

# 将二进制目录 /opt/k8s/bin 加到 PATH 中
export PATH=/opt/k8s/bin:$PATH

# 证书配置信息
export CSR_C="CN"
export CSR_ST="BeiJing"
export CSR_L="BeiJing"
export CSR_O="k8s"
export CSR_OU="zhuanche"

###################################
#软件安装版本及下载地址
###################################
# https://github.com/cloudflare/cfssl/
export GET_CFSSL="http://192.168.205.77/K8s/cfssl/cfssl_1.4.1_linux_amd64"
export GET_CFSSLJSON="http://192.168.205.77/K8s/cfssl/cfssljson_1.4.1_linux_amd64"
export GET_CFSSL_CERTINFO="http://192.168.205.77/K8s/cfssl/cfssl-certinfo_1.4.1_linux_amd64"

# https://github.com/kubernetes/kubernetes/
export KUBERNETES_SERVER="kubernetes1.22.1-server-linux-amd64.tar.gz"
export GET_KUBERNETES_SERVER="http://192.168.205.77/K8s/${KUBERNETES_SERVER}"

# https://github.com/etcd-io/etcd
export ETCD_PKGS="etcd-v3.4.9-linux-amd64.tar.gz"
export GET_ETCD_PKGS="http://192.168.205.77/K8s/${ETCD_PKGS}"

# https://github.com/kubernetes-sigs/cri-tools
export CRICTL="crictl-v1.22.0-linux-amd64.tar.gz"
export GET_CRICTL="http://192.168.205.77/K8s/${CRICTL}"

# https://github.com/opencontainers/runc
export RUNC="runc.amd64-1.0.2"
export GET_RUNC="http://192.168.205.77/K8s/runc/${RUNC}"

# https://github.com/containernetworking/plugins
export CNI_PLUGINS="cni-plugins-linux-amd64-v1.0.0.tgz"
export GET_CNI_PLUGINS="http://192.168.205.77/K8s/${CNI_PLUGINS}"

# https://github.com/containerd/containerd
export CONTAINERD="containerd-1.5.5-linux-amd64.tar.gz"
export GET_CONTAINERD="http://192.168.205.77/K8s/containerd/${CONTAINERD}"

# https://download.docker.com/linux/static/stable/x86_64/
export DOCKER="docker-18.09.6.tgz"
export GET_DOCKER="http://192.168.205.77/K8s/${DOCKER}"

# https://github.com/projectcalico/calicoctl
export CALICOCTL="calicoctl-3.15.1"
export GET_CALICOCTL="http://192.168.205.77/K8s/calico/${CALICOCTL}"

# https://github.com/coredns/coredns
export COREDNS="coredns_1.7.0_linux_amd64.tgz"
export GET_COREDNS="http://192.168.205.77/K8s/${COREDNS}"
```
