# Команды выполнения проекта

Ниже приведён безопасный порядок выполнения. Значения уже подставлены под проект.

## 1. Проверка исходной системы

```bash
whoami
hostnamectl
nmcli device status
lsblk
```

## 2. Настройка системы одним скриптом

```bash
chmod +x scripts/*.sh
sudo CONFIRM_WIPE_SDB=YES ./scripts/setup_fedora43_mephi.sh
```

## 3. Ручные проверки

```bash
hostnamectl
ip addr show eth0
ip route
nmcli dev show eth0 | grep DNS
findmnt /data/mephi-web
systemctl status nginx --no-pager
getenforce
ls -Zd /data/mephi-web
getcap /usr/sbin/tcpdump
sudo -u mephi-admin /usr/sbin/tcpdump --help
curl http://localhost
curl http://192.168.1.100
```

## 4. Сбор артефактов

```bash
sudo ./scripts/collect_artifacts.sh .
history > project_history.txt
```

## 5. Скриншот

Выполнить:

```bash
curl http://192.168.1.100
```

Сделать скриншот терминала так, чтобы был виден вывод:

```text
Hello from Student: м2551086
```

Файл сохранить как:

```text
mephi-nginx-screenshot.png
```

## 6. Публикация

```bash
./scripts/prepare_github_commit.sh
```
