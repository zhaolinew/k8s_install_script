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
