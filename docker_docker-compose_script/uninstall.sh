#!/bin/bash


check_os(){
  # 读取/etc/os-release文件中的NAME和VERSION信息
  OS_NAME=$(source /etc/os-release && echo $NAME)
  #OS_VERSION=$(source /etc/os-release && echo $VERSION)
  if [[ "$OS_NAME" == *"CentOS"* ]]; then
    echo "CentOS"
  elif [[ "$OS_NAME" == *"Ubuntu"* ]]; then
    echo "Ubuntu"
  elif [[ "$OS_NAME" == *"Debian"* ]]; then
    echo "Debian"
  elif [[ "$OS_NAME" == *"Anolis OS"* ]];then
    echo "Anolis OS"
  else
    echo "Unsupported OS [x]"
    # 进入检测分支
    check_os_next
  fi
}

check_os_next(){
    if [ "$(uname -m)" = "x86_64" ]; then
        # 架构正确控制台输入是否继续安装
        read -rep "The schema x86_64 correct whether to proceed with  (y/n)" inpt
        if [ "$inpt" != 'y' ] && [ "$inpt" != 'Y' ]; then
            exit 1
        fi
    else
        echo "x86_64 [x]"
        exit 1
    fi
}

# 检测集合
detect_collect(){
  # 1、检测目录权限
  check_permissions
  # 2、检测适配的操作系统
  check_os
  # 3、检测命令
  check_command
  # 4、 检测适配的架构
  check_os_arch
}

check_permissions(){
  if [ ! -w "/usr/bin/" ]; then
    echo "/usr/bin/ [×] There are no permissions."
    exit 1
fi
}

check_command(){
  if ! command -v find &>/dev/null; then
     echo "find [x]"
     exit 1
  fi
  if ! command -v ps &> /dev/null; then
     echo "ps [x]"
     exit 1
  fi
  if ! command -v rm &> /dev/null; then
      echo "rm [×]"
      exit 1
  fi
  if ! command -v which &> /dev/null; then
     echo "which [x]"
     exit 1
  fi
}

check_os_arch(){
  if [ "$(uname -m)" != "x86_64" ]; then
    echo "Hi, bro this script has only been used on x86_64 [x]"
    exit 1
  fi
}

get_package_master(){
    if command -v apt-get &> /dev/null; then
      controls="apt"
    elif command -v yum &> /dev/null; then
      controls="yum"
    elif command -v dnf &> /dev/null; then
      controls="dnf"
    elif command -v zypper &> /dev/null; then
      controls="zypper"
    else
      echo "无法识别包管理器"
      exit 1
    fi
}

stop_docker_service(){
    if [ -f /etc/systemd/system/docker.service ];then
       systemctl stop docker.service &>/dev/null
       systemctl disable docker.service &>/dev/null
       rm -rf /usr/lib/systemd/system/docker.service
       systemctl daemon-reload
    fi
    local dockerd_pid=$(ps aux | grep dockerd | grep -v grep | awk '{print $2}')
    if [ -n "$dockerd_pid" ]; then
       kill -9 $dockerd_pid
       if [ $? -eq 0 ];then
          echo "stop dockerd pid $dockerd_pid [ok]"
       else
          echo "stop dockerd pid $dockerd_pid [x]"
          exit 1
       fi
    else
       echo "dockerd pid not found [ok]"
    fi
}

package_master_remove_docker(){
   "$controls" -y remove docker* containerd.io &>/dev/null
   echo "$controls remove docker* containerd.io [ok]"
}

rmi_docker_images(){
    local docker_images=$(docker images | awk '{print $1}')
    for image in $docker_images; do
        docker rmi -f $image &>/dev/null
    done
    echo "docker images remove [ok]"
}

remove_docker_container(){
    if command -v docker &>/dev/null; then
        local docker_containers=$(docker ps -a | awk '{print $1}')
        for container in $docker_containers; do
           docker stop $container &>/dev/null
           docker rm $container &>/dev/null
        done
        echo "docker containers remove [ok]"
        rmi_docker_images
    fi
}

remove_docker_compose(){
  # 防止docker-compose存在其他目录导致未删除
  if command -v docker-compose &>/dev/null; then
     if [ -f $(which docker-compose) ];then
        rm -rf $(which docker-compose)
     fi
     echo "remove docker-compose [ok]"
  fi
}

remove_docker_file(){
    if [ -d /var/lib/docker ]; then
        rm -rf /var/lib/docker &>/dev/null
    fi
    if [ -f /var/docker.sock ]; then
        rm -rf /var/docker.sock &>/dev/null
    fi
    if [ -f /usr/bin/dockerd ]; then
        rm -rf /usr/bin/docker* &>/dev/null
    fi
    echo "docker file remove [ok]"
    remove_docker_compose
}

  # 检测集合
  detect_collect
  # 获取包管理器
  get_package_master
  # 包管理器尝试卸载docker
  package_master_remove_docker
  # 删除docker容器和镜像
  remove_docker_container
  # 停止docker服务
  stop_docker_service
  # 删除docker文件
  remove_docker_file