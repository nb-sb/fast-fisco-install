#!/bin/bash
function LOG_ERROR(){
    local content=${1}
    echo -e "\033[31m"${content}"\033[0m"
}
function LOG_INFO(){
    local content=${1}
    echo -e "\033[32m"${content}"\033[0m"
}
install_caliper(){
    caliper_target_dir=~/benchmarks
    if [ ! -d "$caliper_target_dir" ]; then
        mkdir $caliper_target_dir
    fi
    cd $caliper_target_dir && caliper_version=$(npx caliper --version)
    if [ -z "$caliper_version" ]; then
        LOG_INFO "😋正在为您安装caliper  "
        npm init -y
        download_if_not_exists() {
            if [ ! -f "$caliper_target_dir/$2" ]; then
                cd $caliper_target_dir && wget -O $2 $1 && unzip $2 && rm -rf $2
            else
                LOG_INFO "🥵 ✔✔✔ 文件 $2 已存在，跳过下载"
            fi
                }
        download_if_not_exists "https://gitee.com/nb-sb/fast-fisco-install/raw/main/caliper/node_modules.zip" "node_modules.zip"
        download_if_not_exists "https://gitee.com/nb-sb/fast-fisco-install/raw/main/caliper/caliper-benchmarks.zip" "caliper-benchmarks.zip"

    else
        LOG_INFO "caliper已安装，版本：$caliper_version"
        read -p "是否重新安装caliper？(y/n) " reinstall
        if [ "$reinstall" == "y" ]; then
           LOG_INFO "😋正在为您安装caliper...... "
            download_if_not_exists() {
                if [ ! -f "$caliper_target_dir/$2" ]; then
                    cd $caliper_target_dir && wget -O $2 $1 && unzip $2 && rm -rf $2
                else
                   LOG_INFO "🥵 ✔✔✔ 文件 $2 已存在，跳过下载"
                fi
            }
            download_if_not_exists "https://github.com/nb-sb/fast-fisco-install/raw/main/caliper/node_modules.zip" "node_modules.zip"
            download_if_not_exists "https://github.com/nb-sb/fast-fisco-install/raw/main/caliper/caliper-benchmarks.zip" "caliper-benchmarks.zip"
        else
            LOG_ERROR "😋取消安装caliper "
        fi
    fi
    caliper_version=$(npx caliper --version)
    clear
    echo -e "\033[32m
            😋 caliper安装成功！
            ================================
            caliper版本： $caliper_version
            安装目录  $caliper_target_dir
            ================================
            测试命令：
            npx caliper benchmark run --caliper-workspace caliper-benchmarks --caliper-benchconfig benchmarks/samples/fisco-bcos/helloworld/config.yaml  --caliper-networkconfig networks/fisco-bcos/4nodes1group/fisco-bcos.json
            =================================
            \033[0m"
    
}


install_caliper