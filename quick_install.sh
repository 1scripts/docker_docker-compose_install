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

# 检测给定URL的响应时间
measure_response_time() {
    local url=$1
    local start=$(date +%s.%N)
    curl -Is "$url" > /dev/null
    local end=$(date +%s.%N)
    # 使用bc计算时间差，并保留3位小数，然后直接输出，避免在整数运算环境下处理
    echo "$(bc <<< "scale=3; $end - $start")"
}

# 检查Gitee和GitHub的通信速度并选择最快
check_git_speed() {
    local gitee_url="https://gitee.com"
    local github_url="https://github.com"
    printf "选取访问最快的地址..."
    gitee_time=$(measure_response_time "$gitee_url")
    github_time=$(measure_response_time "$github_url")

    if (( $(bc <<< "$gitee_time < $github_time") )); then
        echo "Gitee"
        url="$gitee_url"
    else
        echo "GitHub"
        url="$github_url"
    fi
}

# 检测目录和文件
detect_dir_file() {
    local dir1=/tmp/
    local dir2=/tmp/docker_docker-compose_script/
    local file1=/tmp/docker_docker-compose_install.zip
    if [ ! -d "$dir1" ]; then
        mkdir -p "$dir"
    fi
    if [ -d "$dir2" ]; then
        mv "$dir2" "$dir2$(date +%Y-%m-%d_%H-%M-%S)"
    fi
    if [ -f "$file1" ]; then
        mv "$file1" "$file1$(date +%Y-%m-%d_%H-%M-%S)"
    fi
}

# 下载安装包
download_install_package() {
   local version=v1.4
   if [ "$url" == "https://gitee.com" ]; then
      local url_path="https://gitee.com/li_blog/docker_docker-compose_install/releases/download/docker_docker_compose_$version/docker_docker-compose_install.zip"
   elif [ "$url" == "https://github.com" ]; then
      local url_path="https://github.com/1scripts/docker_docker-compose_install/releases/download/docker_docker_compose_$version/docker_docker-compose_install.zip"
   fi
   wget $url_path -P /tmp/
   if [ $? -ne 0 ]; then
      echo "ERROR: 下载安装包失败."
      exit 1
   fi
}

# 执行安装脚本
execute_install_script() {
   unzip /tmp/docker_docker-compose_install.zip -d /tmp/
   if [ $? -ne 0 ]; then
      echo "ERROR: 解压安装包失败."
      exit 1
   fi
   bash /tmp/docker_docker-compose_script/install.sh
   if [ $? -ne 0 ]; then
     echo "ERROR: 执行安装脚本失败."
   fi
}

# 命令检测
detect_command
# 调用函数检查速度
check_git_speed
# 检测目录和文件
detect_dir_file
# 下载安装包
download_install_package
# 执行安装脚本
execute_install_script