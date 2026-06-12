# mephi-session-project-2026

Сессионный проект по курсу **«Операционные системы семейства Unix»**.

Проект подготовлен под требования задания для Fedora 43 minimal без GUI.

## Используемые значения

| Параметр | Значение |
|---|---|
| Студент | м2551086 |
| Hostname | `mephi-2026.domain.local` |
| Интерфейс | `eth0` |
| IP-адрес | `192.168.1.100/24` |
| Шлюз | `192.168.1.1` |
| DNS | `8.8.8.8` |
| Web root | `/data/mephi-web` |
| Пользователь | `mephi-admin` |
| Группа | `mephi-devs` |
| Пароль пользователя | `P@ssw0rd2026` |
| SELinux | `Enforcing` |
| Метка файловой системы | `MEPHI_DATA` |

## Что настраивается

1. Статический IP и hostname через `nmcli` и `hostnamectl`.
2. Установка пакетов `nginx`, `tcpdump`, `libcap-ng-utils`, `libcap` и вспомогательных утилит.
3. Скачивание RPM-пакета `tcpdump` через `dnf download` и установка через `rpm`.
4. Разметка второго диска `/dev/sdb`, создание ext4 с меткой `MEPHI_DATA`.
5. Автомонтирование `/data/mephi-web` через `/etc/fstab` по метке тома.
6. Запуск и автозагрузка `nginx`.
7. Создание пользователя `mephi-admin` и группы `mephi-devs`.
8. Настройка DAC-прав `2775` на `/data/mephi-web`.
9. Настройка SELinux-контекста `httpd_sys_content_t`.
10. Настройка capabilities для `/usr/sbin/tcpdump`.
11. Запрет входа root через SSH и локальную консоль через PAM `pam_listfile.so`.
12. Создание страницы `index.html` с текстом `Hello from Student: м2551086`.
13. Сбор обязательных артефактов для GitHub.

## Важное предупреждение

Скрипт `scripts/setup_fedora43_mephi.sh` размечает и форматирует диск `/dev/sdb`.
Запускайте его только на учебной виртуальной машине, где `/dev/sdb` является отдельным диском для проекта.

Перед запуском обязательно проверьте:

```bash
lsblk
nmcli device status
```

## Быстрый запуск на Fedora 43

```bash
chmod +x scripts/*.sh
sudo CONFIRM_WIPE_SDB=YES ./scripts/setup_fedora43_mephi.sh
```

После настройки соберите артефакты:

```bash
sudo ./scripts/collect_artifacts.sh .
history > project_history.txt
```

Сделайте скриншот терминала с командой:

```bash
curl http://192.168.1.100
```

На скриншоте должен быть виден текст:

```text
Hello from Student: м2551086
```

Сохраните скриншот как:

```text
mephi-nginx-screenshot.png
```

## Проверка web-сервера

```bash
curl http://localhost
curl http://192.168.1.100
```

Ожидаемый результат:

```text
Hello from Student: м2551086
```

## RPM-артефакт

В репозитории приложен настоящий RPM-пакет Fedora 43:

```text
tcpdump-4.99.6-2.fc43.x86_64.rpm
```

Для соответствия таблице задания также добавлена копия с именем:

```text
tcpdump.rpm
```

## Публикация на GitHub

Репозиторий должен быть публичным:

```text
https://github.com/ArtemDR707/mephi-session-project-2026
```

Команды публикации:

```bash
git init
git add .
git commit -m "Add MEPHI session project 2026 files"
git branch -M main
git remote add origin https://github.com/ArtemDR707/mephi-session-project-2026.git
git push -u origin main
```

## Обязательные файлы после реального запуска

| Файл | Что подтверждает |
|---|---|
| `project_history.txt` | История выполненных команд |
| `network_check.txt` | Проверка связи с gateway и DNS |
| `nginx_recent_logs.txt` | Логи nginx |
| `fstab.txt` | Автомонтирование `/data/mephi-web` |
| `selinux_status.txt` | SELinux `Enforcing` |
| `file_contexts.txt` | SELinux-контекст web-директории |
| `tcpdump_capabilities.txt` | Capabilities для tcpdump |
| `permissions.txt` | Владелец, группа, права `2775` |
| `users_groups.txt` | Пользователь и группа |
| `index.html` | Web-страница студента |
| `curl_output.txt` | Проверка ответа nginx |
| `mephi-nginx-screenshot.png` | Визуальное подтверждение |
| `tcpdump.rpm` / `tcpdump-4.99.6-2.fc43.x86_64.rpm` | Скачанный RPM-пакет tcpdump |
