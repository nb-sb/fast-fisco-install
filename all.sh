#!/bin/bash
# By : 戏人看戏
# qq：3500079813
# blog : https://day.nb.sb

red='\e[91m'
green='\e[92m'
# 定义ANSI转义码
YELLOW='\033[1;33m'
NC='\033[0m' # 恢复到默认颜色
magenta='\e[95m'
cyan='\e[96m'
none='\e[0m'
notshow_menu='notshowmenu'
isshow_menu='showmenu'
is_return='exit'
show_error='showerror'

function show_dir(){
    LOG_Yellow "============== Below is the current directory ================="
    ls ${1}
}
function LOG_ERROR() {
    # local content=${1}
    echo -e "${red}"${1}"${NC}"
}
function LOG_INFO() {
    # local content=${1}
    echo -e "${green}"${1}"${NC}"
}

function LOG_Yellow(){
    echo -e "${YELLOW} ${1} ${NC}"
}
pause() {
    read -rsp "$(echo -e "按 $green Enter 回车键 $none 继续....或按 $red Ctrl + C $none 取消.")" -d $'\n'
    echo
}
# wb_path=$(pwd) 	#默认脚本与WeBase子系统处于同级目录,如有不同，自行修改
port=0
web_Port=5000	#默认5000

function  webase_front(){
    local wb_path=$1
    LOG_INFO "检查 webase-front..."	#在同级目录下查找webase-front文件夹
    wabse_front_path=$(find $wb_path -name 'webase-front' -type d)
    cd $wabse_front_path			#进入WeBase-Front目录
    status="$(bash status.sh)"		#运行状态脚本
    if [[ $status == *"running"* ]]
    then
        msg=`echo ${status#*Port}`
        port=`echo ${msg%%i*}` 		#进行字符串截取获得端口(默认5002)
    fi
    
    port_msg=`lsof -i:$port`			#lsof -i:port 查看端口连接
    if [[ $port_msg == *"LISTEN"* ]] 	#判断端口是否被监听，是则正常运行，否则运行有误
    then 							#后续两个子系统方法大致相同
        LOG_INFO "WeBase-Front is Successful"
    else
        LOG_ERROR "WeBase-Front is Fail"
        return
    fi
    LOG_INFO  "检查 webase-front finish\n"
}

function  webase_node_mgr(){
    local wb_path=$1
    #查找webase-node-mgr文件夹
    LOG_INFO "检查 webase-node-mgr..."
    webase_node_mgr_path=$(find $wb_path -name 'webase-node-mgr' -type d)
    cd $webase_node_mgr_path
    status=$(bash status.sh)
    if [[ $status == *"running"* ]]
    then
        msg=`echo ${status#*Port}`
        port=`echo ${msg%%i*}` #获得端口
    fi
    port_msg=`lsof -i:$port`
    if [[ $port_msg == *"LISTEN"* ]]
    then
        LOG_INFO "WeBase-Node-Mgr is Successful"
    else
        LOG_ERROR "WeBase-Node-Mgr is Fail"
        return
    fi
    LOG_INFO  "检查 WeBase-Node-Mgr finish\n"
}

function  webase_sign(){
    local wb_path=$1
    #查找webase_sign文件夹
    LOG_INFO "检查 webase_sign..."
    webase_sign_path=$(find $wb_path -name 'webase-sign' -type d)
    cd $webase_sign_path
    status=$(bash status.sh)
    if [[ $status == *"running"* ]]
    then
        msg=`echo ${status#*Port}`
        port=`echo ${msg%%i*}` #获得端口
    else
        LOG_ERROR "no running"
    fi
    
    port_msg=`lsof -i:$port`
    if [[ $port_msg == *"LISTEN"* ]]
    then
        LOG_INFO "WeBase-Sign is Successful"
    else
        LOG_ERROR "WeBase-Sign is Fail"
    fi
    LOG_INFO  "检查 WeBase-Sign finish\n"
}
function  webase_web(){
    local wb_path=$1
    LOG_INFO "检查 webase_web..."
    nginx_conf=$wb_path/comm/nginx.conf		#获取nginx.conf的工作路径
    nginx_msg="`ps -ef |grep nginx`"		#ps(英文全拼：process status)命令用于显示当前进程的状态 ps -ef -e显示所有进程,-f全格式。
    
    if [[ $nginx_msg == *$nginx_conf* ]] 	#进行匹配查看，nginx服务有无使用webase-web自带的nginx配置
    then
        LOG_INFO "WeBase-Web is Successful"
    else
        LOG_ERROR "WeBase-Web is Fail"
    fi
    LOG_INFO  "检查 WeBase-Web finish\n"
}

# 检查命令是否存在
check_command() {
    if ! command -v $1 >/dev/null; then
        echo "错误：缺少必要的工具 $1，正在尝试帮你安装 $1"
        if command -v apt-get >/dev/null; then
            apt-get install -y $1
            elif command -v yum >/dev/null; then
            yum install -y $1
        fi
        if command -v $1 >/dev/null; then
            LOG_INFO "$1🥵 ✔✔✔安装完成 "
        else
            LOG_ERROR "$1🥵 安装失败 ！！！ "
            exit
        fi
    fi
}

# 安装python
install_python() {
    read -p "[1/3]>请输入python版本,例如3.8: " py_V
    if [ -z $py_V ]; then
        py_V=3.8
    fi
    LOG_INFO "预计下载并安装python$py_V.10版本的python请稍等！"
    read -p "[2/3]>是否用华为云源进行安装,否则使用华为镜像安装(y/n)：" huawei
    
    py_version=$py_V
    # python的具体版本号
    version=$py_version.10
    # 要安装的路径
    install_path=/usr/local/src/python$version
    #-----可变参数-end-----
    LOG_INFO "即将安装python $version "
    LOG_INFO "安装路径为$install_path"
    
    # 判断操作系统类型
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [ "$ID" = "ubuntu" ]; then
            LOG_INFO "Detected Ubuntu, installing dependencies and updating..."
            
            # 在 Ubuntu 上安装依赖并升级索引的代码
            sudo apt install -y build-essential zlib1g-dev libbz2-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libreadline-dev libffi-dev wget
            sudo apt update
            sudo apt upgrade -y
            
            elif [ "$ID" = "centos" ]; then
            LOG_INFO "Detected CentOS, installing dependencies and updating..."
            
            # 在 CentOS 上安装依赖并升级索引的代码
            sudo yum install -y epel-release
            sudo yum install -y zlib-devel bzip2-devel ncurses-devel gdbm-devel openssl-devel readline-devel libffi-devel wget
            sudo yum update -y
            
        else
            LOG_ERROR "不支持的Linux发行版"
            exit 1
        fi
    else
        LOG_ERROR "不支持的Linux发行版"
        exit 1
    fi
    
    # 创建安装目录文件夹
    sudo mkdir -p $install_path
    
    # 下载python
    LOG_INFO '正在下载'
    if [[ "${huawei,,}" == "no" || "${huawei,,}" == "n" || "$huawei" == "n" ]]; then
        # if [ "$huawei" = "n" ] || [ "$huawei" = "N" ] || [ "$huawei" = "no" ] || [ "$huawei" = "No" ] || [ "$huawei" = "NO" ] ; then
        LOG_INFO "正在使用官方源进行下载 "
        wget https://www.python.org/ftp/python/$version/Python-$version.tgz
    else
        LOG_INFO "正在使用华为源进行下载 "
        wget https://mirrors.huaweicloud.com/python/$version/Python-$version.tgz
    fi
    
    LOG_INFO "正在解压"
    # 静默解压
    tar -xzf Python-$version.tgz
    # 删除压缩包
    LOG_INFO "解压完成，移除压缩包"
    rm -rf Python-$version.tgz
    
    LOG_INFO "正在安装"
    cd Python-$version
    ./configure --prefix=$install_path # 配置安装位置
    sudo make
    sudo make install
    
    LOG_INFO "配置软连接"
    rm -rf /usr/bin/python$py_version /usr/bin/pip$py_version
    sudo ln -s $install_path/bin/python$py_version /usr/bin/python$py_version
    sudo ln -s $install_path/bin/pip$py_version /usr/bin/pip$py_version
    
    cd ..
    sudo rm -rf Python-$version
    LOG_INFO "完成安装Python-$version"
    read -p "[3/3]>是否需要换为国内源？(y/n)：" yuan
    if [[ "${yuan,,}" == "no" || "${yuan,,}" == "n" || "$yuan" == "n" ]]; then
        LOG_INFO "不使用国内源"
    else
        LOG_ERROR "正在升级PIP"
        "pip$py_version" install --upgrade pip
        LOG_ERROR "正在换为清华源"
        "pip$py_version" config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
        LOG_INFO "换源结果："
        "pip$py_version" config list
    fi
    
}
# 安装java
install_java() {
    # 更新包索引
    if command -v apt-get >/dev/null; then
        apt-get update
        apt-get install -y openssh-server curl wget git net-tools unzip python3-pip openjdk-11-jre-headless nginx
        echo 'export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64' >>~/.bashrc
        echo 'export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64' >>/etc/profile
        source ~/.bashrc
        source /etc/profile
        elif command -v yum >/dev/null; then
        rpm -qa | grep java | xargs rpm -e --nodeps
        yum -y remove java-1.8.0-openjdk-headless-1.8.0.65-3.b17.el7.x86_64
        # mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
        # wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
        # yum clean all
        # yum makecache
        yum update
        yum install -y openssh-server curl wget git net-tools unzip python3-pip nginx
        # 配置Java的开发环境
        cd /usr/local && \
        wget --no-check-certificate https://nb.sb/shell/jdk-8u381-linux-x64.tar.gz && \
        tar -xzvf jdk-8u381-linux-x64.tar.gz
        echo 'export JAVA_HOME=/usr/local/jdk1.8.0_381' >>/etc/profile
        echo 'export PATH=$JAVA_HOME/bin:$PATH' >>/etc/profile
        echo 'export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar' >>/etc/profile
        # echo 'export JAVA_HOME=/user/local/jdk1.8.0_381' >>~/.bashrc
        # echo 'export PATH=$JAVA_HOME/bin:$PATH' >>~/.bashrc
        # echo 'export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar' >>~/.bashrc
        
        # wget -O jdk-17_linux-x64_bin.tar.gz https://download.oracle.com/java/17/latest/jdk-17_linux-x64_bin.tar.gz
        # tar zxf jdk-17_linux-x64_bin.tar.gz
        # rm -rf jdk-17_linux-x64_bin.tar.gz
        # mv jdk-17.0.8 jdk-17
        # mv jdk-17 /usr/local/
        # echo 'export JAVA_HOME=/usr/local/jdk-17' >>~/.bashrc
        # echo 'export PATH=/usr/local/php/bin:/usr/local/jdk-17/bin:$PATH' >>~/.bashrc
        source /etc/profile
        # https://cloud.tencent.com/developer/article/2023036
    else
        echo "不支持的Linux发行版"
        exit 1
    fi
}
# 简单粗暴，关闭防火墙
stop_firewall(){
    # 笨笨的检测系统类型方法
    if [[ $(command -v yum) ]] && [[ $(command -v systemctl) ]]; then
        # CentOS
        # 关闭防火墙
        systemctl stop firewalld
        systemctl disable firewalld
        # 设置开机禁用防火墙
        systemctl disable firewalld.service
        LOG_ERROR -e "\n  该脚本已自动关闭防火墙... "
        elif [[ $(command -v apt-get) ]] && [[ $(command -v systemctl) ]] && [[ $(command -v ufw) ]]; then
        # Debian or Ubuntu
        # 关闭防火墙
        ufw disable
        LOG_ERROR -e "\n 该脚本已自动关闭防火墙...... "
    fi
}

# 安装依赖
install_dependencies() {
    
    java_version=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
    LOG_INFO "当前Java版本: $java_version"
    LOG_ERROR "🥵 注：若无显示则无java环境"
    if ! [[ $java_version =~ "1.8" ]]; then
        read -p "是否需要安装Java环境？[Y/n]: " install
        # 判断用户的选择
        if [[ -z ${install} ]] || [[ ${install,,} == "y" || ${install,,} == "yes" ]]; then
            LOG_INFO "开始安装Java环境......"
            install_java
        else
            LOG_INFO "跳过安装Java环境。"
        fi
    fi
    
    
}

# 安装Docker
install_docker_env() {
    if command -v docker >/dev/null; then
        LOG_INFO " 🥵 ✔✔✔ Docker 已经安装，跳过安装docker步骤  "
        if command -v docker-compose >/dev/null; then
            LOG_INFO " 🥵 ✔✔✔ Docker-compose 已经安装，跳过安装Docker-compose步骤  "
            return
        fi
    fi
    if command -v apt-get >/dev/null; then
        apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
        elif command -v yum >/dev/null; then
        yum install -y yum-utils device-mapper-persistent-data lvm2
    else
        LOG_ERROR "不支持的Linux发行版"
        exit 1
    fi
    
    # 检查是否是 Ubuntu 发行版
    # 安装Docker Compose
    install_docker_compose() {
        LOG_INFO "安装Docker Compose..."
        
        primary_url="https://nb.sb/shell/docker-compose-Linux-x86_64"
        backup_url="https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)"
        
        # 使用-f选项，并检查curl命令的返回状态
        if ! curl -Lf "$primary_url" -o /usr/local/bin/docker-compose; then
            # 如果primary_url失败，则使用backup_url
            if ! curl -Lf "$backup_url" -o /usr/local/bin/docker-compose; then
                LOG_ERROR "两个URL都失败了，Docker Compose没有安装成功。"
                return 1
            fi
        fi
        
        chmod +x /usr/local/bin/docker-compose
        
        # 使用-lnf来确保在/usr/bin/已经存在的情况下覆盖链接
        ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
        
        echo "Docker Compose安装完成."
    }
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [ "$ID" = "ubuntu" ]; then
            echo "ubuntu的系统"
            install_docker() {
                echo "安装Docker..."
                apt-get update
                apt-get install -y apt-transport-https ca-certificates curl software-properties-common
                curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
                add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $UBUNTU_CODENAME stable"
                apt-get update
                apt-get install -y docker-ce
                systemctl start docker
                systemctl enable docker
                echo "Docker安装完成."
            }
            
            docker_install_info=$(docker -v | grep version)
            
        elif
        
        [ "$ID" = "centos" ]
        then
            echo "centos的系统"
            # 安装Docker
            install_docker() {
                echo "安装Docker..."
                yum update -y
                yum install -y yum-utils device-mapper-persistent-data lvm2
                yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
                yum install -y docker-ce
                systemctl start docker
                systemctl enable docker
                echo "Docker安装完成."
            }
            
            docker_install_info=$(docker -v | grep version)
        else
            LOG_ERROR "不支持的Linux发行版"
            exit 1
        fi
    else
        echo "不支持的Linux发行版"
        exit 1
    fi
    
    docker_install_info=$(docker -v | grep version)
    if [ $"$docker_install_info" ]; then
        clear
        echo -e "\033[32m
                ============================================================
                🔋   当前Docker环境：
                ✔✔✔ Docker版本: $docker_install_info
                ============================================================
        \033[0m"
    else
        LOG_ERROR "docker未安装,准备开始安装docker"
        install_docker
    fi
    
    docker_install_success=$(docker -v | grep -o version)
    if [ $"$docker_install_success" ]; then
        LOG_INFO "正在配置docker镜像源"
        sudo mkdir -p /etc/docker
        sudo sh -c 'echo "{\"registry-mirrors\": [\"https://kuamavit.mirror.aliyuncs.com\", \"https://registry.docker-cn.com\", \"https://docker.mirrors.ustc.edu.cn\"]}" > /etc/docker/daemon.json'
        sudo systemctl daemon-reload
        sudo systemctl restart docker
    else
        echo "docker未安装成功,请检查执行过程"
        exit
    fi
    
    docker_compose_install_success=$(docker-compose -v | grep version)
    if [ $"$docker_compose_install_success" ]; then
        clear
        echo -e "\033[32m
                ============================================================
                🔋   当前Docker-compose环境：
                ✔✔✔ Docker-compose版本: $docker_compose_install_success$docker_compose_install_success
                ============================================================
        \033[0m"
        exit
    else
        read -p "是否执行安装docker-compose ? (y/n)：" doc
        if [[ "${doc,,}" == "no" || "$doc" == "n" ]]; then
            return
        else
            LOG_INFO "准备开始安装docker-compose"
            install_docker_compose
        fi
    fi
    
    docker_compose_install_success=$(docker-compose -v | grep version)
    if [ $"$docker_compose_install_success" ]; then
        clear
        echo -e "\033[32m
                ============================================================
                🔋   当前Docker-compose环境：
                docker-compose已经成功安装
                ✔✔✔ Docker-compose版本: $docker_compose_install_success$docker_compose_install_success
                ============================================================
        \033[0m"
    else
        LOG_ERROR "docker-compose未安装成功,请检查执行过程"
        exit
    fi
    
    LOG_INFO "一键安装docker环境完成！你真是个小天才！"
    docker_version=$(docker -v)
    docker_compose_version=$(docker-compose -v)
    clear
    echo -e "\033[32m
                ============================================================
                一键安装完成！你真是个小天才！
                docker版本：$docker_version
                docker-compose版本 ： $docker_compose_version
                ============================================================
    \033[0m"
}

# 安装Node.js和NVM
install_nodejs_nvm() {
    # 检查是否已经安装 NVM
    if command -v nvm >/dev/null; then
        echo -e "\033[32mm🥵 ✔✔✔ NVM 已经安装，跳过安装步骤  "
    else
        # 安装NVM
        # curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash
        primary_url="https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh"
        backup_url="https://nb.sb/shell/nvm_install.sh"
        
        # 尝试使用主要链接进行下载，最多重试3次，每次间隔5秒
        curl --fail --retry 3 --retry-delay 5 -o- "$primary_url" | bash
        
        # 如果主要链接下载失败，则切换到备用链接
        if [ $? -ne 0 ]; then
            curl -o- "$backup_url" | bash
        fi
        source ~/.$(basename $SHELL)rc
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
        echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm' >>"$HOME/.bashrc"
        
        # Appending bash_completion source string to .bashrc
        [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion
        echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion' >>"$HOME/.bashrc"
        
        source ~/.bashrc
        export NVM_NODEJS_ORG_MIRROR=https://npm.taobao.org/mirrors/node/
        export NVM_IOJS_ORG_MIRROR=http://npm.taobao.org/mirrors/iojs
        source ~/.bashrc
    fi
    
    LOG_INFO "
    😋检查是否已经安装了Node.js 16   "
    # 检查是否已经安装了Node.js 16
    if ! nvm list | grep -q "v16"; then
        LOG_ERROR "
        😋未安装Node.js 16 ，正在为您安装....   "
        # 安装Node.js 16
        nvm install 16
        nvm use 16
    fi
    LOG_INFO "
    😋已经安装了Node.js 16  "
}

# 安装Remix IDE
install_remix() {
    docker pull remixproject/remix-ide:latest
    sleep 3
    docker run -d -p 8080:80 --name remix --restart=always remixproject/remix-ide:latest
    sleep 3
    
    # 检查是否已经安装并启动 Remix IDE
    if docker ps -a --format "{{.Names}}" | grep -q "^remix$"; then
        if docker ps --format "{{.Names}}" | grep -q "^remix$"; then
            echo "Remix IDE 已经安装并已启动"
        else
            echo "Remix IDE 已经安装但未启动，正在启动..."
            docker start remix
        fi
    else
        echo "安装 Remix IDE..."
        docker pull remixproject/remix-ide:latest
        sleep 3
        docker run -d -p 8080:80 --name remix --restart=always remixproject/remix-ide:latest
        sleep 3
    fi
}

# 安装FISCO BCOS
install_fisco_bcos() {
    LOG_INFO "🥵 ✔✔✔ 检测完成当前的环境"
    local target_dir=$1
    clear
    echo
    echo "即将将 FISCO BCOS 环境安装至 $target_dir 目录下"
    pause
    echo
    # 备份旧工作目录并创建新目录
    if [[ ! -d "$target_dir" ]]; then
        mkdir -p "$(eval echo $target_dir)"
        echo "目录 $target_dir 创建成功"
    else
        LOG_INFO "🥵 ✔✔✔ 检测到你环境中已经安装了$target_dir 目录是否需要备份？不备份就覆盖安装"
        read -p "检测到你环境中已经安装了$target_dir 目录是否需要备份？[y/n]:" backup
        if [ -z "$backup" ]; then
            backup=y
        fi
        if [[ ${backup,,} == "n" || ${backup,,} == "no" ]]; then
            # rm -rf "$target_dir/"
            cd $target_dir && bash nodes/127.0.0.1/stop_all.sh && cd "$target_dir/webase-front/" && bash stop.sh
            # 删除除了 .tar.gz 和 .zip 文件之外的所有文件
            cd $target_dir && find . ! -name "*.tar.gz" ! -name "*.zip" ! -name "*.sh" -exec rm -rf {} \;
            mkdir "$target_dir"
        else
            LOG_INFO "🥵 ✔✔✔ 当前目录已存在正在备份中..."
            cd $target_dir && bash nodes/127.0.0.1/stop_all.sh && cd "$target_dir/webase-front/" && bash stop.sh
            mv "$target_dir" "${target_dir}_bak_$(date +'%Y%m%d_%H:%M:%S')"
            rm -rf "$target_dir"
            mkdir "$target_dir"
        fi
    fi
    
    # 定义下载函数，如果文件存在则跳过
    download_if_not_exists() {
        if [ ! -f "$target_dir/$2" ]; then
            if [ ! -d "/run/fiscor-rely/" ];then
                mkdir "/run/fiscor-rely/"
            fi
            # 下载后将其创建一个/run/fiscor-rely目录复制一份到这个目录下
            # 下载之前先判断这个目录下是否存在需要下载的文件,如果存在则直接复制到这里
            if [ -f  "/run/fiscor-rely/$2" ];then
                cp -r "/run/fiscor-rely/$2" "$target_dir/$2"
            else
                cd $target_dir && curl -#LO "$1" -o "$target_dir/$2"
                cp "$target_dir/$2" "/run/fiscor-rely/$2"
            fi
            
            if [ "${2##*.}" = "tar.gz" ]; then
                tar zxvf "$target_dir/$2" -C "$target_dir" --strip-components=1
                # tar -zxvf "$target_dir/$2"
                # tar -zxvf "fisco-bcos.tar.gz"
                elif [ "${2##*.}" = "zip" ]; then
                unzip "$target_dir/$2" -d "$target_dir"
            fi
        else
            LOG_INFO "🥵 ✔✔✔ 文件 $2 已存在，跳过下载"
        fi
    }
    
    LOG_INFO "拉取FISCO BCOS和WeBASE的离线包"
    # 拉取FISCO BCOS和WeBASE的离线包
    download_if_not_exists "https://osp-1257653870.cos.ap-guangzhou.myqcloud.com/FISCO-BCOS/FISCO-BCOS/releases/v2.8.0/build_chain.sh" "build_chain.sh"
    download_if_not_exists "https://osp-1257653870.cos.ap-guangzhou.myqcloud.com/FISCO-BCOS/console/releases/v2.8.0/console.tar.gz" "console.tar.gz"
    download_if_not_exists "https://osp-1257653870.cos.ap-guangzhou.myqcloud.com/FISCO-BCOS/FISCO-BCOS/releases/v2.8.0/fisco-bcos.tar.gz" "fisco-bcos.tar.gz"
    download_if_not_exists "https://osp-1257653870.cos.ap-guangzhou.myqcloud.com/FISCO-BCOS/FISCO-BCOS/tools/get_account.sh" "get_account.sh"
    download_if_not_exists "https://gitee.com/FISCO-BCOS/FISCO-BCOS/raw/master-2.0/tools/gen_node_cert.sh" "gen_node_cert.sh"
    download_if_not_exists "https://osp-1257653870.cos.ap-guangzhou.myqcloud.com/WeBASE/releases/download/v1.5.5/webase-front.zip" "webase-front.zip"
    download_if_not_exists "https://osp-1257653870.cos.ap-guangzhou.myqcloud.com/WeBASE/releases/download/v1.5.5/webase-deploy.zip" "webase-deploy.zip"
    
    LOG_INFO "🥵 ✔✔✔ 所有文件已下载或存在"
}

install_fisco_bcos_30() {
    LOG_INFO "🥵 ✔✔✔ 检测完成当前的环境"
    
    target_dir=~/fisco
    
    # 备份旧工作目录并创建新目录
    if [ ! -d "$target_dir" ]; then
        mkdir "$target_dir"
    else
        LOG_INFO "🥵 ✔✔✔ 检测到你环境中已经安装了/fisco目录是否需要备份？不备份就覆盖安装"
        read -p "检测到你环境中已经安装了/fisco目录是否需要备份？[y/n] : " backup
        if [ -z "$backup" ]; then
            backup=y
        fi
        if [[ ${backup,,} == "n" || ${backup,,} == "no" ]]; then
            # rm -rf "$target_dir"
            cd ~/fisco && bash nodes/127.0.0.1/stop_all.sh && cd ~/fisco/webase-front/ && bash stop.sh
            cd ~/fisco && find . ! -name "*.tar.gz" ! -name "*.zip" ! -name "*.sh" -exec rm -rf {} \;
            mkdir "$target_dir"
        else
            LOG_INFO "🥵 ✔✔✔ 当前目录已存在正在备份中..."
            cd ~/fisco && bash nodes/127.0.0.1/stop_all.sh && cd ~/fisco/webase-front/ && bash stop.sh
            mv "$target_dir" "${target_dir}_bak_$(date +'%Y%m%d_%H:%M:%S')"
            rm -rf "$target_dir"
            mkdir "$target_dir"
        fi
    fi
    
    # 定义下载函数，如果文件存在则跳过
    download_if_not_exists() {
        if [ ! -f "$target_dir/$2" ]; then
            cd ~/fisco && curl -#LO "$1" -o "$target_dir/$2"
            
            if [ "${2##*.}" = "tar.gz" ]; then
                tar zxvf "$target_dir/$2" -C "$target_dir" --strip-components=1
                
                elif [ "${2##*.}" = "zip" ]; then
                unzip "$target_dir/$2" -d "$target_dir"
            fi
        else
            LOG_INFO "🥵 ✔✔✔ 文件 $2 已存在，跳过下载"
        fi
    }
    
    # 拉取FISCO BCOS 3.1的离线包
    download_if_not_exists "https://osp-1257653870.cos.ap-guangzhou.myqcloud.com/FISCO-BCOS/FISCO-BCOS/releases/v3.1.0/build_chain.sh" "build_chain.sh"
    download_if_not_exists "https://osp-1257653870.cos.ap-guangzhou.myqcloud.com/FISCO-BCOS/FISCO-BCOS/releases/v3.1.0/BcosBuilder.tgz" "BcosBuilder.tgz"
    download_if_not_exists "https://osp-1257653870.cos.ap-guangzhou.myqcloud.com/FISCO-BCOS/FISCO-BCOS/tools/get_account.sh" "get_account.sh"
    download_if_not_exists "https://osp-1257653870.cos.ap-guangzhou.myqcloud.com/FISCO-BCOS/FISCO-BCOS/tools/get_gm_account.sh" "get_gm_account.sh"
    download_if_not_exists "https://osp-1257653870.cos.ap-guangzhou.myqcloud.com/FISCO-BCOS/console/releases/v3.1.0/console.tar.gz" "console.tar.gz"
    download_if_not_exists "https://osp-1257653870.cos.ap-guangzhou.myqcloud.com/FISCO-BCOS/FISCO-BCOS/releases/v3.1.0/fisco-bcos.tar.gz" "fisco-bcos.tar.gz"
    
    # 拉取WeBASE的离线包
    download_if_not_exists "https://osp-1257653870.cos.ap-guangzhou.myqcloud.com/WeBASE/releases/download/v1.5.4/webase-front.zip" "webase-front.zip"
    download_if_not_exists "https://osp-1257653870.cos.ap-guangzhou.myqcloud.com/WeBASE/releases/download/v1.5.4/webase-deploy.zip" "webase-deploy.zip"
    
    LOG_INFO "🥵 ✔✔✔ 所有文件已下载或存在"
}

start_webase() {
    local dir=$1
    LOG_INFO "将要启动 $dir 下的WeBASE"
    # 判断是否存在webase-deploy文件夹
    if [ ! -d "$dir/webase-deploy" ]; then
        LOG_ERROR "webase-deploy folder not found"
        show_dir
        return ;
    fi
    LOG_ERROR "若是第一次启动会自动帮你安装并启动,若不是第一个启动则直接帮你启动跳过安装步骤"
    LOG_ERROR "如若不是第一次启动但填了 y ,则会自动帮你覆盖安装"
    read -p "[3/3]>是否第一次启动？(y/n)：" onestart
    if [[ "${onestart,,}" == "no" || "${onestart,,}" == "n" || "$onestart" == "n" ]]; then
        LOG_INFO "正在帮你启动"
        docker run -d --name mysql_webase -e MYSQL_ROOT_PASSWORD=123456 -p 23306:3306 mysql:5.6
        docker start mysql_webase
        while ! command -v python3.8 &>/dev/null; do
            LOG_ERROR " 😊推荐使用Python3.8版本,如果你后面学习不想出现bug的话"
            LOG_ERROR "请安装 Python 3.8，输入 3.8！"
            install_python
        done
        pip3.8 install pymysql
        python3.8 deploy.py installAll
    else
        LOG_INFO "正在帮你初始化安装"
        cd "$dir" && \
        unzip webase-deploy.zip && cd webase-deploy && \
        # sed -i "s/localhost/127.0.0.1/g" common.properties && \
        sed -i "s/dbUsername/root/g" common.properties && \
        sed -i "s/dbPassword/123456/g" common.properties && \
        sed -i "s/=3306/=23306/g" common.properties
        sed -i "s//data/app/nodes/127.0.0.1/"$dir/webase-deploy"/g" common.properties
        install_docker_env
        docker run -d --name mysql_webase -e MYSQL_ROOT_PASSWORD=123456 -p 23306:3306 mysql:5.6
        docker start mysql_webase
        while ! command -v python3.8 &>/dev/null; do
            LOG_ERROR " 😊推荐使用Python3.8版本,如果你后面学习不想出现bug的话"
            LOG_ERROR "请安装 Python 3.8，输入 3.8！"
            install_python
        done
        pip3.8 install pymysql
        python3.8 deploy.py installAll
    fi
    clear
    echo -e "\033[32m
                ============================================================
                WeBASE启动成功！
                默认网站地址： IP:5000
                默认账号：admin
                默认密码：Abcd1234
                ============================================================
    \033[0m"
    return $is_return
}

# start_4fisco(){
#         echo "启动节点"
#         cd ~/fisco && tar zxvf   fisco-bcos.tar.gz
#         echo -e "\033[32m🥳输入节点配置信息,直接回车则按照默认的进行搭建node链"
#         read -p "p2p_port(DEFAULT 30300): " p2p_port
#         read -p "channel_port(DEFAULT 20200): " channel_port
#         read -p "jsonrpc_port(DEFAULT 8545): " jsonrpc_port
#          if [ -z $p2p_port ]; then
#             p2p_port=30300
#         fi
#          if [ -z $channel_port ]; then
#             channel_port=20200
#         fi
#          if [ -z $jsonrpc_port ]; then
#             jsonrpc_port=8545
#         fi
#         channel_port_2=$(echo "$channel_port" | awk '{$1=$1};1' | tr -d ' ' | awk '{print $0+1}')
#         cd ~/fisco && bash build_chain.sh -l 127.0.0.1:4 -p $p2p_port,$channel_port,$jsonrpc_port -e ./fisco-bcos && \
#         tar zxvf console.tar.gz && \
#         unzip webase-front.zip && \
#         bash nodes/127.0.0.1/start_all.sh && \
#         cp console/conf/config-example.toml console/conf/config.toml && \
#         sed -i "s/20200/$channel_port/g" console/conf/config.toml && \
#         sed -i "s/20201/$channel_port_2/g" console/conf/config.toml && \
#         cp nodes/127.0.0.1/sdk/* console/conf/ && \
#         cp nodes/127.0.0.1/sdk/*  webase-front/conf/
#         cd ~/fisco/webase-front/ && bash start.sh
# }
start_4fisco_front() {
    target_dir=$1
    echo "启动 $target_dir 下的节点"
    cd "$target_dir"
    if [ -d "$target_dir/nodes" ]; then
        echo "链已经存在,正在帮你开启中....."
        cd "$target_dir" && \
        bash nodes/127.0.0.1/start_all.sh
        if [[ ! -d "$(eval echo "$target_dir/webase-front")" ]]; then
            unzip webase-front.zip && \
            cp -r nodes/127.0.0.1/sdk/* webase-front/conf/
        fi
        cd "webase-front/" && bash start.sh
    else
        echo "链不存在,正在帮你使用部署....."
        custom_4fisco_front $target_dir
    fi
}
custom_4fisco_front() {
    local dir=$1
    echo "安装节点至: $dir "
    cd $(eval echo $dir) 
    tar zxvf fisco-bcos.tar.gz
    LOG_INFO "🥳输入节点配置信息,直接回车则按照默认的进行搭建node链"
    read -p "[1/3]> p2p_port(DEFAULT 30300): " p2p_port
    read -p "[2/3]> channel_port(DEFAULT 20200): " channel_port
    read -p "[3/3]> jsonrpc_port(DEFAULT 8545): " jsonrpc_port
    if [ -z $p2p_port ]; then
        p2p_port=30300
    fi
    if [ -z $channel_port ]; then
        channel_port=20200
    fi
    if [ -z $jsonrpc_port ]; then
        jsonrpc_port=8545
    fi
    channel_port_2=$(echo "$channel_port" | awk '{$1=$1};1' | tr -d ' ' | awk '{print $0+1}')
    cd $(eval echo $dir) 
     bash build_chain.sh -l 127.0.0.1:4 -p $p2p_port,$channel_port,$jsonrpc_port -e ./fisco-bcos
    # cd "$dir" && bash build_chain.sh -l 127.0.0.1:4 -p 30300,20200,8545 -e ./fisco-bcos && \
    tar zxvf console.tar.gz && \
    unzip webase-front.zip && \
    bash nodes/127.0.0.1/start_all.sh && \
    cp console/conf/config-example.toml console/conf/config.toml && \
    sed -i "s/20200/$channel_port/g" console/conf/config.toml && \
    sed -i "s/20201/$channel_port_2/g" console/conf/config.toml && \
    cp nodes/127.0.0.1/sdk/* console/conf/ && \
    cp nodes/127.0.0.1/sdk/* webase-front/conf/ && \
    cd "webase-front/" && bash start.sh
}

node_cert() {
    
    local dir="$1"
    local node_name="$2"
    echo "开始扩容节点！在 $dir 文件夹下，节点名为 $node_name"
    last_node_config_file=$(ls -t1 "$dir"/nodes/127.0.0.1/*/config.ini | head -n1)                                 # 获取最后一个节点的配置文件路径
    last_channel_port=$(sed -n 's/channel_listen_port=\([0-9]\+\)/\1/p' "$last_node_config_file")                  # 获取最后一个节点的 channel_listen_port
    last_jsonrpc_port=$(sed -n 's/jsonrpc_listen_port=\([0-9]\+\)/\1/p' "$last_node_config_file")                  # 获取最后一个节点的 jsonrpc_listen_port
    # listen_port=$(sed -n 's/listen_port=\([0-9]\+\)/\1/p' "$last_node_config_file")
    listen_port=$(awk -F "=" '/listen_port/ {gsub(/ /,"",$2); port=$2} END {print port}' "$last_node_config_file") # 获取最后一个节点的 jsonrpc_listen_port
    last_node_dir=$(dirname "$last_node_config_file")
    
    cd "$dir" && \
    bash gen_node_cert.sh -c nodes/cert/agency -o "$node_name" && \
    cp "$last_node_dir"/config.ini "$last_node_dir"/start.sh "$last_node_dir"/stop.sh "$node_name/" && \
    cp $last_node_dir/conf/group.* "$node_name/conf/"
    mv "$node_name" "nodes/127.0.0.1/" && \
    cd "nodes/127.0.0.1/" && \
    config_file="$node_name/config.ini" && \
    
    # echo "端口： $last_channel_port $last_jsonrpc_port  $listen_port"
    new_channel_port=$(echo "$last_channel_port" | awk '{$1=$1};1' | tr -d ' ' | awk '{print $0+1}')
    new_jsonrpc_port=$(echo "$last_jsonrpc_port" | awk '{$1=$1};1' | tr -d ' ' | awk '{print $0+1}')
    new_listen_port=$(echo "$listen_port" | awk '{$1=$1};1' | tr -d ' ' | awk '{print $0+1}')
    echo "新端口 channel_listen_port:$new_channel_port jsonrpc_listen_port:$new_jsonrpc_port P2P:$new_listen_port"
    
    node_num=$(echo $node_name | grep -o '[0-9]*$')
    node_num_last=$(expr "$node_num" - 1)
    # sed -i "/node.$node_num_last=127\.0\.0\.1:$listen_port/ s/$/    node.$node_num=127.0.0.1:$new_listen_port/" "$config_file" # 在 [p2p] 部分添加新节点的信息
    # sed -i "s/channel_listen_port=$last_channel_port/channel_listen_port=$new_channel_port/" "$config_file" # 更新 channel_listen_port
    # sed -i "s/jsonrpc_listen_port=$last_jsonrpc_port/jsonrpc_listen_port=$new_jsonrpc_port/" "$config_file" # 更新 jsonrpc_listen_port
    sed -Ei "s/(listen_port=)[^ ]*/\1$new_listen_port/" "$config_file"
    sed -Ei "s/(channel_listen_port=)[^ ]*/\1$new_channel_port/" "$config_file"
    sed -Ei "s/(jsonrpc_listen_port=)[^ ]*/\1$new_jsonrpc_port/" "$config_file"
    sed -i "/node.$node_num_last=127\.0\.0\.1:$listen_port/ s/$/\n    node.$node_num=127.0.0.1:$new_listen_port/" "$config_file"
    
    bash "$node_name/start.sh"
    clear
    LOG_INFO "  😆正在输出连接信息,20秒后自动关闭,请稍等  "
    timeout 20s tail -f $node_name/log/log* | grep 'connected count'
    LOG_INFO "  😊正在输出共识信息,15秒后自动关闭,请稍等  "
    timeout 15s tail -f $node_name/log/log* | grep '+++'
    LOG_INFO " 😂如果不出意外你应该看不到共识信息，因为需要你自己到console中添加(addSealer nodeid)  "
    LOG_INFO " 🐷注: 正常情况下你是可以看到新节点的连接信息输出，但是没有共识信息输出"
    LOG_INFO "  扩容节点完成！
    ==========================================================
    新节点的信息：
    name: $node_name
    jsonrpc_listen_port: $new_jsonrpc_port
    channel_listen_port: $new_channel_port
    P2P: $new_listen_port
    "
}

# 启动data_export
data_export() {
    LOG_ERROR "输入fisco文件主目录,例如: /root/fisco "
    while true; do
        read -p "[1/2]> 请输入fisco文件主目录 : " fisco_dir
        if [ -z "$fisco_dir" ]; then
            LOG_ERROR "路径不能为空，请重新输入！"
        else
            if [ -d "$fisco_dir" ]; then
                break
            else
                LOG_ERROR "路径不存在，请重新输入！"
            fi
        fi
    done
    
    cd "$fisco_dir"
    bash "nodes/127.0.0.1/start_all.sh"
    curl -#LO https://gitee.com/WeBankBlockchain/Data-Export/attach_files/679385/download/data-export-1.7.2.tar.gz && tar -xzvf data-export-1.7.2.tar.gz && cd data-export-docker
    mysqlexist=$(docker inspect --format '{{.State.Running}}' mysql_data_exprt)
    if [ "${mysqlexist}" != "true" ]; then
        docker run -p 3307:3306 --name mysql_data_exprt -e MYSQL_ROOT_PASSWORD=123456 -e MYSQL_DATABASE=data_export -d mysql:5.6
        if [ ! $? -eq 0 ]; then
            docker start mysql_data_exprt
        fi
    fi
    local_ip=$(ifconfig -a | grep inet | grep -v 127.0.0.1 | grep -v inet6 | awk 'NR>1{print $2}' | tr -d "addr:")
    cp -f "$fisco_dir/nodes/127.0.0.1/sdk/"* "./config/"
    LOG_ERROR "请输入你的ip地址,例如: $local_ip"
    read -p "[2/2]> 请输入你的Linux系统ip地址: " ipaddr
    sed -i "s/127.0.0.1:3307/$ipaddr:3307/" "./config/application.properties"
    sed -i "s/system.grafanaEnable=false/system.grafanaEnable=true/" "./config/application.properties"
    docker run -d -p 3001:3000 --name=grafana grafana/grafana
    if [ ! $? -eq 0 ]; then
        docker start grafana
    fi
    bash build_export.sh
}
listen_nodes() {
    while true;
    do
        a=$(ps -ef | grep -v grep | grep fisco-bcos | wc -l)
        if [ $a -gt 0 ]; then
            LOG_INFO "Success: nodes 节点运行正常"
        else
            LOG_ERROR "error: nodes 节点进程数量小于0"
        fi
        sleep 3
    done
}
go_install(){
    cd /usr/local/
    # wget https://dl.google.com/go/go1.20.linux-amd64.tar.gz
    wget https://mirrors.aliyun.com/golang/go1.21.0.linux-amd64.tar.gz
    
    # tar -C /usr/local/ -xzf go1.20.linux-amd64.tar.gz
    tar -C /usr/local/ -xzf go1.21.0.linux-amd64.tar.gz
    
    echo 'export GOROOT=/usr/local/go'>>/etc/profile
    echo 'export PATH=$PATH:$GOROOT/bin'>>/etc/profile
    echo 'export GOPATH=/work'>>/etc/profile
    source /etc/profile
    go env -w  GOPROXY=https://goproxy.cn,direct
    cd ~
}
# 输出环境信息
print_environment_info() {
    LOG_INFO "========================================="
    LOG_INFO " ✔✔✔ 查看当前的工作目录环境包"
    # 输出工作目录文件列表
    ls -ll $target_dir | awk 'NR>1{print $NF}'
    LOG_INFO "========================================="
    # 获取Docker版本
    docker_version=$(docker -v)
    java_version=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
    docker_compose_version=$(docker-compose -v)
    
    # 获取本机IP
    local_ip=$(ifconfig -a | grep inet | grep -v 127.0.0.1 | grep -v inet6 | awk 'NR>1{print $2}' | tr -d "addr:")
    source /etc/os-release
    user_login=$(whoami)
    pwd_dir=$(pwd)
    echo -e "\033[32m
        🔋   当前系统环境：
    ============================================================
    ✔✔✔  当前系统为: $ID $VERSION_ID
    ✔✔✔  当前的IP地址: $local_ip
    ✔✔✔  当前的登录用户: $user_login
    ✔✔✔  当前的环境工作目录: $pwd_dir
    ✔✔✔ NVM仓库: http://npm.taobao.org/mirrors/node
    ✔✔✔ WeBASE-Front: $local_ip:5002/WeBASE-Front
    ✔✔✔ Docker版本: $docker_version
    ✔✔✔ Docker-Compose版本: $docker_compose_version
    ✔✔✔ Java版本: $java_version
    ✔✔✔ 在线Remix  $local_ip:8080
    ============================================================
    =          FISCO BCOS全家桶开发者环境
    =            官网：https://nb.sb
    =                by : 戏人看戏😁🫵
    =        脚本适配于 主流 Linux 如：ubuntu和centos
    =        脚本编写于 ubuntu 18 和 centOS 7.6
    ============================================================
    \033[0m"
}

# 主菜单
show_menu() {
    content=$(wget --no-check-certificate -qO- https://nb.sb/shell/version.txt)
    # echo "$content"
    echo -e "\033[32m
*************************************************************************************************************************
*\t1) 部署FISCO BCOS 2.8的环境包并启动WeBASE-Front  2) 部署FISCO BCOS 3.1的环境包并启动WeBASE-Front \t\t*
*\t3) 开启在线Remix IDE          \t\t\t 4) 开启指定路径下的FISCO BCOS 链和WeBASE-Front \t\t*
*\t5) 安装并启动指定路径下的 WeBASE  \t\t 6) 扩容节点 \t\t\t\t\t\t\t*
*\t7) 安装Docker相关环境  \t\t\t\t 8) 安装Python相关环境  \t\t\t\t\t*
*\t9) 安装nodejs和nvm    \t\t\t\t 10) 安装caliper     \t\t\t\t\t\t*
*\t11) 安装Java相关环境\t\t\t    \t 12) 安装Go lang环境\t\t\t\t\t\t*
*\t13) 启动Grafana和Data-Export\t\t\t 14) 停止系统中所有的FISCO-BCOS链和WeBASE-Front\t\t\t*
*\t15) 监控node节点运行状态\t\t\t 16) 监控WeBASE-WEB运行状态\t\t\t\t\t*
*\t17) 升级此脚本至最新版\t\t\t\t 0.  输入0查看帮助文档\t\t\t\t\t\t*
    *************************************************************************************************************************\033[0m"
    # 1) 部署FISCO BCOS 2.8的环境包并启动WeBASE-Front
    # 2) 部署FISCO BCOS 3.1的环境包并启动WeBASE-Front
    # 3) 开启在线Remix IDE
    # 4) 开启指定路径下的FISCO BCOS 链和WeBASE-Front
    # 5) 安装并启动指定路径下的 WeBASE
    # 6) 扩容节点
    # 7) 安装Docker相关环境
    # 8) 安装Python相关环境
    # 9) 安装nodejs和nvm
    # 10) 安装caliper
    # 11) 安装Java相关环境
    # 12) 输入12查看帮助文档
    # 13) 启动Grafana和Data-Export
    # 14) 停止系统中所有的fisco-bcos链和webase-front
    # 15) 监控node节点运行状态
    # 16) 监控WeBASE-WEB运行状态
    echo -e "\033[32m
    ============================
    注：使用的时候请直接拉取当前最新版脚本，以确保安装过程的正确，建议直接使用这行命令
    当前版本：4.3
   $YELLOW 最新版：$content $NC
    =      当前版本的更新时间 : 2023-12-1 9:39
    安装命令最新版本命令：
    wget --no-check-certificate  -O all.sh https://nb.sb/shell/all.sh &&  source all.sh
	调用方法： source all.sh 或 bash all.sh
    ============================
    \033[0m"
}

# 帮助信息
show_help() {
    echo -e "\033[32m
    ==================================================
    =                                                =
    =          使用文档 一键部署FISCO环境            =
    =                                                =
    ==================================================
    1. source all.sh
    2. chmod +x all.sh && . all.sh
    描述:
        1. 输入1默认部署FISCO BCOS 2.8的环境包并启动WeBASE-Front,可以按照提示输入安装路径，不输入则使用默认安装路径
        2. 输入2部署FISCO BCOS 3.1的环境包并启动WeBASE-Front
        3. 输入3开启在线Remix IDE
        4. 输入4启动指定路径下的FISCO BCOS 链和WeBASE-Front,需要已经安装过(也就是部署过FISCO BCOS 基础环境包)了才可以使用
        5. 输入5安装并启动指定路径下的 WeBASE，需要安装过基础环境包(或路径下有webase-deploy压缩包或文件可以使用此命令进行安装或启动)
        6. 扩容节点，需要有已经启动了的节点，输入指定的节点目录，按照提示输出端口等信息进行扩容节点
        7. 安装Docker以及docker-compose相关环境
        8. 安装Python相关环境，按照提示输入即可安装指定的python版本
        9. 安装nodejs和nvm
        10. 安装caliper
        11. 安装Java相关环境
        12. 输入12安装go lang
        13. 启动Grafana和Data-Export
        14. 停止系统中所有的fisco-bcos链和webase-front
        15. 监控node节点运行状态
    	16. 监控WeBASE-WEB运行状态
   👉 🤡 👈 作者一言：没有什么好吊的，站在巨人肩膀上罢了
    \033[0m"
    
    LOG_ERROR "有问题或者bug可以及时向作者反馈,【看到邮件后】当天更新。email：svip@nb.sb"
    echo -e "只需要简单的输入几个名称，如果你默认使用提示中默认的内容可以直接 按 $YELLOW Enter 回车键 $none"
}

# 安装初始化
install_init() {
    stop_firewall
    install_dependencies
    install_docker_env
}
install_caliper() {
    read -p "是否需要安装nvm依赖项？[Y/n]: " install
    if [[ ${install,,} == "y" || ${install,,} == "yes" ]]; then
        echo "开始安装nvm依赖项......"
        install_nodejs_nvm
    else
        echo "跳过安装nvm依赖项。"
    fi
    curl -o- "https://nb.sb/shell/caliper.sh" | bash
}
# 选择安装FISCO BCOS或开启Remix IDE
select_install_option() {
    while true; do
        
        print_environment_info
        show_menu
        read -p "请输入选项(DEFAULT 1):" choice
        if [ -z $choice ]; then
            choice=1
        fi
        case $choice in
            1)
                install_init
                read -p "输入需要安装的 FISCO BCOS 目录(默认为 ~/fisco): " dir
                if [["${dir,,}" == "$HOME/fisco" || "$dir" == "/root/fisco" ]]; then
                    target_dir=~/fisco
                    dir=~/fisco
                else
                    target_dir=$(eval echo $dir)
                fi
                install_fisco_bcos "$target_dir"
                clear
                read -p "是否需要启动安装的nodes和webase-front [y/n] : " yy
                if [[ ${yy,,} == "n" ]]; then
                    cd $dir
                    LOG_INFO "跳过启动步骤"
                else
                    read -p "启动指定目录下的nodes和webase-front(默认目录$dir):" dirs
                    if [[  "${dirs,,}" == "~/fisco" || "$dirs" == "/root/fisco" ]]; then
                        custom_4fisco_front "$(eval echo ~/fisco)"
                    else
                        custom_4fisco_front "$dir"
                    fi
                fi
                clear
                print_environment_info
                break
            ;;
            2)
                install_init
                install_fisco_bcos_30
                custom_4fisco_front "$(eval echo ~/fisco)"
                clear
                print_environment_info
                break
            ;;
            3)
                install_remix
                echo "已开启在线Remix服务"
                break
            ;;
            4)
                read -p "启动指定目录下的nodes和webase-front(默认目录 ~/fisco):" dir
                if [[ -z "$dir" || "${dir,,}" == "$HOME/fisco" || "$dir" == "/root/fisco" ]]; then
                    start_4fisco_front "$(eval echo $HOME/fisco)"
                else
                    if [ ! -d $(eval echo $dir) ]; then
                        LOG_ERROR "目标目录不存在: $(eval echo $dir)"
                        return 1
                    fi
                    start_4fisco_front $(eval echo $dir)
                fi
                echo "已开启FISCO BCOS 链和WeBASE-Front服务"
                break
            ;;
            5)
                install_init
                read -p "[1/3]>输入需要安装的 FISCO BCOS 目录(默认为 ~/fisco): " dir
                if [[ -z "$dir" || "${dir,,}" == "~/fisco" || "$dir" == "/root/fisco" ]]; then
                    target_dir="$(eval echo ~/fisco)"
                    dir="$(eval echo ~/fisco)"
                else
                    target_dir=$(eval echo $dir)
                fi
                if [ ! -d $(eval echo $dir) ]; then
                    LOG_ERROR "目标目录不存在: $(eval echo $dir)"
                    return 1
                fi
                read -p "[2/3]>启动指定目录下的WeBASE(默认目录 $dir):" dirs
                if [[ "${dirs,,}" == "~/fisco" ]]; then
                    dir="$(eval echo ~/fisco)"
                else
                    dir="$(eval echo $dir)"
                fi
                start_webase $dir
                break
            ;;
            6)
                read -p "启动指定目录下的nodes和webase-front(默认目录 ~/fisco):" dir
                if [[ -z "$dir" || "${dir,,}" == "~/fisco" ]]; then
                    dir="$(eval echo ~/fisco)"
                else
                    dir="$(eval echo $dir)"
                fi
                if [ ! -d $(eval echo $dir) ]; then
                    LOG_ERROR "目标目录不存在: $(eval echo $dir)"
                    return 1
                fi
                while true; do
                    read -p "请输入新创建的节点文件名(例如:node4): " node_name
                    if [ -z "$node_name" ]; then
                        LOG_ERROR "必须输入节点文件名！"
                    else
                        break
                    fi
                done
                
                dir=$(eval echo $dir)
                node_cert "$dir" "$node_name"
            ;;
            7)
                LOG_INFO "正在安装docker环境"
                install_docker_env
            ;;
            8)
                install_python
            ;;
            9)
                install_nodejs_nvm
            ;;
            10)
                install_caliper
            ;;
            11)
                install_java
            ;;
            0)
                show_help
                break
            ;;
            12)
                go_install
            ;;
            13)
                data_export
                LOG_ERROR "Grafana端口网址为：$local_ip:3001"
                LOG_INFO "Grafana默认账号密码都为:admin"
            ;;
            14)
                ps -ef | grep -v grep | grep "fisco-bcos" | awk '{print $2}' | xargs kill -9
                ps -ef | grep -v grep | grep "webase-front" | awk '{print $2}' | xargs kill -9
                LOG_ERROR "已停止所有的fisco-bcos链和webase-front"
            ;;
            15)
                listen_nodes
            ;;
            16)
                read -p "输入需要监控的WeBASE路径(默认目录 ~/fisco/webase-deploy):" wb_path
                if [[ -z "$wb_path" || "${wb_path,,}" == "~/fisco/webase-deploy" ]]; then
                    wb_path="$(eval echo ~/fisco/webase-deploy)"
                else
                    wb_path="$(eval echo $wb_path)"
                fi
                while true;
                do
                    # WeBase-Front子系统测试
                    webase_front $wb_path
                    # WeBase-Node-Msg子系统测试
                    sleep 3
                    webase_node_mgr $wb_path
                    # WeBase-Sign子系统测试
                    sleep 3
                    webase_sign $wb_path
                    # WeBase-Web子系统测试
                    sleep 3
                    webase_web $wb_path
                    sleep 3
                done
                
                
            ;;
            17)
                wget --no-check-certificate  -O all.sh https://nb.sb/shell/all.sh &&  source all.sh
            ;;
            *)
                show_menu
            ;;
        esac
    done
}
if [ $(id -u) != 0 ]; then
    LOG_ERROR "记住！你是站在巨人的肩膀之上！"
    LOG_ERROR "👉 🤡 👈 ✔✔✔ 请使用root用户运行此脚本"
    return
    elif [[ $1 = "--help" ]] || [[ $1 = "-h" ]];then
    show_help
    return
else
    # 检查所需命令是否存在
    check_command curl
    check_command wget
    check_command git
    check_command unzip
    # check_command python3
    # check_command java
    # check_command docker
    select_install_option
fi


