#!/bin/bash

detect_command() {
 if command -v apt &>/dev/null; then
    local package_master="apt"
 elif command -v yum &>/dev/null; then
    local package_master="yum"
 elif command -v dnf &>/dev/null; then
    local package_master="dnf"
 fi
 if ! command -v bc &>/dev/null; then
    $package_master install -y bc
    if [ $? -ne 0 ]; then
       echo "ERROR: bc not found."
       exit 1
    fi
 fi
 if ! command -v wget &>/dev/null; then
    $package_master install -y wget
    if [ $? -ne 0 ]; then
       echo "ERROR: wget not found."
       exit 1
    fi
 fi
 if ! command -v unzip &>/dev/null; then
    $package_master install -y unzip
    if [ $? -ne 0 ]; then
       echo "ERROR: unzip not found."
       exit 1
    fi
 fi
}

# 架构检测
check_os_arch() {
    if [ "$(uname -m)" != "x86_64" ]; then
        echo "Only supports x86_64 "
        exit 1
    fi
}

# 选择下载地址
check_git_speed() {
    local url_xargs=$1
    local url_1="https://gitee.com"
    local url_2="https://github.com"
    local url_3="https://git.homegu.com"
    if [[ $url_xargs =~ ^[0-9]+$ ]] ; then
       if [ "$url_xargs" == "1" ]; then
           url=$url_1
       elif [ "$url_xargs" == "2" ]; then
           url=$url_2
       elif [ "$url_xargs" == "3" ]; then
           url=$url_3
       else
           echo "Number failed."
           exit 1
       fi
    else
        if [[ $url_xargs == https://* ]]; then
           local get_url_return=$(curl -Is "$url_xargs" | head -n 1 | awk '{print $2)')
           if [ "$get_url_return" == "200" ]; then
              url="$url_xargs"
           else
              echo "ERROR: return status $get_url_return"
              exit 1
           fi
        else
           echo "Requires https:// link or number"
           exit 1
        fi
    fi
}

# 检测目录和文件
detect_dir_file() {
    local dir1=/tmp/
    local dir2=docker_docker-compose_script
    local file1=docker_docker-compose_script.zip
    if [ ! -d "$dir1" ]; then
        mkdir -p "$dir"
    fi
    if [ -d "$dir1/$dir2" ]; then
       cd "$dir1" &&  mv "$dir2" "$(date +%Y-%m-%d_%H-%M-%S)_$dir2"
    fi
    if [ -f "$dir1/$file1" ]; then
       cd $dir1 &&  mv "$file1" "$(date +%Y-%m-%d_%H-%M-%S)_$file1"
    fi
}

# 下载安装包
download_install_package() {
   local version=v1.4
   if [ "$url" == "https://gitee.com" ]; then
      local url_path="$url/li_blog/docker_docker-compose_install/releases/download/docker_docker_compose_$version/docker_docker-compose_script.zip"
   elif [ "$url" == "https://github.com" ]; then
      local url_path="$url/1scripts/docker_docker-compose_install/releases/download/docker_docker_compose_$version/docker_docker-compose_script.zip"
   else
      local url_path="$url/1scripts/docker_docker-compose_install/releases/download/docker_docker_compose_$version/docker_docker-compose_script.zip"
   fi
   wget $url_path -P /tmp/
   if [ $? -ne 0 ]; then
      echo "ERROR: 下载安装包失败."
      exit 1
   fi
}

# 执行安装脚本
execute_install_script() {
   unzip /tmp/docker_docker-compose_script.zip -d /tmp/
   if [ $? -ne 0 ]; then
      echo "ERROR: 解压安装包失败."
      exit 1
   fi
   bash /tmp/docker_docker-compose_script/install.sh
   if [ $? -ne 0 ]; then
     echo "ERROR: 执行安装脚本失败."
   fi
   [ -f /tmp/docker_docker-compose_script.zip ] && rm -rf /tmp/docker_docker-compose_script.zip
   [ -d /tmp/docker_docker-compose_script ] && rm -rf /tmp/docker_docker-compose_script
}

# 命令检测
detect_command
# 检测架构
check_os_arch
# 选择下载地址
if [ -z "$CDN" ];then
   check_git_speed 2 # default https://github.com
else
   check_git_speed $CDN # 1:gitee 2:github 3:git.homegu.com
fi
# 检测目录和文件
detect_dir_file
# 下载安装包
download_install_package
# 执行安装脚本
execute_install_script