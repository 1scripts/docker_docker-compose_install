# docker_docker-compose_install

### 介绍

可代替docker官网的一键安装脚本，使用docker包进行离线安装
> 注意当前只适配了x86_64的centos、ubuntu、debian,Anolis OS版本，其他系统版本但是属于x86_64架构的请自行斟酌是否运行,其他架构的操作系统请修改脚本或提交Issues.

#### 文件列表

```text
root@ubuntu:/home/ubuntu# tree docker_docker-compose_script/
docker_docker-compose_script/
├── config
│   ├── daemon.json
│   └── docker.service
├── install.sh
├── package
│   ├── docker-20.10.9.tgz
│   └── docker-compose
└── uninstall.sh

2 directories, 6 files
root@ubuntu:/home/ubuntu#
```

### 使用方法

#### 一键安装

```shell
bash <(curl -sL https://raw.githubusercontent.com/1scripts/docker_docker-compose_install/main/quick_install.sh)
```

> 中国境内从github地址下载时好时慢，增加选择或手动输入地址功能，根据需要进行选择
#### 下载加速地址
| CDN值| 加速地址|
|:----:|:-----------------:|
|  1   | https://gitee.com |
|  2   | https://github.com |
|  3   | https://git.homegu.com | 
| 自定义|

示例:
```shell
export CDN=1 && bash <(curl -sL https://raw.githubusercontent.com/1scripts/docker_docker-compose_install/main/quick_install.sh)
```

> 时不时也会出现raw.githubusercontent.com地址决绝访问的情况，这里也需要使用镜像站

示例:
```shell
export CDN=1 && url_address=raw.yzuu.cf & bash <(curl -sL https://${url_address}/1scripts/docker_docker-compose_install/main/quick_install.sh)
```


#### 下载离线安装包

> 链接请查看最新发行版本,此处只做示例

```shell
wget https://gitee.com/li_blog/docker_docker-compose_install/releases/download/docker_docker_compose_v1.2/docker_docker-compose_script.zip
```

#### 解压安装包

```shell
unzip docker_docker-compose_script.zip
```

#### 执行install程序

```shell
cd docker_docker-compose_script/ && bash install.sh
```

### 使用其他源码包

> 注意: 放入的docker安装包和docker-compose文件必须保留官方安装包的名称特征,否则脚本无法识别到

#### 使用其他docker源码包

1. 下载安装包后直接将安装包放到package路径下

#### 使用其他docker-compose文件

1. 下载docker-compose文件后直接将docker-compose文件放到package路径下