# Отчёт по сессионному проекту

## Цель работы

Подготовить минимальную установку Fedora 43 без графического интерфейса к работе в локальной сети, настроить базовую безопасность и развернуть web-сервер nginx для публикации простой страницы.

## 1. Управление сетью

Настроен сетевой интерфейс `eth0` через `nmcli`:

- IP-адрес: `192.168.1.100/24`
- Шлюз: `192.168.1.1`
- DNS: `8.8.8.8`

Hostname установлен командой `hostnamectl`:

```text
mephi-2026.domain.local
```

Проверка сетевой связности сохраняется в файл `network_check.txt`.

## 2. Управление программным обеспечением

Через `dnf` устанавливаются пакеты:

- `nginx`
- `tcpdump`
- `libcap-ng-utils`
- `libcap`
- `dnf-plugins-core`
- `policycoreutils-python-utils`

RPM-пакет `tcpdump` скачивается в `/tmp` командой `dnf download`, после чего устанавливается через `rpm -Uvh --replacepkgs`.

## 3. Файловая система и сервисы

Второй диск `/dev/sdb` размечается в один раздел `/dev/sdb1`, форматируется как ext4 с меткой `MEPHI_DATA` и монтируется в `/data/mephi-web`.

В `/etc/fstab` используется монтирование по метке:

```text
LABEL=MEPHI_DATA /data/mephi-web ext4 defaults 0 2
```

Сервис `nginx` включается в автозагрузку и запускается через `systemctl enable --now nginx`.

## 4. Управление доступом

Создаются:

- пользователь `mephi-admin`
- группа `mephi-devs`

Директория `/data/mephi-web` получает владельца `mephi-admin:mephi-devs` и права `2775`, чтобы новые файлы наследовали группу `mephi-devs`.

Для SELinux на директорию `/data/mephi-web` назначается тип `httpd_sys_content_t` через `semanage fcontext` и `restorecon`.

Для `/usr/sbin/tcpdump` устанавливаются capabilities:

```text
cap_net_admin,cap_net_raw+ep
```

## 5. Аутентификация и итоговая проверка

Для запрета входа root используется PAM-модуль `pam_listfile.so`. Пользователь `root` добавляется в файл `/etc/security/denied_users`, а правило подключается к `/etc/pam.d/sshd` и `/etc/pam.d/login`.

Страница web-сервера содержит:

```text
Hello from Student: м2551086
```

Итоговая проверка выполняется командами:

```bash
curl http://localhost
curl http://192.168.1.100
```

## Итоговый вывод

В результате выполнена настройка Fedora 43: задан статический IP и hostname, установлен и настроен nginx, создана отдельная файловая система для web-директории, настроены DAC-права, SELinux-контекст, capabilities для tcpdump и запрет входа root через PAM. Web-сервер отдаёт страницу `Hello from Student: м2551086` по адресу `http://192.168.1.100`.
