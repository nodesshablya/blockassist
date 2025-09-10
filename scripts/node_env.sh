#!/usr/bin/env bash
set -Eeuo pipefail

# ----- bootstrap logging ------------------------------------------------------
mkdir -p logs
: > logs/node_env.log
log() { echo "[$(date +'%F %T')]" "$@" | tee -a logs/node_env.log; }
trap 'log "ERROR at line $LINENO: exit code $?"' ERR

# ----- defaults & .env loading -----------------------------------------------
export SMART_CONTRACT_ADDRESS="${SMART_CONTRACT_ADDRESS:-0xE2070109A0C1e8561274E59F024301a19581d45c}"

ENV_FILE="$PWD/.env"
if [[ -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$ENV_FILE"
else
  log ".env not found, creating new one"
  printf "# Environment\nSMART_CONTRACT_ADDRESS=%s\n" "$SMART_CONTRACT_ADDRESS" > "$ENV_FILE"
fi

# helper: set or update key=value in .env (append if missing)
set_env_kv() {
  local key="$1" val="$2"
  if grep -qE "^${key}=" "$ENV_FILE"; then
    if [[ "$OSTYPE" == darwin* ]]; then
      sed -i '' -E "s|^${key}=.*|${key}=${val}|" "$ENV_FILE"
    else
      sed -i -E "s|^${key}=.*|${key}=${val}|" "$ENV_FILE"
    fi
  else
    printf "%s=%s\n" "$key" "$val" >> "$ENV_FILE"
  fi
}

# ----- Node.js / NVM / Yarn ---------------------------------------------------
setup_node_nvm() {
  log "Setting up Node.js and NVM…"

  # Install NVM if missing
  if ! command -v nvm >/dev/null 2>&1; then
    export NVM_DIR="$HOME/.nvm"
    if [[ ! -d "$NVM_DIR" ]]; then
      log "Installing NVM…"
      curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    fi
    # load nvm into current shell
    [[ -s "$NVM_DIR/nvm.sh" ]] && . "$NVM_DIR/nvm.sh"
    [[ -s "$NVM_DIR/bash_completion" ]] && . "$NVM_DIR/bash_completion"
  fi

  # Install latest LTS Node
  if ! command -v node >/dev/null 2>&1; then
    log "Installing Node via NVM…"
    nvm install --lts
  else
    log "Node found: $(node -v)"
  fi

  # Yarn: prefer Corepack (Node 16.10+)
  if ! command -v yarn >/dev/null 2>&1; then
    if command -v corepack >/dev/null 2>&1; then
      log "Enabling Corepack Yarn…"
      corepack enable
      corepack prepare yarn@stable --activate || true
    else
      log "Installing Yarn via npm…"
      npm install -g yarn --silent
    fi
  fi
}

# ----- Environment patch ------------------------------------------------------
setup_environment() {
  log "Setting up environment configuration…"
  set_env_kv "SMART_CONTRACT_ADDRESS" "$SMART_CONTRACT_ADDRESS"
  log "SMART_CONTRACT_ADDRESS set to: $SMART_CONTRACT_ADDRESS"
}

# ----- export functions if sourced, or run directly ---------------------------
# (оставь как есть, если файл source'ится из другого скрипта)
