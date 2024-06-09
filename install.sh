#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

cur_dir=$(pwd)

# check root
    [[ $EUID -ne 0 ]] && echo -e "${red}Lưu Ý：${plain} Bạn Cần Chạy VPS Quyền ROOT Mới Sử Dụng Được！\n" && exit 1

# check os
if [[ -f /etc/redhat-release ]]; then
    release="centos"
elif cat /etc/issue | grep -Eqi "debian"; then
    release="debian"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
elif cat /proc/version | grep -Eqi "debian"; then
    release="debian"
elif cat /proc/version | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
else
    echo -e "${red}Không tìm thấy phiên bản hệ thống, vui lòng liên hệ với tác giả tập lệnh！${plain}\n" && exit 1
fi

arch=$(arch)

if [[ $arch == "x86_64" || $arch == "x64" || $arch == "amd64" ]]; then
    arch="64"
elif [[ $arch == "aarch64" || $arch == "arm64" ]]; then
    arch="arm64-v8a"
elif [[ $arch == "s390x" ]]; then
    arch="s390x"
else
    arch="64"
    echo -e "${red}Không phát hiện được kiến trúc, sử dụng kiến trúc mặc định: ${arch}${plain}"
fi

echo "Ngành kiến trúc: ${arch}"

if [ "$(getconf WORD_BIT)" != '32' ] && [ "$(getconf LONG_BIT)" != '64' ] ; then
    echo "Phần mềm này không hỗ trợ hệ thống 32 bit (x86), vui lòng sử dụng hệ thống 64 bit (x86_64), nếu phát hiện không chính xác, vui lòng liên hệ với tác giả"
    exit 2
fi

os_version=""

# os version
if [[ -f /etc/os-release ]]; then
    os_version=$(awk -F'[= ."]' '/VERSION_ID/{print $3}' /etc/os-release)
fi
if [[ -z "$os_version" && -f /etc/lsb-release ]]; then
    os_version=$(awk -F'[= ."]+' '/DISTRIB_RELEASE/{print $2}' /etc/lsb-release)
fi

if [[ x"${release}" == x"centos" ]]; then
    if [[ ${os_version} -le 6 ]]; then
        echo -e "${red}Vui lòng sử dụng hệ thống CentOS 7 trở lên！${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"ubuntu" ]]; then
    if [[ ${os_version} -lt 16 ]]; then
        echo -e "${red}Vui lòng sử dụng hệ thống Ubuntu 16 trở lên！${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"debian" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red}Vui lòng sử dụng phiên bản Debian 8 hoặc cao hơn của hệ thống！${plain}\n" && exit 1
    fi
fi

install_base() {
    if [[ x"${release}" == x"centos" ]]; then
        yum install epel-release -y
        yum install wget curl unzip tar crontabs socat -y
    else
        apt update -y
        apt install wget curl unzip tar cron socat -y
    fi
}

# 0: running, 1: not running, 2: not installed
check_status() {
    if [[ ! -f /etc/systemd/system/XrayR.service ]]; then
        return 2
    fi
    temp=$(systemctl status XrayR | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
    if [[ x"${temp}" == x"running" ]]; then
        return 0
    else
        return 1
    fi
}

install_acme() {
    curl https://get.acme.sh | sh
}

install_XrayR() {
    if [[ -e /usr/local/XrayR/ ]]; then
        rm /usr/local/XrayR/ -rf
    fi

    mkdir /usr/local/XrayR/ -p
	cd /usr/local/XrayR/

    # url="https://4gsieure.net/xrayr/XrayR-linux-64.zip"
    # wget -q -N --no-check-certificate -O /usr/local/XrayR/XrayR-linux.zip ${url}
    curl -o XrayR-linux.zip https://domain/XrayR/XrayR-linux-64.zip

    unzip XrayR-linux.zip
    rm XrayR-linux.zip -f
    chmod +x XrayR
    mkdir /etc/XrayR/ -p
    rm /etc/systemd/system/XrayR.service -f
    file="https://domain/XrayR/XrayR.service"
    wget -q -N --no-check-certificate -O /etc/systemd/system/XrayR.service ${file}
    # cp -f XrayR.service /etc/systemd/system/
    systemctl daemon-reload
    systemctl stop XrayR
    systemctl enable XrayR
    echo -e "${green}XrayR Đã Được Cài đặt"
    cp geoip.dat /etc/XrayR/
    cp geosite.dat /etc/XrayR/ 

    if [[ ! -f /etc/XrayR/config.yml ]]; then
        cp config.yml /etc/XrayR/
        echo -e ""
    else
        systemctl start XrayR
        sleep 2
        check_status
        echo -e ""
        if [[ $? == 0 ]]; then
            echo -e "${green}Khởi Chạy Skyht XrayR Thành Công${plain}"
        else
            echo -e "${red}Skyht XrayR Có Thể Không Chạy - Vui Lòng Truy Cập Lệnh XrayR Log Để Biết Thêm Chi Tiết${plain}"
        fi
    fi

    if [[ ! -f /etc/XrayR/dns.json ]]; then
        cp dns.json /etc/XrayR/
    fi
    if [[ ! -f /etc/XrayR/route.json ]]; then
        cp route.json /etc/XrayR/
    fi
    if [[ ! -f /etc/XrayR/custom_outbound.json ]]; then
        cp custom_outbound.json /etc/XrayR/
    fi
    if [[ ! -f /etc/XrayR/custom_inbound.json ]]; then
        cp custom_inbound.json /etc/XrayR/
    fi
    if [[ ! -f /etc/XrayR/rulelist ]]; then
        cp rulelist /etc/XrayR/
    fi
    curl -o /usr/bin/XrayR -Ls https://domain/XrayR/XrayR1.sh
    # cp -f XrayR.sh /usr/bin/XrayR
    chmod +x /usr/bin/XrayR
    ln -s /usr/bin/XrayR /usr/bin/xrayr # 小写兼容
    chmod +x /usr/bin/xrayr
    cd $cur_dir
    rm -f install.sh
    echo -e ""
    echo "--------------[SKYHT]--------------"
    echo "Cách sử dụng tập lệnh quản lý XrayR (tương thích với thực thi xrayr, không phân biệt chữ hoa chữ thường): "
    echo "------------------------------------------"
    echo "XrayR                    - Hiển Thị Menu"
    echo "XrayR start              - Khởi Động XrayR"
    echo "XrayR stop               - Dừng XrayR"
    echo "XrayR restart            - Khởi Động Lại XrayR"
    echo "XrayR status             - Trạng Thái XrayR"
    echo "XrayR enable             - Mở XrayR"
    echo "XrayR disable            - Hủy Bỏ XrayR"
    echo "XrayR log                - Log Xrayr"
    echo "XrayR update             - Cập Nhật XrayR"
    echo "XrayR update x.x.x       - Cập Nhật XrayR Theo Phiên Bản"
    echo "XrayR config             - Hiển Thị Nội Dung XrayR"
    echo "XrayR install            - Cài Đặt XrayR"
    echo "XrayR uninstall          - Xóa XrayR"
    echo "XrayR version            - Phiên Bản XrayR"
    echo "------------------------------------------"
}

echo -e "${green}开始安装${plain}"
install_base
# install_acme
install_XrayR $1