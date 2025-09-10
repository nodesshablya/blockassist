#!/usr/bin/env bash
set -Eeuo pipefail

# === Абсолютные пути ===
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LOG_DIR="$ROOT_DIR/logs"
LOG_FILE="$LOG_DIR/yarn_setup.log"

# Логи
mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "[yarn_setup] ROOT_DIR=$ROOT_DIR"
echo "[yarn_setup] LOG_FILE=$LOG_FILE"

# 1) Готовим Node/NVM/Yarn и .env через node_env.sh (как отдельный шаг)
echo "[yarn_setup] Running node_env setup..."
bash "$ROOT_DIR/scripts/node_env.sh"

# 2) Переходим в каталог приложения
APP_DIR="$ROOT_DIR/modal-login"
if [[ ! -d "$APP_DIR" ]]; then
  echo "[yarn_setup] ERROR: App directory not found: $APP_DIR"
  exit 1
fi
cd "$APP_DIR"

# 3) Если ещё не билдили (.next нет) — ставим зависимости и билдим
if [[ ! -d ".next" ]]; then
  echo "[yarn_setup] Installing dependencies in $APP_DIR ..."
  yarn install --immutable

  echo "[yarn_setup] Building app in $APP_DIR ..."
  yarn build
else
  echo "[yarn_setup] .next already exists — skipping install/build"
fi

echo "[yarn_setup] Done."
