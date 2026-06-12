#!/usr/bin/env bash
set -euo pipefail

STUDENT_ID="${STUDENT_ID:-м2551086}"
IFACE="${IFACE:-eth0}"
IP_CIDR="${IP_CIDR:-192.168.1.100/24}"
IP_ADDR="${IP_ADDR:-192.168.1.100}"
GATEWAY="${GATEWAY:-192.168.1.1}"
DNS="${DNS:-8.8.8.8}"
HOSTNAME_FQDN="${HOSTNAME_FQDN:-mephi-2026.domain.local}"
DISK="${DISK:-/dev/sdb}"
PARTITION="${PARTITION:-/dev/sdb1}"
WEB_ROOT="${WEB_ROOT:-/data/mephi-web}"
WEB_USER="${WEB_USER:-mephi-admin}"
WEB_GROUP="${WEB_GROUP:-mephi-devs}"
WEB_PASSWORD="${WEB_PASSWORD:-P@ssw0rd2026}"
DENIED_USERS_FILE="${DENIED_USERS_FILE:-/etc/security/denied_users}"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

require_root() {
    if [[ "${EUID}" -ne 0 ]]; then
        echo "Ошибка: скрипт нужно запускать от root или через sudo." >&2
        exit 1
    fi
}

backup_once() {
    local file="$1"
    if [[ -f "$file" && ! -f "${file}.mephi.bak" ]]; then
        cp -a "$file" "${file}.mephi.bak"
    fi
}

insert_pam_rule() {
    local pam_file="$1"
    local pam_rule="auth required pam_listfile.so item=user sense=deny file=${DENIED_USERS_FILE} onerr=succeed"

    if [[ -f "$pam_file" ]]; then
        backup_once "$pam_file"
        if ! grep -q "pam_listfile.so.*${DENIED_USERS_FILE}" "$pam_file"; then
            sed -i "1i${pam_rule}" "$pam_file"
        fi
    fi
}

require_root

if [[ "${CONFIRM_WIPE_SDB:-NO}" != "YES" ]]; then
    cat >&2 <<MSG
ВНИМАНИЕ: скрипт форматирует ${DISK}.
Перед запуском проверьте диск командой:

    lsblk

Если ${DISK} точно является учебным вторым диском, запустите так:

    sudo CONFIRM_WIPE_SDB=YES ./scripts/setup_fedora43_mephi.sh
MSG
    exit 2
fi

if [[ ! -b "$DISK" ]]; then
    echo "Ошибка: диск ${DISK} не найден. Добавьте второй диск в виртуальную машину и повторите запуск." >&2
    lsblk >&2 || true
    exit 3
fi

echo "[1/11] Настройка hostname"
hostnamectl set-hostname "$HOSTNAME_FQDN"
hostnamectl

echo "[2/11] Настройка статического IP через nmcli"
CON_NAME="$(nmcli -t -f NAME,DEVICE connection show --active | awk -F: -v dev="$IFACE" '$2 == dev {print $1; exit}')"
if [[ -z "${CON_NAME}" ]]; then
    CON_NAME="$(nmcli -t -f NAME,DEVICE connection show | awk -F: -v dev="$IFACE" '$2 == dev {print $1; exit}')"
fi
if [[ -z "${CON_NAME}" ]]; then
    echo "Ошибка: не найдено подключение NetworkManager для интерфейса ${IFACE}." >&2
    nmcli device status >&2 || true
    exit 4
fi

nmcli connection modify "$CON_NAME" \
    ipv4.addresses "$IP_CIDR" \
    ipv4.gateway "$GATEWAY" \
    ipv4.dns "$DNS" \
    ipv4.method manual \
    connection.autoconnect yes

nmcli connection up "$CON_NAME"
ip addr show "$IFACE"
ip route

echo "[3/11] Установка пакетов"
dnf makecache -y
dnf install -y \
    nginx \
    tcpdump \
    libcap-ng-utils \
    libcap \
    dnf-plugins-core \
    policycoreutils-python-utils \
    firewalld \
    openssh-server \
    sudo \
    git \
    parted \
    e2fsprogs

echo "[4/11] Скачивание и установка локального RPM tcpdump"
rm -f /tmp/tcpdump*.rpm
dnf download --destdir /tmp tcpdump
rpm -Uvh --replacepkgs /tmp/tcpdump*.rpm

echo "[5/11] Разметка ${DISK}, создание ext4 с меткой MEPHI_DATA"
umount "$WEB_ROOT" 2>/dev/null || true
parted "$DISK" --script mklabel gpt
parted "$DISK" --script mkpart primary ext4 0% 100%
partprobe "$DISK" || true
sleep 2
mkfs.ext4 -F -L MEPHI_DATA "$PARTITION"

mkdir -p "$WEB_ROOT"
backup_once /etc/fstab
if grep -qE "[[:space:]]${WEB_ROOT}[[:space:]]" /etc/fstab; then
    awk -v mp="${WEB_ROOT}" '$2 != mp {print}' /etc/fstab > /etc/fstab.mephi.tmp
    cat /etc/fstab.mephi.tmp > /etc/fstab
    rm -f /etc/fstab.mephi.tmp
fi
echo "LABEL=MEPHI_DATA ${WEB_ROOT} ext4 defaults 0 2" >> /etc/fstab
systemctl daemon-reload
mount -a
findmnt "$WEB_ROOT"

echo "[6/11] Создание пользователя, группы и настройка DAC"
if ! getent group "$WEB_GROUP" >/dev/null; then
    groupadd "$WEB_GROUP"
fi
if ! id "$WEB_USER" >/dev/null 2>&1; then
    useradd -m -s /bin/bash -G "$WEB_GROUP" "$WEB_USER"
else
    usermod -aG "$WEB_GROUP" "$WEB_USER"
fi
echo "${WEB_USER}:${WEB_PASSWORD}" | chpasswd
chown "$WEB_USER:$WEB_GROUP" "$WEB_ROOT"
chmod 2775 "$WEB_ROOT"

sudo -u "$WEB_USER" bash -c "cat > '${WEB_ROOT}/index.html'" <<PAGE
Hello from Student: ${STUDENT_ID}
PAGE
chmod 664 "$WEB_ROOT/index.html"

ls -ld "$WEB_ROOT"
id "$WEB_USER"
getent group "$WEB_GROUP"

echo "[7/11] Настройка SELinux"
setenforce 1 || true
if [[ -f /etc/selinux/config ]]; then
    sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config
fi
semanage fcontext -a -t httpd_sys_content_t "${WEB_ROOT}(/.*)?" 2>/dev/null || \
    semanage fcontext -m -t httpd_sys_content_t "${WEB_ROOT}(/.*)?"
restorecon -Rv "$WEB_ROOT"
getenforce
ls -Zd "$WEB_ROOT"

echo "[8/11] Настройка nginx для нестандартной директории"
cat > /etc/nginx/conf.d/mephi-web.conf <<NGINX
server {
    listen 80;
    listen [::]:80;
    server_name localhost ${IP_ADDR} ${HOSTNAME_FQDN};

    root ${WEB_ROOT};
    index index.html;

    location / {
        try_files \$uri \$uri/ =404;
    }

    access_log /var/log/nginx/mephi-web-access.log;
    error_log  /var/log/nginx/mephi-web-error.log;
}
NGINX

nginx -t
systemctl enable --now nginx
systemctl restart nginx
systemctl status nginx --no-pager || true
journalctl -u nginx --since "5 minutes ago" > /tmp/nginx_recent_logs.txt || true

echo "[9/11] Настройка firewalld для доступа к nginx из подсети"
systemctl enable --now firewalld || true
firewall-cmd --permanent --add-service=http || true
firewall-cmd --reload || true
firewall-cmd --list-services || true

echo "[10/11] Настройка capabilities для tcpdump"
chmod u-s /usr/sbin/tcpdump || true
setcap cap_net_raw,cap_net_admin+ep /usr/sbin/tcpdump
getcap /usr/sbin/tcpdump
sudo -u "$WEB_USER" /usr/sbin/tcpdump --help >/tmp/tcpdump_help_check.txt
head -n 5 /tmp/tcpdump_help_check.txt || true

echo "[11/11] Запрет входа root через PAM и SSH"
printf 'root\n' > "$DENIED_USERS_FILE"
chown root:root "$DENIED_USERS_FILE"
chmod 600 "$DENIED_USERS_FILE"

insert_pam_rule /etc/pam.d/sshd
insert_pam_rule /etc/pam.d/login
insert_pam_rule /etc/pam.d/su

mkdir -p /etc/ssh/sshd_config.d
cat > /etc/ssh/sshd_config.d/99-mephi-root-login.conf <<SSHCFG
UsePAM yes
PermitRootLogin no
SSHCFG

systemctl enable --now sshd || true
sshd -t
systemctl restart sshd || true

grep pam_listfile /etc/pam.d/sshd || true
grep pam_listfile /etc/pam.d/login || true
sshd -T | grep -E 'usepam|permitrootlogin' || true

echo "Сохранение проверки сети в /tmp/network_check.txt"
{
    echo "### default route"
    ip route | grep -E '^default' || true
    echo
    echo "### ping ${DNS}"
    ping -c 4 "${DNS}" || true
    echo
    echo "### ping ${GATEWAY}"
    ping -c 4 "${GATEWAY}" || true
} > /tmp/network_check.txt

echo "Финальная проверка curl"
curl -s http://localhost || true
echo
curl -s "http://${IP_ADDR}" || true
echo

echo "Готово. Теперь выполните:"
echo "  sudo ./scripts/collect_artifacts.sh ."
echo "  history > project_history.txt"
echo "И сделайте скриншот curl http://${IP_ADDR} как mephi-nginx-screenshot.png"
