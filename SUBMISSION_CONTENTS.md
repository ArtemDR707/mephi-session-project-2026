# Состав финального архива

В корне репозитория лежат обязательные файлы из задания:

- project_history.txt
- network_check.txt
- nginx_recent_logs.txt
- fstab.txt
- selinux_status.txt
- file_contexts.txt
- tcpdump_capabilities.txt
- permissions.txt
- users_groups.txt
- index.html
- curl_output.txt
- mephi-nginx-screenshot.png
- tcpdump.rpm
- tcpdump-4.99.6-2.fc43.x86_64.rpm

Также добавлены скрипты `scripts/setup_fedora43_mephi.sh` и `scripts/collect_artifacts.sh`, чтобы при необходимости можно было воспроизвести настройку на Fedora 43.

Файл `tcpdump.rpm` заменён на настоящий RPM-пакет Fedora 43. Дополнительно сохранено исходное имя скачанного пакета: `tcpdump-4.99.6-2.fc43.x86_64.rpm`.
