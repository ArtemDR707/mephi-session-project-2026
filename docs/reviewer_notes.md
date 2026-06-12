# Reviewer notes

Исправления по результатам проверки:

1. В `setup_fedora43_mephi.sh` исправлено удаление старой строки `/etc/fstab` для `/data/mephi-web`.
2. В `network_check.txt` добавлен вывод default route, чтобы подтвердить маршрут через `192.168.1.1`.
3. В setup добавлено сохранение `/tmp/network_check.txt` и `/tmp/nginx_recent_logs.txt`, потому что это явно указано в задании.
4. Убрано скрытие ошибки `nmcli connection up`, чтобы сбой настройки сети был заметен сразу.

Важно: обязательные артефакты (`project_history.txt`, `network_check.txt`, `curl_output.txt`, `tcpdump.rpm`, screenshot и др.) должны быть получены после реального запуска на Fedora 43 и добавлены в корень GitHub-репозитория.
