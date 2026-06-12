#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="${1:-$(pwd)}"
WEB_ROOT="${WEB_ROOT:-/data/mephi-web}"
IP_ADDR="${IP_ADDR:-192.168.1.100}"
GATEWAY="${GATEWAY:-192.168.1.1}"
DNS="${DNS:-8.8.8.8}"
WEB_USER="${WEB_USER:-mephi-admin}"
WEB_GROUP="${WEB_GROUP:-mephi-devs}"
DENIED_USERS_FILE="${DENIED_USERS_FILE:-/etc/security/denied_users}"

mkdir -p "$OUT_DIR"

if [[ "${EUID}" -ne 0 ]]; then
    echo "Рекомендуется запускать через sudo, чтобы прочитать все системные файлы." >&2
fi

{
    echo "### default route"
    ip route | grep -E '^default' || true
    echo
    echo "### ping ${GATEWAY}"
    ping -c 4 "$GATEWAY" || true
    echo
    echo "### ping ${DNS}"
    ping -c 4 "$DNS" || true
} > "$OUT_DIR/network_check.txt"

journalctl -u nginx --since "5 minutes ago" > "$OUT_DIR/nginx_recent_logs.txt" || true
if [[ -f /tmp/nginx_recent_logs.txt ]]; then
    cp /tmp/nginx_recent_logs.txt "$OUT_DIR/nginx_recent_logs_tmp.txt"
fi
cp /etc/fstab "$OUT_DIR/fstab.txt"
getenforce > "$OUT_DIR/selinux_status.txt" || true
ls -Zd "$WEB_ROOT" > "$OUT_DIR/file_contexts.txt" || true
getcap /usr/sbin/tcpdump > "$OUT_DIR/tcpdump_capabilities.txt" || true
stat "$WEB_ROOT" > "$OUT_DIR/permissions.txt" || true
id "$WEB_USER" > "$OUT_DIR/users_groups.txt" || true
getent group "$WEB_GROUP" >> "$OUT_DIR/users_groups.txt" || true
curl -s "http://${IP_ADDR}" > "$OUT_DIR/curl_output.txt" || curl -s http://localhost > "$OUT_DIR/curl_output.txt" || true

if [[ -f "$WEB_ROOT/index.html" ]]; then
    cp "$WEB_ROOT/index.html" "$OUT_DIR/index.html"
fi

if compgen -G "/tmp/tcpdump*.rpm" >/dev/null; then
    cp /tmp/tcpdump*.rpm "$OUT_DIR/tcpdump.rpm" 2>/dev/null || cp /tmp/tcpdump*.rpm "$OUT_DIR/"
fi

# Дополнительные артефакты: не обязательны по таблице, но помогают подтвердить пункт 5.1.
if [[ -f "$DENIED_USERS_FILE" ]]; then
    cp "$DENIED_USERS_FILE" "$OUT_DIR/denied_users.txt"
fi
grep pam_listfile /etc/pam.d/sshd > "$OUT_DIR/pam_sshd_check.txt" || true
grep pam_listfile /etc/pam.d/login > "$OUT_DIR/pam_login_check.txt" || true
grep pam_listfile /etc/pam.d/su > "$OUT_DIR/pam_su_check.txt" || true
sshd -T 2>/dev/null | grep -E 'usepam|permitrootlogin' > "$OUT_DIR/sshd_security_check.txt" || true

cat <<MSG
Артефакты собраны в: ${OUT_DIR}

Проверьте вручную:
  cat ${OUT_DIR}/curl_output.txt

Должно быть:
  Hello from Student: м2551086

Историю команд лучше сохранить отдельно из интерактивной оболочки:
  history > ${OUT_DIR}/project_history.txt

Скриншот нужно сделать вручную и сохранить как:
  ${OUT_DIR}/mephi-nginx-screenshot.png
MSG
