#!/bin/bash

#color functions
function gecho() {
    echo -e "\e[1;2;32m $1 \e[0m"
    sleep 0.5
}

function recho() {
    echo -e "\e[1;2;31m $1 \e[0m"
    sleep 0.5
}

function becho() {
    echo -e "\e[1;4;34m $1 \e[0m"
    sleep 0.5
}

function get_help(){
    echo "Usage $0 -f <Config_File> -c <containerd|docker|init|clean> [-a]" 
    echo 
    echo "使用说明"
    echo "-f fileanme   必选项，安装群集时使用指定的文件定义好的参数去初始化群集主机"
    echo "-c            必选项，表示cluster选项，后面跟的参数为"
    echo "   containerd 使用 containerd 作为远行时"
    echo "   docker     使用 docker 作为运行时"
    echo "   init       只会对配置文件中的主机进行初始化操作，不安装群集"
    echo "   clean      按照配置文件清理群集，此参数无法与 -a 配合使用"
    echo "-a            可选项，在已经安装的群集上添加新的主机"
    echo "-h            帮助"
    exit 1
}

function ready(){
    read -p "WARNING! 在运行这个脚本前请确认已经对配置文件完成初始化操作:[YES](任意键退出)" confirm
    if [ ! "${confirm}" == YES ]; then
        exit 1
    fi

    WORK_DIR=$(echo ${WORK_DIR} | sed -r 's#^(.+)/$#\1#')
    LOG=$(date +%F_%H-%M-%S)
    LOG_PATH="${WORK_DIR}/install_${LOG}.log"
    if [[ "${WORK_DIR}" =~ ^/.+$ ]]; then
        if [ ! -d ${WORK_DIR} ]; then
            echo -n "created workdir ${WORK_DIR}..."
            if mkdir ${WORK_DIR} -p; then
                gecho " successful"
            else
                recho " filed"
                exit -1
            fi
        else
            read -p "workdir ${WORK_DIR} is existing... continue?(YES or any key for exit)" yesno
            [ "$yesno" = YES ] || exit 1
        fi
    else
        echo "workdir: ${WORK_DIR}, directory must start with / ..."
        exit 1
    fi
}

while getopts "f:c:ah" opts; do
    case $opts in
        f)
            config_file=$OPTARG
            ;;
        c)
            cluster_flag=$OPTARG
            ;;
        a)
            add_flag="true"
            ;;
        ?)
            #unknown args?
            get_help
            ;;
    esac
done

if [ $# == 0 ]; then
    get_help
    exit -1
fi

if [ -f "${config_file}" -a -f ./functions ]; then
    source $config_file
    source ./functions
    IPS=(${MASTER_IPS[@]} ${NODE_IPS[@]} ${ETCD_IPS[@]})
    NAMES=(${MASTER_NAMES[@]} ${NODE_NAMES[@]} ${ETCD_NAMES[@]})
    WORK_DIR=$(echo ${WORK_DIR} | sed -r 's#^(.*)/$#\1#')
else
    echo "config file $config_file or functions file doesn't exist..."
    get_help
    exit -1
fi

if [ "$add_flag" = "true" ]; then
    MASTER_IPS=()
    MASTER_NAMES=()
    NODE_IPS=(${NEW_NODE_IPS[*]})
    NODE_NAMES=(${NEW_NODE_NAMES[*]})
    IPS=(${NEW_NODE_IPS[@]})
    NAMES=(${NEW_NODE_NAMES[@]})
    case $cluster_flag in
        containerd)
            echo "adding additional work nodes by configfile, runtime is Containerd..."
            ready
            init_pre_check
            init_ssh_key
            init_set_hosts
            init_set_env
            add_ca
            add_containerd
            add_kubelet
            add_kube-proxy
            ;;
        docker) 
            echo "adding additional work nodes by configfile, runtime is docker..."
            ready
            add_ca
            add_docker
            add_kubelet
            add_kube-proxy
            ;;
        init)
            echo "only for initialize the added work nodes by configfile"
            ready
            init_pre_check
            init_ssh_key
            init_set_hosts
            init_set_env
            ;;
        clean)
            echo "invalid option -c clean with -a, if using -c clean must without -a"
            get_help
            exit -1
            ;;
        *)
            echo "invalid cluster -c option..."
            get_help
            exit -1
            ;;
    esac
else
    case $cluster_flag in
        containerd)
            echo "install kubernets runtime as Containerd..."
            # init....
                ready
                init_pre_check
                init_install_expect
                init_ssh_key
                init_set_hosts
                init_set_env
            # common install..
                cfssl_get
                ca_setup
                kubectl_setup
            # etcd install ...
                etcd_get
                etcd_cert
                etcd_systemd
            # kubeapi install....
                kubernetes_get
                kubeapi_cert
                #kubeapi_encry
                #kubeapi_audit
                kubeapi_proxy_cert
                kubeapi_systemd
            # controller install....
                controller_cert
                controller_kubeconfig
                controller_systemd
            # scheduler install...
                scheduler_cert
                scheduler_kubeconfig
                #scheduler_config
                scheduler_systemd
            # containerd
                containerd_get
                containerd_config
                containerd_systemd
                containerd_crctl
            # kubelet install...
                kubelet_get
                kubelet_kubeconfig
                kubelet_config
                kubelet_csr
                kubelet_systemd_for_containerd
            # kube-proxy
                kube-proxy_cert
                kube-proxy_kubeconfig
                kube-proxy_config
                kube-proxy_systemd
            ;;
        docker)
            echo "install kubernets runtime as docker..."
            # init....
                ready
                init_pre_check
                init_install_expect
                init_ssh_key
                init_set_hosts
                init_set_env
            # common install..
                cfssl_get
                ca_setup
                kubectl_setup
            # etcd install...
                etcd_get
                etcd_cert
                etcd_systemd
            # kubeapi install...
                kubernetes_get
                kubeapi_cert
                # kubeapi_encry
                # kubeapi_audit
                kubeapi_proxy_cert
                kubeapi_systemd
            # controller install...
                controller_cert
                controller_kubeconfig
                controller_systemd
            # scheduler install...
                scheduler_cert
                scheduler_kubeconfig
                #scheduler_config
                scheduler_systemd
            # docker install...
                docker_get
                docker_systemd
            # kubelet install...
                kubelet_get
                kubelet_kubeconfig
                kubelet_config
                kubelet_csr
                kubelet_systemd_for_docker
            # kube-proxy install...
                kube-proxy_cert
                kube-proxy_kubeconfig
                kube-proxy_config
                kube-proxy_systemd
            ;;
        init)
            echo "only for initialize cluster..."
            ready
            init_pre_check
            init_install_expect
            init_ssh_key
            init_set_hosts
            init_set_env
            ;;
        clean)
            echo "clean all the cluster by configfile..."
            ready
            clean_cluster
            ;;
        *)
            echo "invalid cluster -c options..."
            get_help
            exit -1
            ;;
    esac
fi
