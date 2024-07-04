#!/bin/bash

check_docker_status(){
  if which docker &>/dev/null; then
    printf "[检测到已安装略过] $(which docker) version:"
    local docker_version=$(docker --version | awk '{print $3}' | awk -F ',' '{print $1}')
    if [ -n "$docker_version" ]; then
       echo "[$docker_version]"
    else
       echo "[null]"
    fi
    return 0
  else
    #未检测到docker命令开始进行docker检测并安装
    check_docker_package
  fi
}

check_docker_compose_status(){
  if which docker-compose &>/dev/null; then
    printf "[检测到已安装略过] $(which docker-compose) version:"
    local docker_compose_version=$(docker-compose -v | awk '{print $NF}' | awk -F 'v' '{print $2}')
    if [ -n "$docker_compose_version" ]; then
       echo "[$docker_compose_version]"
    else
       echo "[null]"
    fi
    return 0
  else
    #未检测到docker-compose命令开始进行docker-compose检测并安装
    check_docker_compose_package
  fi
}

# 检测功能集合
detect_collect(){
  # 1、检测目录权限
  check_permissions
  # 2、检测适配系统
  check_os
  # 3、所需检测命令
  check_command
  # 4、检测适配架构
  check_os_arch
}

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
  else
    echo "Unsupported OS [x]"
    # 进入架构检测分支
    check_os_next
  fi
}

check_os_next(){
    if [ "$(uname -m)" = "x86_64" ]; then
        # 架构正确判断是否继续安装
        read -rep "The schema x86_64 correct whether to proceed with  (y/n)" inpt
        if [ "$inpt" != 'y' ] && [ "$inpt" != 'Y' ]; then
            exit 1
        fi
    else
        echo "x86_64 [x]"
        exit 1
    fi
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
  if ! command -v iptables &> /dev/null; then
     echo "iptables [x]"
     exit 1
  fi
  if ! command -v cp &> /dev/null; then
     echo "cp [x]"
     exit 1
  fi
  if ! command -v tar &> /dev/null; then
     echo "tar [x]"
     exit 1
  fi
  if ! command -v rm &> /dev/null; then
      echo "rm [×]"
      exit 1
  fi
}

check_os_arch(){
  if [ "$(uname -m)" != "x86_64" ]; then
    echo "Hi, bro this script has only been used on x86_64 [x]"
    exit 1
  fi
}

check_docker_package(){
  if [ -d package/ ]; then
     # 2024/6/30增加多个docker安装包时触发选择功能
     local docker_package_number=($(find package/ -name 'docker-*.tgz' -type f | awk -F '/' '{print $NF}'))
     if [ "${#docker_package_number[@]}" == 1 ]; then
        docker_package_name=${docker_package_number[0]}
     elif [ "${#docker_package_number[@]}" -gt 1 ]; then
        printf "\n"
        echo -e "\033[32m----------------------------------------------------\033[0m"
        for (( i = 0; i < "${#docker_package_number[@]}"; i++ )); do
            printf "\t$i.${docker_package_number[$i]}\n"
        done
        echo -e "\033[32m----------------------------------------------------\033[0m"
        printf "\n"
        read -rep "Please select the docker package you want to install: " inpt
        docker_package_name=${docker_package_number[$inpt]}
     fi
     # END 2024/6/30
     if [ -n "$docker_package_name" ] && [ -f "package/$docker_package_name" ];then
        echo "$docker_package_name [ok]"
        docker_install
     else
        echo "docker-*.tgz package [x]"
     fi
  else
     echo "package not found."
     exit 1
  fi
}

check_docker_compose_package(){
  if [ -d package/ ]; then
     # 2024/6/30增加多个docker-compose安装包时触发选择功能
     local  docker_compose_package_number=($(find package/ -name 'docker-compose*' -type f | awk -F '/' '{print $NF}'))
     if [ "${#docker_compose_package_number[@]}" == 1 ]; then
        docker_compose_package_name=${docker_compose_package_number[0]}
     elif [ "${#docker_compose_package_number[@]}" -gt 1 ]; then
        printf "\n"
        echo -e "\033[32m----------------------------------------------------\033[0m"
        for (( i = 0; i < "${#docker_compose_package_number[@]}"; i++ )); do
            printf "\t$i.${docker_compose_package_number[$i]}\n"
        done
        echo -e "\033[32m----------------------------------------------------\033[0m"
        printf "\n"
        read -rep "Please select the docker-compose package you want to install(default: $inpt): " inpt
        docker_compose_package_name=${docker_compose_package_number[$inpt]}
     fi
     # END 2024/6/30
     if [ -n "$docker_compose_package_name" ] && [ -f "package/$docker_compose_package_name" ];then
        echo "$docker_compose_package_name [ok]"
        docker_compose_install
     else
        echo "docker-compose* package [x]"
     fi
  else
     echo "package not found."
  fi
}

docker_install(){
   tar xf package/$docker_package_name -C package/
   sudo cp -rf package/docker/* /usr/bin/
   rm -rf package/docker/
   if command -v systemctl &>/dev/null; then
      if [ ! -d /etc/systemd/system/ ]; then
          mkdir -p /etc/systemd/system/
      fi
      cp -rf config/docker.service /etc/systemd/system/
      if [ -f /etc/systemd/system/docker.service ];then
         echo "copy docker.service [ok]"
         chmod +x /etc/systemd/system/docker.service
         if [ ! -d /etc/docker/ ];then
             mkdir /etc/docker/
         fi
         cp -rf config/daemon.json /etc/docker/
         if [ -f /etc/docker/daemon.json ];then
            echo "copy daemon.json [ok]"
         else
            echo "copy daemon.json [x]"
            exit 1
         fi
         systemctl daemon-reload
         systemctl start docker
         if $(docker info &>/dev/null); then
            printf "docker [ok] version: "
            local docker_version=$(docker --version | awk '{print $3}' | awk -F ',' '{print $1}')
            if [ -n "$docker_version" ]; then
               echo "[$docker_version]"
            else
               echo "[null]"
            fi
            systemctl enable docker
         else
            echo "docker [×]"
            exit 1
         fi
      else
         echo "copy docker.service [x]"
         exit 1
      fi
   else
      echo "systemctl not found."
      exit 1
   fi
}

docker_compose_install(){
   cp -rf package/$docker_compose_package_name /usr/bin/docker-compose
   if [ -f /usr/bin/docker-compose ]; then
       chmod +x /usr/bin/docker-compose
   fi
   if $(docker-compose --version &>/dev/null); then
      printf "docker-compose [ok] version: "
      local docker_compose_version=$(docker-compose -v | awk '{print $NF}' | awk -F 'v' '{print $2}')
      if [ -n "$docker_compose_version" ]; then
         echo "[$docker_compose_version]"
      else
         echo "[null]"
      fi
   else
      echo "docker-compose [x]"
      exit 1
   fi
}
  # 检测集合
  detect_collect
  # 安装
  check_docker_status
  check_docker_compose_status
