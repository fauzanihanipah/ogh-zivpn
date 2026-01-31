#!/bin/bash

# ========= WARNA =========
G='\033[0;32m'
R='\033[0;31m'
Y='\033[0;33m'
B='\033[0;34m'
N='\033[0m'

# ========= ROOT CHECK =========
[[ $EUID -ne 0 ]] && echo -e "${R}Jalankan sebagai root${N}" && exit 1

# ========= VAR =========
IP=$(curl -s https://ipv4.icanhazip.com)
PORT=36712
DOMAIN_FILE="/etc/zivpn-domain.conf"

# ========= LOAD DOMAIN =========
if [[ -f $DOMAIN_FILE ]]; then
  DOMAIN=$(cat $DOMAIN_FILE)
else
  DOMAIN=""
fi

# HOST yang dipakai user (domain > ip)
HOST=${DOMAIN:-$IP}

# ========= INSTALL ZIVPN =========
if [[ ! -f /usr/bin/zivpn ]]; then
  wget -q -O /usr/bin/zivpn https://raw.githubusercontent.com/Zidni_Dev/zivpn-binary/main/zivpn-linux-amd64
  chmod +x /usr/bin/zivpn

cat >/etc/zivpn.json <<EOF
{
  "listen": ":$PORT",
  "password": "zivpn",
  "slowdns": "8.8.8.8"
}
EOF

cat >/etc/systemd/system/zivpn.service <<EOF
[Unit]
Description=ZiVPN UDP Potato
After=network.target

[Service]
ExecStart=/usr/bin/zivpn -config /etc/zivpn.json
Restart=always
RestartSec=2

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable zivpn
  systemctl start zivpn
fi

# ========= LIST AKUN AKTIF =========
list_active() {
echo -e "${Y}┌────────── AKUN AKTIF ──────────┐${N}"
for u in $(awk -F: '$3 >= 1000 {print $1}' /etc/passwd); do
  exp=$(chage -l $u 2>/dev/null | grep "Account expires" | cut -d: -f2)
  [[ "$exp" != " never" && "$exp" != "" ]] && \
  echo -e "${Y}│${G} $u | Exp:$exp${Y} │${N}"
done
echo -e "${Y}└────────────────────────────────┘${N}"
}

# ========= MENU =========
while true; do
clear

# ===== LOGO =====
echo -e "${Y}┌──────────────────────────────────────────────┐${N}"
echo -e "${Y}│${R}   ██████╗  ██████╗ ██╗  ██╗${Y}           │${N}"
echo -e "${Y}│${R}  ██╔═══██╗██╔════╝ ██║  ██║${Y}           │${N}"
echo -e "${Y}│${R}  ██║   ██║██║  ███╗███████║${Y}           │${N}"
echo -e "${Y}│${R}  ██║   ██║██║   ██║██╔══██║${Y}           │${N}"
echo -e "${Y}│${R}  ╚██████╔╝╚██████╔╝██║  ██║${Y}           │${N}"
echo -e "${Y}│${R}   ╚═════╝  ╚═════╝ ╚═╝  ╚═╝${Y}           │${N}"
echo -e "${Y}│${G}        O G H   Z I V P N${Y}               │${N}"
echo -e "${Y}└──────────────────────────────────────────────┘${N}"
echo ""

# ===== VPS SPEC =====
echo -e "${Y}┌──────────── VPS SPEC ────────────┐${N}"
echo -e "${Y}│${B} HOST   ${Y}: ${G}$HOST${Y}               │${N}"
echo -e "${Y}│${B} PORT   ${Y}: ${G}$PORT${Y}                 │${N}"
echo -e "${Y}│${B} STATUS ${Y}: ${G}ZiVPN ACTIVE${Y}        │${N}"
echo -e "${Y}└──────────────────────────────────┘${N}"
echo ""

# ===== MENU =====
echo -e "${Y}┌──────────────── MENU ────────────────┐${N}"
echo -e "${Y}│${G} 1 ${Y}│${N} Buat Akun Premium              ${Y}│${N}"
echo -e "${Y}│${G} 2 ${Y}│${N} Buat Akun Trial (1 Hari)       ${Y}│${N}"
echo -e "${Y}│${G} 3 ${Y}│${N} Hapus Akun                     ${Y}│${N}"
echo -e "${Y}│${G} 4 ${Y}│${N} Lihat Akun Aktif               ${Y}│${N}"
echo -e "${Y}│${G} 5 ${Y}│${N} Ganti / Set Domain             ${Y}│${N}"
echo -e "${Y}│${G} 6 ${Y}│${N} Restart ZiVPN                  ${Y}│${N}"
echo -e "${Y}│${G} 0 ${Y}│${N} Keluar                         ${Y}│${N}"
echo -e "${Y}└─────────────────────────────────────┘${N}"
echo ""
read -p " Pilih menu : " x

case $x in
1)
  read -p "Username : " u
  read -p "Password : " p
  read -p "Expired (hari): " e
  useradd -e $(date -d "$e days" +%Y-%m-%d) -s /bin/false $u
  echo "$u:$p" | chpasswd
  clear
  echo -e "${G}┌──────── AKUN BERHASIL DIBUAT ────────┐${N}"
  echo -e "${G}│ HOST   : $HOST${N}"
  echo -e "${G}│ PORT   : $PORT${N}"
  echo -e "${G}│ USER   : $u${N}"
  echo -e "${G}│ PASS   : $p${N}"
  echo -e "${G}│ CONFIG : $HOST:$PORT@$u:$p${N}"
  echo -e "${G}└─────────────────────────────────────┘${N}"
  read -p " ENTER..."
  ;;
2)
  u=trial$(date +%s | cut -c8-)
  p=1234
  useradd -e $(date -d "1 day" +%Y-%m-%d) -s /bin/false $u
  echo "$u:$p" | chpasswd
  clear
  echo -e "${G}┌──────── TRIAL AKTIF 1 HARI ──────────┐${N}"
  echo -e "${G}│ HOST : $HOST${N}"
  echo -e "${G}│ PORT : $PORT${N}"
  echo -e "${G}│ USER : $u${N}"
  echo -e "${G}│ PASS : $p${N}"
  echo -e "${G}│ CFG  : $HOST:$PORT@$u:$p${N}"
  echo -e "${G}└─────────────────────────────────────┘${N}"
  read -p " ENTER..."
  ;;
3)
  list_active
  echo ""
  read -p "Username yang mau dihapus: " u
  read -p "Yakin hapus [$u]? [y/n]: " c
  [[ $c == y ]] && userdel $u && echo -e "${G}Akun $u dihapus${N}"
  sleep 2
  ;;
4)
  list_active
  read -p " ENTER..."
  ;;
5)
  read -p "Masukkan domain (kosongkan untuk IP): " d
  echo "$d" > $DOMAIN_FILE
  DOMAIN="$d"
  HOST=${DOMAIN:-$IP}
  echo -e "${G}Domain diset: ${HOST}${N}"
  sleep 2
  ;;
6)
  systemctl restart zivpn
  echo -e "${G}ZiVPN direstart${N}"
  sleep 2
  ;;
0) exit ;;
esac
done
