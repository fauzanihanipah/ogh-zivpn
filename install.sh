#!/bin/bash
# Zivpn UDP Management Panel - CIAN Edition
# ASCII Style: ZIVPN Thick Lean Left

# Warna
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' 
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
BOLD='\033[1m'

# Fungsi Banner ZIVPN Miring Ke Kiri (Garis Tebal & Patah-Patah)
function banner() {
    clear
    echo -e "${PURPLE}${BOLD}"
    echo "  ________  ___  ___  ___  ________  ________      "
    echo " /_  ___/|/__/|/__/|/__/|/_______/|/_______/|     "
    echo " \/_  |_|/|__|/|__|/|__|/|  ______|/|  ___  |_|     "
    echo "   /  / / /  / / \  \  / /|  |____  |  |/|  | /     "
    echo "  /  /_/_/  /_/_  \  \/ / |  |____|/|  | |  |/      "
    echo " /______/|______/| \___/  |_______/||__| |__|       "
    echo " |______|/|______|/ \__/  |_______|/|__| |__|       "
    echo -e "          ${CYAN}C I A N   M O D   P A N E L${NC}"
    echo -e "${PURPLE}======================================================${NC}"
}

# Fungsi Install (Logic Zahid Islam)
function install_zivpn() {
    banner
    echo -e "${CYAN}Sedang Menginstall Zivpn UDP Service...${NC}"
    sudo apt-get update && sudo apt-get upgrade -y
    sudo apt-get install -y jq curl wget ufw
    
    systemctl stop zivpn.service 1> /dev/null 2> /dev/null
    wget -q https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-amd64 -O /usr/local/bin/zivpn
    chmod +x /usr/local/bin/zivpn
    mkdir -p /etc/zivpn
    
    if [ ! -f /etc/zivpn/config.json ]; then
        wget -q https://raw.githubusercontent.com/zahidbd2/udp-zivpn/main/config.json -O /etc/zivpn/config.json
    fi

    openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 -subj "/C=ID/ST=CIAN/L=CIAN/O=ZIVPN/OU=IT/CN=zivpn" -keyout "/etc/zivpn/zivpn.key" -out "/etc/zivpn/zivpn.crt"
    
    cat <<EOF > /etc/systemd/system/zivpn.service
[Unit]
Description=zivpn VPN Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/zivpn
ExecStart=/usr/local/bin/zivpn server -c /etc/zivpn/config.json
Restart=always
RestartSec=3
Environment=ZIVPN_LOG_LEVEL=info
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW

[Install]
WantedBy=multi-user.target
EOF

    sysctl -w net.core.rmem_max=16777216 1> /dev/null 2> /dev/null
    sysctl -w net.core.wmem_max=16777216 1> /dev/null 2> /dev/null
    interface=$(ip -4 route ls|grep default|grep -Po '(?<=dev )(\S+)'|head -1)
    iptables -t nat -A PREROUTING -i $interface -p udp --dport 6000:19999 -j DNAT --to-destination :5667
    ufw allow 6000:19999/udp
    ufw allow 5667/udp
    
    systemctl daemon-reload
    systemctl enable zivpn.service
    systemctl start zivpn.service
    echo -e "${GREEN}Zivpn UDP Berhasil Terpasang!${NC}"
    read -p "Tekan Enter untuk kembali..."
}

# Fungsi Create Akun
function create_akun() {
    banner
    echo -e "${CYAN}--- TAMBAH PASSWORD BARU ---${NC}"
    read -p "Masukkan Password Baru: " username
    if [[ -z "$username" ]]; then echo -e "${RED}Input kosong!${NC}"; sleep 2; return; fi

    tmp=$(mktemp)
    jq ".config += [\"$username\"]" /etc/zivpn/config.json > "$tmp" && mv "$tmp" /etc/zivpn/config.json
    
    systemctl restart zivpn.service
    
    IP=$(curl -s ifconfig.me)
    echo -e "\n${GREEN}AKUN BERHASIL AKTIF!${NC}"
    echo -e "${PURPLE}-------------------------------------------${NC}"
    echo -e "Host/IP  : ${YELLOW}$IP${NC}"
    echo -e "Password : ${YELLOW}$username${NC}"
    echo -e "Port UDP : ${YELLOW}6000-19999${NC}"
    echo -e "Protocol : ${YELLOW}ZIVPN UDP${NC}"
    echo -e "${PURPLE}-------------------------------------------${NC}"
    read -p "Tekan Enter untuk kembali ke menu..."
}

# Fungsi Delete Akun
function delete_akun() {
    banner
    echo -e "${RED}--- HAPUS AKUN ---${NC}"
    users=$(jq -r '.config[]' /etc/zivpn/config.json)
    echo -e "Daftar User Aktif:"
    echo "$users" | nl
    echo ""
    read -p "Ketik Password yang ingin dihapus: " userhapus
    
    check=$(jq -r ".config[] | select(. == \"$userhapus\")" /etc/zivpn/config.json)
    if [ -z "$check" ]; then
        echo -e "${RED}Password [$userhapus] tidak ditemukan!${NC}"
    else
        tmp=$(mktemp)
        jq "del(.config[] | select(. == \"$userhapus\"))" /etc/zivpn/config.json > "$tmp" && mv "$tmp" /etc/zivpn/config.json
        systemctl restart zivpn.service
        echo -e "\n${GREEN}SUKSES:${NC} Akun dengan password ${YELLOW}[$userhapus]${NC} telah dihapus."
    fi
    read -p "Tekan Enter untuk kembali..."
}

# Fungsi Info VPS & Change Domain (Placeholder)
function info_vps() {
    banner
    echo -e "${CYAN}--- SYSTEM INFO ---${NC}"
    echo -e "Uptime      : $(uptime -p)"
    echo -e "RAM Usage   : $(free -h | grep Mem | awk '{print $3 "/" $2}')"
    echo -e "Public IP   : $(curl -s ifconfig.me)"
    echo -e "UDP Status  : $(systemctl is-active zivpn.service)"
    echo -e "${PURPLE}-------------------------------------------${NC}"
    read -p "Tekan Enter untuk kembali..."
}

# Main Menu
while true; do
    banner
    echo -e " [1] Install Zivpn UDP Server"
    echo -e " [2] Create Akun / Password"
    echo -e " [3] Delete Akun / Password"
    echo -e " [4] List User Aktif"
    echo -e " [5] Info Status VPS"
    echo -e " [6] Speedtest Server"
    echo -e " [0] Exit"
    echo -e "${PURPLE}======================================================${NC}"
    read -p " Pilih Menu :  " menu
    
    case $menu in
        1) install_zivpn ;;
        2) create_akun ;;
        3) delete_akun ;;
        4) banner; echo -e "${CYAN}USER AKTIF:${NC}"; jq -r '.config[]' /etc/zivpn/config.json | nl; echo ""; read -p "Enter..." ;;
        5) info_vps ;;
        6) banner; speedtest-cli --simple 2>/dev/null || (apt install speedtest-cli -y && speedtest-cli --simple); read -p "Enter..." ;;
        0) exit 0 ;;
        *) echo -e "${RED}Pilihan salah!${NC}"; sleep 1 ;;
    esac
done
