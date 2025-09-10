#!/usr/bin/env bash
set -Eeuo pipefail

# === Абсолютные пути ===
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LOG_DIR="$ROOT_DIR/logs"
LOG_FILE="$LOG_DIR/node_env.log"

# Логи
mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "[node_env] ROOT_DIR=$ROOT_DIR"
echo "[node_env] LOG_FILE=$LOG_FILE"

export SMART_CONTRACT_ADDRESS="0xE2070109A0C1e8561274E59F024301a19581d45c"

# Подхват .env из корня (если есть)
if [[ -f "$ROOT_DIR/.env" ]]; then
  echo "[node_env] Sourcing $ROOT_DIR/.env"
  # shellcheck disable=SC1090
  source "$ROOT_DIR/.env"
else
  echo "[node_env] No .env found at $ROOT_DIR/.env (will create it later if needed)"
fi

setup_node_nvm() {
  echo "[node_env] Setting up Node.js and NVM..."

  if ! command -v node >/dev/null 2>&1; then
    echo "[node_env] Node.js not found. Installing NVM and latest Node.js..."
    export NVM_DIR="$HOME/.nvm"
    if [ ! -d "$NVM_DIR" ]; then
      curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    fi
    # shellcheck disable=SC1090
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
    # shellcheck disable=SC1090
    [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
    nvm install --lts
  else
    echo "[node_env] Node.js is already installed: $(node -v)"
  fi

  if ! command -v yarn >/dev/null 2>&1; then
    if [[ "$OSTYPE" == darwin* ]]; then
      echo "[node_env] Installing Yarn via npm on macOS..."
      npm install -g --silent yarn
    else
      if grep -qi "ubuntu" /etc/os-release 2>/dev/null || uname -r | grep -qi "microsoft"; then
        echo "[node_env] Installing Yarn via apt on Ubuntu/WSL..."
        curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
        echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
        sudo apt update && sudo apt install -y yarn
      else
        echo "[node_env] Installing Yarn globally with npm..."
        npm install -g --silent yarn
      fi
    fi
  else
    echo "[node_env] Yarn is already installed: $(yarn -v)"
  fi
}

setup_environment() {
  echo "[node_env] Setting up environment configuration..."

  ENV_FILE="$ROOT_DIR/.env"

  # Гарантируем, что .env существует и имеет минимум 3 строки
  if [[ ! -f "$ENV_FILE" ]]; then
    echo "[node_env] Creating $ENV_FILE"
    printf "HF_TOKEN=\nSMART_CONTRACT_ADDRESS=\nDUMMY_LINE=\n" > "$ENV_FILE"
  else
    # Если в файле меньше 3 строк, добьём пустыми
    line_count=$(wc -l < "$ENV_FILE" || echo 0)
    while [[ "${line_count:-0}" -lt 3 ]]; do
      echo "" >> "$ENV_FILE"
      line_count=$((line_count+1))
    done
  fi

  if [[ "$OSTYPE" == darwin* ]]; then
    sed -i '' "3s~.*~SMART_CONTRACT_ADDRESS=$SMART_CONTRACT_ADDRESS~" "$ENV_FILE"
  else
    sed -i "3s~.*~SMART_CONTRACT_ADDRESS=$SMART_CONTRACT_ADDRESS~" "$ENV_FILE"
  fi

  echo "[node_env] Updated SMART_CONTRACT_ADDRESS in $ENV_FILE"
}

main() {
  setup_node_nvm
  setup_environment
  echo "[node_env] Done."
}

main "$@"
