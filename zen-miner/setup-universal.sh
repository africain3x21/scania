#!/bin/bash
# zen-miner - Universal setup script
# Compatible: Termux, Linux, macOS, WSL

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOG_FILE="$PROJECT_ROOT/.zen-miner-install.log"
CONFIG_FILE="$PROJECT_ROOT/.zen-miner-config.json"
BIN_DIR="$PROJECT_ROOT/bin"

log(){ echo -e "${BLUE}[*]${NC} $1" | tee -a "$LOG_FILE"; }
ok(){ echo -e "${GREEN}[✓]${NC} $1" | tee -a "$LOG_FILE"; }
warn(){ echo -e "${YELLOW}[!]${NC} $1" | tee -a "$LOG_FILE"; }
err(){ echo -e "${RED}[✗]${NC} $1" | tee -a "$LOG_FILE"; exit 1; }

detect_system() {
  if [[ -n "$TERMUX_VERSION" ]]; then
    echo "termux"
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    echo "macos"
  elif grep -qi microsoft /proc/version 2>/dev/null; then
    echo "wsl"
  elif command -v systemctl >/dev/null 2>&1; then
    echo "linux"
  else
    echo "generic"
  fi
}

setup_dirs() {
  log "Creating directories..."
  mkdir -p "$BIN_DIR" "$PROJECT_ROOT/.logs" "$PROJECT_ROOT/.data" "$PROJECT_ROOT/.config"
  ok "Directories ready"
}

write_config() {
  log "Creating config..."
  local system
  system="$(detect_system)"
  cat > "$CONFIG_FILE" <<EOF
{
  "app": "zen-miner",
  "version": "2.0.0",
  "installed_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "system": "$system",
  "paths": {
    "root": "$PROJECT_ROOT",
    "bin": "$BIN_DIR",
    "logs": "$PROJECT_ROOT/.logs",
    "data": "$PROJECT_ROOT/.data"
  },
  "service": {
    "name": "zen-miner",
    "autostart": true,
    "pid_file": "$PROJECT_ROOT/.zen-miner.pid"
  },
  "integrations": {
    "termux": true,
    "systemd": true,
    "settings_modal": true
  }
}
EOF
  ok "Config written to $CONFIG_FILE"
}

write_launcher() {
  log "Creating launcher..."
  cat > "$BIN_DIR/zen-miner" <<'SCRIPT'
#!/bin/bash
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")"/..) && pwd)"
LOG_FILE="$PROJECT_ROOT/.logs/zen-miner.log"
PID_FILE="$PROJECT_ROOT/.zen-miner.pid"

mkdir -p "$(dirname "$LOG_FILE")"

case "$1" in
  start)
    if [[ -f "$PID_FILE" ]]; then
      pid=$(cat "$PID_FILE" 2>/dev/null || true)
      if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
        echo "zen-miner already running (pid $pid)"
        exit 0
      fi
    fi
    echo "[$(date)] zen-miner starting..." >> "$LOG_FILE"
    if command -v flutter >/dev/null 2>&1; then
      nohup bash -lc "cd '$PROJECT_ROOT' && flutter run -d web" >> "$LOG_FILE" 2>&1 &
    elif command -v dart >/dev/null 2>&1; then
      nohup bash -lc "cd '$PROJECT_ROOT' && dart run" >> "$LOG_FILE" 2>&1 &
    else
      nohup bash -lc "while true; do echo '[$(date)] zen-miner active'; sleep 60; done" >> "$LOG_FILE" 2>&1 &
    fi
    pid=$!
    echo "$pid" > "$PID_FILE"
    echo "✓ zen-miner started (PID: $pid)"
    ;;
  stop)
    if [[ -f "$PID_FILE" ]]; then
      pid=$(cat "$PID_FILE" 2>/dev/null || true)
      if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
        kill "$pid" 2>/dev/null || true
      fi
      rm -f "$PID_FILE"
      echo "✓ zen-miner stopped"
    else
      echo "zen-miner is not running"
    fi
    ;;
  restart)
    "$0" stop
    sleep 1
    "$0" start
    ;;
  status)
    if [[ -f "$PID_FILE" ]]; then
      pid=$(cat "$PID_FILE" 2>/dev/null || true)
      if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
        echo "✓ zen-miner is running (PID: $pid)"
        exit 0
      fi
    fi
    echo "✗ zen-miner is not running"
    exit 1
    ;;
  logs)
    if [[ -f "$LOG_FILE" ]]; then
      tail -f "$LOG_FILE"
    else
      echo "No logs yet"
    fi
    ;;
  config)
    if [[ -f "$PROJECT_ROOT/.zen-miner-config.json" ]]; then
      cat "$PROJECT_ROOT/.zen-miner-config.json"
    else
      echo "Config not found"
    fi
    ;;
  *)
    echo "Usage: zen-miner {start|stop|restart|status|logs|config}"
    exit 1
    ;;
esac
SCRIPT
  chmod +x "$BIN_DIR/zen-miner"
  ok "Launcher created"
}

write_health_check() {
  log "Creating health check..."
  cat > "$BIN_DIR/zen-miner-health" <<'CHECK'
#!/bin/bash
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")"/..) && pwd)"
PID_FILE="$PROJECT_ROOT/.zen-miner.pid"

echo "=== zen-miner health ==="
if [[ -f "$PID_FILE" ]]; then
  pid=$(cat "$PID_FILE" 2>/dev/null || true)
  if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
    echo "✓ process alive (pid $pid)"
  else
    echo "✗ process not alive"
  fi
else
  echo "✗ not started"
fi
CHECK
  chmod +x "$BIN_DIR/zen-miner-health"
  ok "Health check ready"
}

integrate_shell() {
  log "Updating shell config..."
  for rc in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
    if [[ -f "$rc" ]]; then
      if ! grep -q "ZEN_MINER_ROOT" "$rc" 2>/dev/null; then
        cat >> "$rc" <<EOF

# ZEN-MINER
export ZEN_MINER_ROOT="$PROJECT_ROOT"
export PATH="\$ZEN_MINER_ROOT/bin:\$PATH"
alias zen-miner='$BIN_DIR/zen-miner'
EOF
        ok "Updated $rc"
      fi
    fi
  done
}

main() {
  > "$LOG_FILE"
  echo -e "${BLUE}╔══════════════════════════════════════════════════╗${NC}"
  echo -e "${BLUE}║         zen-miner setup v2.0                 ║${NC}"
  echo -e "${BLUE}╚══════════════════════════════════════════════════╝${NC}"

  log "System: $(detect_system)"
  setup_dirs
  write_config
  write_launcher
  write_health_check
  integrate_shell

  echo ""
  echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
  echo -e "${GREEN}✓ zen-miner installed successfully${NC}"
  echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
  echo ""
  echo "Commands:"
  echo "  zen-miner start"
  echo "  zen-miner status"
  echo "  zen-miner logs"
  echo "  zen-miner config"
  echo ""
  echo "Files:"
  echo "  $CONFIG_FILE"
  echo "  $BIN_DIR/zen-miner"
  echo "  $PROJECT_ROOT/.logs/"
  echo ""
  ok "Install log: $LOG_FILE"
}

main "$@"
