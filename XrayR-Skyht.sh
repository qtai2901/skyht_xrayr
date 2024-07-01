clear
echo "   1. Cài đặt"
echo "   2. update"
echo "   3. thêm node"
read -p "  Vui lòng chọn một số và nhấn Enter (Enter theo mặc định Cài đặt)  " num
[ -z "${num}" ] && num="1"


install(){
  clear
  read -p " Nhập domain web (không cần https://):" api_host
    [ -z "${api_host}" ] && api_host=0
    echo "--------------------------------"
  echo "Bạn đã chọn https://${api_host}"
  echo "--------------------------------"
  #key web
  read -p " Nhập key web :" api_key
    [ -z "${api_key}" ] && api_key=0
  echo "--------------------------------"
  echo "Bạn đã chọn https://${api_host}"
  echo "--------------------------------"

  pre_install
  
}
	
pre_install(){
 clear
	read -p "Nhập số node cần cài và nhấn Enter (tối đa 2 node): " n
	 [ -z "${n}" ] && n="1"
    a=0
    if [ "$n" -ge 2 ] ; then 
    n="2"
fi
  while [ $a -lt $n ]
 do
 echo " node số $((a+1))"


  echo -e "[1] Vmess"
  echo -e "[2] Vless"
  echo -e "[3] trojan"
  echo -e "[4] Shadowsocks"
  read -p "chọn kiểu node(mặc định là vmess):" NodeType
  if [ "$NodeType" == "1" ]; then
    NodeType="V2ray"
    EnableVless="false"
    info="vmess"
  elif [ "$NodeType" == "2" ]; then
    NodeType="V2ray"
    EnableVless="true"
    info="Vless"
  elif [ "$NodeType" == "3" ]; then
    NodeType="Trojan"
    EnableVless="false"
    info="Trojan"
    elif [ "$NodeType" == "4" ]; then
    NodeType="Shadowsocks"
    EnableVless="false"
    info="Shadowsocks"
  else
    NodeType="V2ray"
    EnableVless="false"
    info="vmess"
  fi
  echo "Bạn đã chọn $info"
  echo "--------------------------------"



  #node id
    read -p " ID nút (Node_ID):" node_id
  [ -z "${node_id}" ] && node_id=0
  echo "-------------------------------"
  echo -e "Node_ID: ${node_id}"
  echo "-------------------------------"
  

 config
  a=$((a+1))
done
}



#clone node
clone_node(){
  clear
  read -p " Nhập domain web (không cần https://):" api_host
    [ -z "${api_host}" ] && api_host=0
    echo "--------------------------------"
  echo "Bạn đã chọn https://${api_host}"
  echo "--------------------------------"
  #key web
  read -p " Nhập key web :" api_key
    [ -z "${api_key}" ] && api_key=0
  echo "--------------------------------"
  echo "Bạn đã chọn https://${api_host}"
  echo "--------------------------------"

  
  echo -e "[1] Vmess"
  echo -e "[2] Vless"
  echo -e "[3] trojan"
  echo -e "[4] Shadowsocks"
  read -p "chọn kiểu node(mặc định là vmess):" NodeType
  if [ "$NodeType" == "1" ]; then
    NodeType="V2ray"
    EnableVless="false"
    info="vmess"
  elif [ "$NodeType" == "2" ]; then
    NodeType="V2ray"
    EnableVless="true"
    info="Vless"
  elif [ "$NodeType" == "3" ]; then
    NodeType="Trojan"
    EnableVless="false"
    info="Trojan"
    elif [ "$NodeType" == "4" ]; then
    NodeType="Shadowsocks"
    EnableVless="false"
    info="Shadowsocks"
  else
    NodeType="V2ray"
    EnableVless="false"
    info="vmess"
  fi
  echo "Bạn đã chọn $info"
  echo "--------------------------------"





  #node id
    read -p " ID nút (Node_ID):" node_id
  [ -z "${node_id}" ] && node_id=0
  echo "-------------------------------"
  echo -e "Node_ID: ${node_id}"
  echo "-------------------------------"
 

 config
#   a=$((a+1))
#   done
}







config(){
cd /etc/XrayR
cat >>config.yml<<EOF
  - PanelType: "V2board" # Panel type:  NewV2board, V2board
    ApiConfig:
      ApiHost: "https://$api_host"
      ApiKey: "$api_key"
      NodeID: $node_id
      NodeType: $NodeType # Node type: V2ray, Shadowsocks, Trojan, Shadowsocks-Plugin
      Timeout: 30 # Timeout for the api request
      EnableVless: $EnableVless  # Enable Vless for V2ray Type
      VlessFlow: "none" # Only support vless
      SpeedLimit: 0 # Mbps, Local settings will replace remote settings, 0 means disable
      DeviceLimit: 0 # Local settings will replace remote settings, 0 means disable
      RuleListPath: # /etc/XrayR/rulelist Path to local rulelist file
      DisableCustomConfig: false # disable custom config for sspanel
    ControllerConfig:
      DisableSniffing: true
      ListenIP: 0.0.0.0 # IP address you want to listen
      SendIP: 0.0.0.0 # IP address you want to send pacakage
      UpdatePeriodic: 60 # Time to update the nodeinfo, how many sec.
      EnableDNS: false # Use custom DNS config, Please ensure that you set the dns.json well
      DNSType: AsIs # AsIs, UseIP, UseIPv4, UseIPv6, DNS strategy
      EnableProxyProtocol: false # Only works for WebSocket and TCP
      AutoSpeedLimitConfig:
        Limit: 0 # Warned speed. Set to 0 to disable AutoSpeedLimit (mbps)
        WarnTimes: 0 # After (WarnTimes) consecutive warnings, the user will be limited. Set to 0 to punish overspeed user immediately.
        LimitSpeed: 0 # The speedlimit of a limited user (unit: mbps)
        LimitDuration: 0 # How many minutes will the limiting last (unit: minute)
      GlobalDeviceLimitConfig:
        Enable: false # Enable the global device limit of a user
        RedisAddr: 127.0.0.1:6379 # The redis server address
        RedisPassword: YOUR PASSWORD # Redis password
        RedisDB: 0 # Redis DB
        Timeout: 5 # Timeout for redis request
        Expiry: 60 # Expiry time (second)
      EnableFallback: false # Only support for Trojan and Vless
      FallBackConfigs:  # Support multiple fallbacks
        - SNI: # TLS SNI(Server Name Indication), Empty for any
          Alpn: # Alpn, Empty for any
          Path: # HTTP PATH, Empty for any
          Dest: 80 # Required, Destination of fallback, check https://xtls.github.io/config/features/fallback.html for details.
          ProxyProtocolVer: 0 # Send PROXY protocol version, 0 for disable
      DisableLocalREALITYConfig: false  # disable local reality config
      EnableREALITY: false # Enable REALITY
      REALITYConfigs:
        Show: false # Show REALITY debug
        Dest: www.smzdm.com:443 # Required, Same as fallback
        ProxyProtocolVer: 0 # Send PROXY protocol version, 0 for disable
        ServerNames: # Required, list of available serverNames for the client, * wildcard is not supported at the moment.
          - www.smzdm.com
        PrivateKey: YOUR_PRIVATE_KEY # Required, execute './xray x25519' to generate.
        MinClientVer: # Optional, minimum version of Xray client, format is x.y.z.
        MaxClientVer: # Optional, maximum version of Xray client, format is x.y.z.
        MaxTimeDiff: 0 # Optional, maximum allowed time difference, unit is in milliseconds.
        ShortIds: # Required, list of available shortIds for the client, can be used to differentiate between different clients.
          - ""
          - 0123456789abcdef
      CertConfig:
        CertMode: file # Option about how to get certificate: none, file, http, tls, dns. Choose "none" will forcedly disable the tls config.
        CertDomain: "1.1.1.1" # Domain to cert
        CertFile: /etc/XrayR/vpndata.crt # Provided if the CertMode is file
        KeyFile: /etc/XrayR/vpndata.key
        Provider: alidns # DNS cert provider, Get the full support list here: https://go-acme.github.io/lego/dns/
        Email: test@me.com
        DNSEnv: # DNS ENV option used by DNS provider
          ALICLOUD_ACCESS_KEY: aaa
          ALICLOUD_SECRET_KEY: bbb
EOF


 }

case "${num}" in
1) bash <(curl -Ls https://raw.githubusercontent.com/qtai2901/skyht_xrayr/main/install.sh)
openssl req -newkey rsa:2048 -x509 -sha256 -days 365 -nodes -out /etc/XrayR/vpndata.crt -keyout /etc/XrayR/vpndata.key -subj "/C=JP/ST=Tokyo/L=Chiyoda-ku/O=Google Trust Services LLC/CN=google.com"
cd /etc/XrayR
  cat >config.yml <<EOF
Log:
  Level: none # Log level: none, error, warning, info, debug 
  AccessPath: # /etc/XrayR/access.Log
  ErrorPath: # /etc/XrayR/error.log
DnsConfigPath: # /etc/XrayR/dns.json # Path to dns config, check https://xtls.github.io/config/dns.html for help
RouteConfigPath: # /etc/XrayR/route.json # Path to route config, check https://xtls.github.io/config/routing.html for help
InboundConfigPath: # /etc/XrayR/custom_inbound.json # Path to custom inbound config, check https://xtls.github.io/config/inbound.html for help
OutboundConfigPath: # /etc/XrayR/custom_outbound.json # Path to custom outbound config, check https://xtls.github.io/config/outbound.html for help
ConnectionConfig:
  Handshake: 4 # Handshake time limit, Second
  ConnIdle: 30 # Connection idle time limit, Second
  UplinkOnly: 2 # Time limit when the connection downstream is closed, Second
  DownlinkOnly: 4 # Time limit when the connection is closed after the uplink is closed, Second
  BufferSize: 64 # The internal cache size of each connection, kB
Nodes:
EOF

install
cd /root
xrayr start
 ;;
 2) cd /etc/XrayR
cat >config.yml <<EOF
Log:
  Level: none # Log level: none, error, warning, info, debug 
  AccessPath: # /etc/XrayR/access.Log
  ErrorPath: # /etc/XrayR/error.log
DnsConfigPath: # /etc/XrayR/dns.json # Path to dns config, check https://xtls.github.io/config/dns.html for help
RouteConfigPath: # /etc/XrayR/route.json # Path to route config, check https://xtls.github.io/config/routing.html for help
InboundConfigPath: # /etc/XrayR/custom_inbound.json # Path to custom inbound config, check https://xtls.github.io/config/inbound.html for help
OutboundConfigPath: # /etc/XrayR/custom_outbound.json # Path to custom outbound config, check https://xtls.github.io/config/outbound.html for help
ConnectionConfig:
  Handshake: 4 # Handshake time limit, Second
  ConnIdle: 30 # Connection idle time limit, Second
  UplinkOnly: 2 # Time limit when the connection downstream is closed, Second
  DownlinkOnly: 4 # Time limit when the connection is closed after the uplink is closed, Second
  BufferSize: 64 # The internal cache size of each connection, kB
Nodes:
EOF

install
cd /root
xrayr restart
 ;;
 3) cd /etc/XrayR
 clone_node
 cd /root
  xrayr restart
;;
esac
