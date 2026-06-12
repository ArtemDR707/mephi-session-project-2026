#!/usr/bin/env bash
set -euo pipefail

REMOTE_URL="${REMOTE_URL:-https://github.com/ArtemDR707/mephi-session-project-2026.git}"

if [[ ! -d .git ]]; then
    git init
fi

git add .
git status

echo
read -r -p "Создать commit и push в ${REMOTE_URL}? Введите YES: " answer
if [[ "$answer" != "YES" ]]; then
    echo "Остановлено пользователем."
    exit 0
fi

git commit -m "Add MEPHI session project 2026 files" || true
git branch -M main
if git remote get-url origin >/dev/null 2>&1; then
    git remote set-url origin "$REMOTE_URL"
else
    git remote add origin "$REMOTE_URL"
fi
git push -u origin main
