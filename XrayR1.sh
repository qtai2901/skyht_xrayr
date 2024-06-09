#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

version="v1.0.0"

# check root
[[ $EUID -ne 0 ]] && "${red}Lưu Ý：${plain} Bạn Cần Chạy VPS Quyền ROOT Mới Sử Dụng Được！\n" && exit 1
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

confirm() {
    if [[ $# > 1 ]]; then
        echo && read -p "$1 [Mặc định$2]: " temp
        if [[ x"${temp}" == x"" ]]; then
            temp=$2
        fi
    else
        read -p "$1 [y/n]: " temp
    fi
    if [[ x"${temp}" == x"y" || x"${temp}" == x"Y" ]]; then
        return 0
    else
        return 1
    fi
}

confirm_restart() {
    confirm "Có nên khởi động lại XrayR hay không" "y"
    if [[ $? == 0 ]]; then
        restart
    else
        show_menu
    fi
}

before_show_menu() {
    echo && echo -n -e "${yellow}Nhấn Enter để quay lại menu chính: ${plain}" && read temp
    show_menu
}

install() {
    bash <(curl -Ls https://raw.githubusercontent.com/qtai2901/script_xrayr/master/install.sh)
    if [[ $? == 0 ]]; then
        if [[ $# == 0 ]]; then
            start
        else
            start 0
        fi
    fi
}

# update() {
#     if [[ $# == 0 ]]; then
#         echo && echo -n -e "输入指定版本(默认最新版): " && read version
#     else
#         version=$2
#     fi
# #    confirm "本功能会强制重装当前最新版，数据不会丢失，是否继续?" "n"
# #    if [[ $? != 0 ]]; then
# #        echo -e "${red}已取消${plain}"
# #        if [[ $1 != 0 ]]; then
# #            before_show_menu
# #        fi
# #        return 0
# #    fi
#     bash <(curl -Ls https://raw.githubusercontent.com/qtai2901/script_xrayr/master/install.sh) $version
#     if [[ $? == 0 ]]; then
#         echo -e "${green}更新完成，已自动重启 XrayR，请使用 XrayR log 查看运行日志${plain}"
#         exit
#     fi

#     if [[ $# == 0 ]]; then
#         before_show_menu
#     fi
# }

config() {
    echo "XrayR sẽ tự động thử khởi động lại sau khi sửa đổi cấu hình."
    vi /etc/XrayR/config.yml
    sleep 2
    check_status
    case $? in
        0)
            echo -e "Trạng thái XrayR: ${green}đã chạy{plain}"
            ;;
        1)
            echo -e "Chúng tôi phát hiện thấy bạn chưa khởi động XrayR hoặc XrayR không tự động khởi động lại. Bạn có muốn kiểm tra nhật ký không? [Có/không]" && echo
            read -e -p "(Mặc định:y):" yn
            [[ -z ${yn} ]] && yn="y"
            if [[ ${yn} == [Yy] ]]; then
               show_log
            fi
            ;;
        2)
            echo -e "Trạng thái XrayR: ${red}Không chạy{plain}"
    esac
}

uninstall() {
    confirm "Bạn có chắc chắn muốn gỡ cài đặt XrayR không?" ": n"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    systemctl stop XrayR
    systemctl disable XrayR
    rm /etc/systemd/system/XrayR.service -f
    systemctl daemon-reload
    systemctl reset-failed
    rm /etc/XrayR/ -rf
    rm /usr/local/XrayR/ -rf

    echo ""
    echo -e "Quá trình gỡ cài đặt thành công. Nếu bạn muốn xóa tập lệnh này, hãy chạy ${green}rm /usr/bin/XrayR -f${plain} sau khi thoát tập lệnh để xóa tập lệnh."
    echo ""

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

start() {
    check_status
    if [[ $? == 0 ]]; then
        echo ""
        echo -e "${green}XrayR đã chạy và không cần phải khởi động lại. Nếu bạn cần khởi động lại, vui lòng chọn Khởi động lại.${plain}"
    else
        systemctl start XrayR
        sleep 2
        check_status
        if [[ $? == 0 ]]; then
            echo -e "${green}XrayR đã khởi động thành công, vui lòng sử dụng nhật ký XrayR để xem nhật ký đang chạy${plain}"
        else
            echo -e "${red}XrayR có thể không khởi động được, vui lòng sử dụng nhật ký XrayR sau để xem thông tin nhật ký.${plain}"
        fi
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

stop() {
    systemctl stop XrayR
    sleep 2
    check_status
    if [[ $? == 1 ]]; then
        echo -e "${green}XrayR Dừng thành công${plain}"
    else
        echo -e "${red}XrayR không dừng được, có thể do thời gian dừng vượt quá hai giây. Vui lòng kiểm tra thông tin nhật ký sau.${plain}"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

restart() {
    systemctl restart XrayR
    sleep 2
    check_status
    if [[ $? == 0 ]]; then
        echo -e "${green}XrayR đã khởi động lại thành công, vui lòng sử dụng nhật ký XrayR để xem nhật ký đang chạy${plain}"
    else
        echo -e "${red}XrayR có thể không khởi động được, vui lòng sử dụng nhật ký XrayR sau để xem thông tin nhật ký.${plain}"
    fi
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

status() {
    systemctl status XrayR --no-pager -l
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

enable() {
    systemctl enable XrayR
    if [[ $? == 0 ]]; then
        echo -e "${green}XrayR Thiết lập tự động khởi động thành công ${plain}"
    else
        echo -e "${red}XrayR Cài đặt khởi động tự động khởi động không thành công ${plain}"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

disable() {
    systemctl disable XrayR
    if [[ $? == 0 ]]; then
        echo -e "${green}XrayR Hủy khởi động tự động khởi động thành công ${plain}"
    else
        echo -e "${red}XrayR Hủy khởi động tự động khởi động không thành công ${plain}"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

show_log() {
    journalctl -u XrayR.service -e --no-pager -f
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

install_bbr() {
    bash <(curl -L -s https://raw.githubusercontent.com/chiakge/Linux-NetSpeed/master/tcp.sh)
    #if [[ $? == 0 ]]; then
    #    echo ""
    #    echo -e "${green}安装 bbr 成功，请重启服务器${plain}"
    #else
    #    echo ""
    #    echo -e "${red}下载 bbr 安装脚本失败，请检查本机能否连接 Github${plain}"
    #fi

    #before_show_menu
}

update_shell() {
    wget -O /usr/bin/XrayR -N --no-check-certificate https://raw.githubusercontent.com/qtai2901/script_xrayr/master/XrayR.sh
    if [[ $? != 0 ]]; then
        echo ""
        echo -e "${red}Không tải được script, vui lòng kiểm tra xem máy có kết nối được với Github không ${plain}"
        before_show_menu
    else
        chmod +x /usr/bin/XrayR
        echo -e "${green}Kịch bản nâng cấp thành công, vui lòng chạy lại kịch bản.${plain}" && exit 0
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

check_enabled() {
    temp=$(systemctl is-enabled XrayR)
    if [[ x"${temp}" == x"enabled" ]]; then
        return 0
    else
        return 1;
    fi
}

check_uninstall() {
    check_status
    if [[ $? != 2 ]]; then
        echo ""
        echo -e "${red}XrayR đã được cài đặt, vui lòng không cài đặt lại${plain}"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 1
    else
        return 0
    fi
}

check_install() {
    check_status
    if [[ $? == 2 ]]; then
        echo ""
        echo -e "${red}Vui Lòng Cài Đặt XrayR Trước ${plain}"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 1
    else
        return 0
    fi
}

show_status() {
    check_status
    case $? in
        0)
            echo -e "Trạng thái XrayR: ${green} đã chạy ${plain}"
            show_enable_status
            ;;
        1)
            echo -e "Trạng thái XrayR: ${yellow} không chạy ${plain}"
            show_enable_status
            ;;
        2)
            echo -e "Trạng thái XrayR: ${red} chưa được cài đặt ${plain}"
    esac
}

show_enable_status() {
    check_enabled
    if [[ $? == 0 ]]; then
        echo -e "Có tự động khởi động khi khởi động hay không: ${green} Có ${plain}"
    else
        echo -e "Có tự động khởi động khi khởi động hay không: ${red}không{plain}"
    fi
}

show_XrayR_version() {
    echo -n "XrayR 版本："
    /usr/local/XrayR/XrayR -version
    echo ""
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

show_usage() {
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

show_menu() {
    echo -e "
  ${green}XrayR Kịch bản quản lý phụ trợ，${plain}${red}Không áp dụng cho docker${plain}
--- https://github.com/XrayR-project/XrayR ---
  ${green}0.${plain} Thay đổi config
————————————————
  ${green}1.${plain} Cài đặt XrayR
  ${green}2.${plain} Gỡ cài đặt XrayR
————————————————
  ${green}3.${plain} Khởi động XrayR
  ${green}4.${plain} Dừng XrayR
  ${green}5.${plain} Khởi động lại XrayR
  ${green}6.${plain} Trạng thái XrayR
  ${green}7.${plain} Log XrayR 
————————————————
  ${green}8.${plain} Đặt XrayR tự động khởi động khi khởi động
 ${green}9.${plain} Hủy tự động khởi động XrayR khi khởi động
————————————————
 ${green}10.${plain} Cài bbr
 ${green}11.${plain} Kịch bản bảo trì nâng cấp
 "
 #后续更新可加入上方字符串中
    show_status
    echo && read -p "chọn trong [0-11]: " num

    case "${num}" in
        0) config
        ;;
        1) check_uninstall && install
        ;;
        2) check_install && uninstall
        ;;
        3) check_install && start
        ;;
        4) check_install && stop
        ;;
        5) check_install && restart
        ;;
        6) check_install && status
        ;;
        7) check_install && show_log
        ;;
        8) check_install && enable
        ;;
        9) check_install && disable
        ;;
        10) install_bbr
        ;;
        11) check_install && show_XrayR_version
        ;;
        *) echo -e "${red}chọn trong  [0-11]${plain}"
        ;;
    esac
}


if [[ $# > 0 ]]; then
    case $1 in
        "start") check_install 0 && start 0
        ;;
        "stop") check_install 0 && stop 0
        ;;
        "restart") check_install 0 && restart 0
        ;;
        "status") check_install 0 && status 0
        ;;
        "enable") check_install 0 && enable 0
        ;;
        "disable") check_install 0 && disable 0
        ;;
        "log") check_install 0 && show_log 0
        ;;
        "config") config $*
        ;;
        "install") check_uninstall 0 && install 0
        ;;
        "uninstall") check_install 0 && uninstall 0
        ;;
        "version") check_install 0 && show_XrayR_version 0
        ;;
        *) show_usage
    esac
else
    show_menu
fi