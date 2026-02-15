#!/bin/bash
# Zivpn UDP Management Panel - CIAN MOD
# Verified Original Logic Zahid Islam

# Warna
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' 
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'

# Banner ZIVPN Miring Kiri Patah-Patah Tebal
function banner() {
    clear
    echo -e "${PURPLE}"
    echo "      ███████╗██╗██╗   ██╗██████╗ ███╗   ██╗"
    echo "      ╚══███╔╝██║██║   ██║██╔══██╗████╗  ██║"
    echo "        ███╔╝ ██║██║   ██║██████╔╝██╔██╗ ██║"
    echo "       ███╔╝  ██║╚██╗ ██╔╝██╔═══╝ ██║╚██╗██║"
    echo "      ███████╗██║ ╚████╔╝ ██║     ██║ ╚████║"
    echo "      ╚Ref═══╝╚═╝  ╚═══╝  ╚═╝     ╚═╝  ╚═══╝"
    echo -e "                ${CYAN}C I A N   M O D   P A N E L${NC}"
    echo -e "${PURPLE}------------------------------------------------------------${NC}"
}

# --- AUTOMATIC INSTALL (Logic Asli Zahid Islam) ---
if [ ! -f "/usr/local/bin/zivpn" ]; then
    echo -e "Updating server"
    sudo apt-get update && sudo apt-get upgrade -y
    systemctl stop zivpn.service 1> /dev/null 2> /dev/null
    echo -e "Downloading UDP Service"
    wget https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-amd64 -O /usr/local/bin/zivpn 1> /dev/null 2> /dev/null
    chmod +x /usr/local/bin/zivpn
    mkdir /etc/zivpn 1> /dev/null 2> /dev/null
    
    # Kodingan Asli yang Kakak minta jangan sampai hilang
    wget https://raw.githubusercontent.com/zahidbd2/udp-zivpn/main/config.json -O /etc/zivpn/config.json 1> /dev/null 2> /dev/null

    echo "Generating cert files:"
    openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 -subj "/C=US/ST=California/L=Los Angeles/O=Example Corp/OU=IT Department/CN=zivpn" -keyout "/etc/zivpn/zivpn.key" -out "/etc/zivpn/zivpn.crt"
    sysctl -w net.core.rmem_max=16777216 1> /dev/null 2> /dev/null
    sysctl -w net.core.wmem_max=16777216 1> /dev/null 2> /dev/null
    
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
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable zivpn.service
    systemctl start zivpn.service
    
    # Iptables Asli
    iptables -t nat -A PREROUTING -i $(ip -4 route ls|grep default|grep -Po '(?<=dev )(\S+)'|head -1) -p udp --dport 6000:19999 -j DNAT --to-destination :5667
    ufw allow 6000:19999/udp
    ufw allow 5667/udp
    echo -e "ZIVPN UDP Installed"
    sleep 2
fi

# Fungsi Create Akun
function create_akun() {
    banner
    echo -e "${CYAN}--- TAMBAH AKUN BARU ---${NC}"
    read -p "Masukkan Password Baru: " username
    if [[ -z "$username" ]]; then echo "Gagal: Input kosong!"; sleep 1; return; fi

    # Pakai JQ untuk edit config.json tanpa hapus settingan lain
    tmp=$(mktemp)
    jq ".config += [\"$username\"]" /etc/zivpn/config.json > "$tmp" && mv "$tmp" /etc/zivpn/config.json
    systemctl restart zivpn.service
    
    IP=$(curl -s ifconfig.me)
    echo -e "\n${GREEN}AKUN BERHASIL DIBUAT!${NC}"
    echo -e "Host/IP  : $IP"
    echo -e "Password : $username"
    echo -e "Port UDP : 6000-19999"
    read -p "Tekan Enter untuk kembali..."
}

# Fungsi Delete Akun
function delete_akun() {
    banner
    echo -e "${RED}--- HAPUS AKUN ---${NC}"
    users=$(jq -r '.config[]' /etc/zivpn/config.json)
    echo -e "Daftar User:\n$users" | nl
    echo ""
    read -p "Masukkan Password yang akan dihapus: " userhapus
    
    # Konfirmasi hapus
    tmp=$(mktemp)
    jq "del(.config[] | select(. == \"$userhapus\"))" /etc/zivpn/config.json > "$tmp" && mv "$tmp" /etc/zivpn/config.json
    systemctl restart zivpn.service
    echo -e "\n${GREEN}Berhasil menghapus user: ${YELLOW}$userhapus${NC}"
    read -p "Tekan Enter untuk kembali..."
}

# Menu Utama
while true; do
    banner
    echo -e " [1] Create Akun (Tambah Password)"
    echo -e " [2] Delete Akun (Hapus Password)"
    echo -e " [3] List Akun Aktif"
    echo -e " [4] Info Status VPS"
    echo -e " [5] Speedtest Server"
    echo -e " [0] Exit"
    echo -e "${PURPLE}------------------------------------------------------------${NC}"
    read -p " Pilih Menu :  " menu
    
    case $menu in
        1) create_akun ;;
        2) delete_akun ;;
        3) banner; echo -e "${CYAN}USER AKTIF:${NC}"; jq -r '.config[]' /etc/zivpn/config.json | nl; echo ""; read -p "Enter..." ;;
        4) banner; echo -e "Uptime: $(uptime -p)"; echo "IP: $(curl -s ifconfig.me)"; read -p "Enter..." ;;
        5) banner; speedtest-cli --simple 2>/dev/null || (apt install speedtest-cli -y && speedtest-cli --simple); read -p "Enter..." ;;
        0) exit 0 ;;
        *) echo "Pilihan salah!"; sleep 1 ;;
    esac
done
