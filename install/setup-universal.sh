#!/bin/bash

################################################################################
# SCANIA - Universal Setup Script
# Compatible: Termux, Linux (systemd), macOS, Windows (WSL)
# Communicates with existing system configs and settings
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Global variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
INSTALL_LOG="$PROJECT_ROOT/.scania-install.log"
SETTINGS_FILE="$PROJECT_ROOT/.scania-config.json"
SERVICE_NAME="scania"
IS_TERMUX=false
IS_SYSTEMD=false
IS_MACOS=false
IS_WSL=false

################################################################################
# UTILITY FUNCTIONS
################################################################################

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$INSTALL_LOG"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1" | tee -a "$INSTALL_LOG"
}

log_warn() {
    echo -e "${YELLOW}[⚠]${NC} $1" | tee -a "$INSTALL_LOG"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1" | tee -a "$INSTALL_LOG"
}

# Detect system type
detect_system() {
    log_info "Detecting system environment..."
    
    if [[ -n "$TERMUX_VERSION" ]]; then
        IS_TERMUX=true
        log_success "Detected: Termux"
    elif [[ -f /etc/systemd/system-preset/100-default.preset ]]; then
        IS_SYSTEMD=true
        if grep -qi microsoft /proc/version &>/dev/null; then
            IS_WSL=true
            log_success "Detected: Linux (WSL2)"
        else
            log_success "Detected: Linux (systemd)"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        IS_MACOS=true
        log_success "Detected: macOS"
    else
        log_warn "System detection unclear - proceeding with generic setup"
    fi
}

# Check dependencies
check_dependencies() {
    log_info "Checking dependencies..."
    
    local deps=()
    local missing=false
    
    # Core requirements
    if ! command -v dart &> /dev/null; then
        deps+=("dart")
        missing=true
    fi
    
    if ! command -v git &> /dev/null; then
        deps+=("git")
        missing=true
    fi
    
    if [[ "$IS_SYSTEMD" == true ]]; then
        if ! command -v systemctl &> /dev/null; then
            deps+=("systemd")
            missing=true
        fi
    fi
    
    if [[ "$missing" == true ]]; then
        log_error "Missing dependencies: ${deps[*]}"
        log_info "Install them and run again, or use --skip-deps"
        return 1
    fi
    
    log_success "All dependencies found"
    return 0
}

# Create configuration structure
create_config() {
    log_info "Creating configuration files..."
    
    # Create main config file
    cat > "$SETTINGS_FILE" << 'EOF'
{
  "version": "1.0.0",
  "installation": {
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "system": "$(uname -s)",
    "environment": "production"
  },
  "service": {
    "name": "scania",
    "autostart": true,
    "restart_policy": "on-failure"
  },
  "paths": {
    "root": "SCANIA_ROOT",
    "logs": "SCANIA_ROOT/.logs",
    "data": "SCANIA_ROOT/.data",
    "config": "SCANIA_ROOT/.config"
  },
  "monitoring": {
    "enabled": true,
    "health_check_interval": 300,
    "log_retention_days": 30
  },
  "termux": {
    "enabled": false,
    "notification_service": false,
    "background_service": false
  },
  "systemd": {
    "enabled": false,
    "user_mode": true
  }
}
EOF

    # Replace placeholders
    sed -i "s|SCANIA_ROOT|$PROJECT_ROOT|g" "$SETTINGS_FILE"
    
    # Create directories
    mkdir -p "$PROJECT_ROOT/.logs"
    mkdir -p "$PROJECT_ROOT/.data"
    mkdir -p "$PROJECT_ROOT/.config"
    
    log_success "Configuration created at $SETTINGS_FILE"
}

# Setup Termux-specific configuration
setup_termux() {
    log_info "Setting up Termux environment..."
    
    # Create Termux notification helper
    cat > "$PROJECT_ROOT/.config/termux-setup.sh" << 'EOF'
#!/bin/bash
# Termux specific configuration

# Check if termux-notification is available
if command -v termux-notification &> /dev/null; then
    export TERMUX_NOTIFICATION_AVAILABLE=true
fi

# Setup background job handler
if command -v termux-wake-lock &> /dev/null; then
    export TERMUX_WAKELOCK_AVAILABLE=true
    termux-wake-lock
fi

# Create persistent notification
if [[ -n "$TERMUX_NOTIFICATION_AVAILABLE" ]]; then
    termux-notification \
        --title "Scania Running" \
        --content "Service is active" \
        --id 1
fi

echo "Termux environment ready"
EOF

    chmod +x "$PROJECT_ROOT/.config/termux-setup.sh"
    
    # Update config file
    jq '.termux.enabled = true' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp"
    mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
    
    log_success "Termux setup completed"
}

# Setup systemd service
setup_systemd() {
    log_info "Setting up systemd service..."
    
    local service_dir=""
    local user_mode=$1
    
    if [[ "$user_mode" == true ]]; then
        service_dir="$HOME/.config/systemd/user"
        mkdir -p "$service_dir"
    else
        service_dir="/etc/systemd/system"
        if [[ ! -w "$service_dir" ]]; then
            log_warn "No write permission to /etc/systemd/system, using user mode"
            service_dir="$HOME/.config/systemd/user"
            mkdir -p "$service_dir"
            user_mode=true
        fi
    fi
    
    # Create service file
    cat > "$service_dir/$SERVICE_NAME.service" << EOF
[Unit]
Description=Scania Service - Universal Computing Machine
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$PROJECT_ROOT
ExecStart=$PROJECT_ROOT/bin/scania start
ExecStop=$PROJECT_ROOT/bin/scania stop
ExecReload=$PROJECT_ROOT/bin/scania reload
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=$SERVICE_NAME
Environment="PATH=$PATH"

[Install]
WantedBy=$([ "$user_mode" == true ] && echo "default.target" || echo "multi-user.target")
EOF

    chmod 644 "$service_dir/$SERVICE_NAME.service"
    
    # Update config
    jq ".systemd.enabled = true | .systemd.user_mode = $user_mode" "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp"
    mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
    
    # Reload systemd
    if [[ "$user_mode" == true ]]; then
        systemctl --user daemon-reload
        log_success "Systemd user service installed: $service_dir/$SERVICE_NAME.service"
    else
        sudo systemctl daemon-reload
        log_success "Systemd system service installed: $service_dir/$SERVICE_NAME.service"
    fi
}

# Create launcher scripts
create_launchers() {
    log_info "Creating launcher scripts..."
    
    mkdir -p "$PROJECT_ROOT/bin"
    
    # Main launcher
    cat > "$PROJECT_ROOT/bin/scania" << 'EOF'
#!/bin/bash

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="$PROJECT_ROOT/.scania-config.json"
LOG_FILE="$PROJECT_ROOT/.logs/scania.log"

# Source system config if available
if [[ -f "$PROJECT_ROOT/.config/termux-setup.sh" ]]; then
    source "$PROJECT_ROOT/.config/termux-setup.sh"
fi

case "$1" in
    start)
        echo "[$(date)] Starting Scania..." >> "$LOG_FILE"
        cd "$PROJECT_ROOT"
        flutter run -d web 2>&1 | tee -a "$LOG_FILE" &
        echo $! > "$PROJECT_ROOT/.pid"
        echo "Scania started (PID: $!)"
        ;;
    stop)
        echo "[$(date)] Stopping Scania..." >> "$LOG_FILE"
        if [[ -f "$PROJECT_ROOT/.pid" ]]; then
            kill $(cat "$PROJECT_ROOT/.pid") 2>/dev/null || true
            rm "$PROJECT_ROOT/.pid"
        fi
        echo "Scania stopped"
        ;;
    restart)
        $0 stop
        sleep 2
        $0 start
        ;;
    reload)
        echo "[$(date)] Reloading Scania..." >> "$LOG_FILE"
        # Graceful reload logic
        echo "Reload signal sent"
        ;;
    status)
        if [[ -f "$PROJECT_ROOT/.pid" ]]; then
            PID=$(cat "$PROJECT_ROOT/.pid")
            if kill -0 "$PID" 2>/dev/null; then
                echo "✓ Scania is running (PID: $PID)"
                return 0
            fi
        fi
        echo "✗ Scania is not running"
        return 1
        ;;
    logs)
        tail -f "$LOG_FILE"
        ;;
    config)
        cat "$CONFIG_FILE" | jq .
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|reload|status|logs|config}"
        exit 1
        ;;
esac
EOF

    chmod +x "$PROJECT_ROOT/bin/scania"
    
    # Health check script
    cat > "$PROJECT_ROOT/bin/health-check" << 'EOF'
#!/bin/bash

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="$PROJECT_ROOT/.scania-config.json"

check_process() {
    if [[ -f "$PROJECT_ROOT/.pid" ]]; then
        PID=$(cat "$PROJECT_ROOT/.pid")
        if kill -0 "$PID" 2>/dev/null; then
            return 0
        fi
    fi
    return 1
}

check_port() {
    if command -v lsof &> /dev/null; then
        lsof -i :8080 &>/dev/null && return 0
    elif command -v netstat &> /dev/null; then
        netstat -tuln | grep -q 8080 && return 0
    fi
    return 1
}

check_logs() {
    local log_file="$PROJECT_ROOT/.logs/scania.log"
    if [[ -f "$log_file" ]]; then
        tail -n 5 "$log_file" | grep -q "error\|ERROR" && return 1
    fi
    return 0
}

# Run checks
echo "=== Scania Health Check ==="
echo -n "Process: "
if check_process; then echo "✓ Running"; else echo "✗ Not running"; fi

echo -n "Port 8080: "
if check_port; then echo "✓ Listening"; else echo "✗ Not listening"; fi

echo -n "Logs: "
if check_logs; then echo "✓ No errors"; else echo "⚠ Errors detected"; fi

echo "=== End Health Check ==="
EOF

    chmod +x "$PROJECT_ROOT/bin/health-check"
    
    log_success "Launcher scripts created in $PROJECT_ROOT/bin/"
}

# Setup cron job for monitoring
setup_monitoring() {
    log_info "Setting up monitoring..."
    
    # Create cron job for health checks
    local cron_cmd="*/5 * * * * $PROJECT_ROOT/bin/health-check >> $PROJECT_ROOT/.logs/health-check.log 2>&1"
    
    if command -v crontab &> /dev/null; then
        # Check if already exists
        if ! crontab -l 2>/dev/null | grep -q "health-check"; then
            (crontab -l 2>/dev/null; echo "$cron_cmd") | crontab -
            log_success "Cron health check installed"
        fi
    fi
    
    # For Termux, create a background script instead
    if [[ "$IS_TERMUX" == true ]]; then
        cat > "$PROJECT_ROOT/.config/termux-monitor.sh" << EOF
#!/bin/bash
while true; do
    $PROJECT_ROOT/bin/health-check >> $PROJECT_ROOT/.logs/health-check.log 2>&1
    sleep 300
done
EOF
        chmod +x "$PROJECT_ROOT/.config/termux-monitor.sh"
        log_success "Termux monitoring script created"
    fi
}

# Integration with existing settings
integrate_settings() {
    log_info "Integrating with existing system settings..."
    
    # Detect and merge existing configs
    local existing_configs=(
        "$HOME/.bashrc"
        "$HOME/.zshrc"
        "/etc/environment"
        "$HOME/.config/environment.d/scania.conf"
    )
    
    for config in "${existing_configs[@]}"; do
        if [[ -f "$config" ]] && ! grep -q "SCANIA_ROOT" "$config"; then
            cat >> "$config" << EOF
# Scania Configuration
export SCANIA_ROOT="$PROJECT_ROOT"
export PATH="\$SCANIA_ROOT/bin:\$PATH"
EOF
            log_success "Updated: $config"
        fi
    done
    
    # Create environment file for systemd
    if [[ "$IS_SYSTEMD" == true ]]; then
        mkdir -p "$HOME/.config/environment.d"
        cat > "$HOME/.config/environment.d/scania.conf" << EOF
SCANIA_ROOT=$PROJECT_ROOT
SCANIA_LOG_DIR=$PROJECT_ROOT/.logs
SCANIA_DATA_DIR=$PROJECT_ROOT/.data
PATH=$PROJECT_ROOT/bin:\$PATH
EOF
        log_success "Environment configuration created for systemd"
    fi
}

# Final setup and summary
finalize_setup() {
    log_info "Finalizing setup..."
    
    # Make bin executable
    chmod +x "$PROJECT_ROOT/bin"/*
    
    # Create README
    cat > "$PROJECT_ROOT/SETUP.md" << 'EOF'
# Scania Setup Complete

## Quick Start

### Start Service
```bash
scania start
# or
systemctl --user start scania  # if using systemd
```

### Check Status
```bash
scania status
bin/health-check
```

### View Logs
```bash
scania logs
```

### Configuration
```bash
scania config
# Edit: .scania-config.json
```

## Environment

- **Installation**: Termux, Linux (systemd), macOS, WSL2
- **Service Manager**: systemd (Linux), Termux (mobile), launchd (macOS)
- **Configuration**: `.scania-config.json`
- **Logs**: `.logs/`
- **Data**: `.data/`

## Troubleshooting

1. **Service won't start**: Check logs with `scania logs`
2. **Health check fails**: Run `bin/health-check` manually
3. **Config issues**: Verify JSON with `scania config`
EOF

    log_success "Setup documentation created: SETUP.md"
    
    # Summary
    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✓ SCANIA SETUP COMPLETE${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
    echo ""
    echo "Installation Type:"
    [[ "$IS_TERMUX" == true ]] && echo "  • Termux (Mobile)"
    [[ "$IS_SYSTEMD" == true ]] && echo "  • Linux (systemd)"
    [[ "$IS_MACOS" == true ]] && echo "  • macOS"
    echo ""
    echo "Quick Commands:"
    echo "  Start:   scania start"
    echo "  Stop:    scania stop"
    echo "  Status:  scania status"
    echo "  Logs:    scania logs"
    echo ""
    echo "Configuration: $SETTINGS_FILE"
    echo "Logs: $PROJECT_ROOT/.logs/"
    echo ""
    echo -e "${BLUE}Read SETUP.md for detailed documentation${NC}"
    echo ""
}

################################################################################
# MAIN EXECUTION
################################################################################

main() {
    echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║        SCANIA - Universal Setup Script                ║${NC}"
    echo -e "${BLUE}║  Compatible: Termux, Linux, macOS, WSL                ║${NC}"
    echo -e "${BLUE}╚════════════��═══════════════════════════════════════════╝${NC}"
    echo ""
    
    # Create log file
    > "$INSTALL_LOG"
    
    # Run setup steps
    detect_system
    
    if ! check_dependencies; then
        if [[ "$1" != "--skip-deps" ]]; then
            log_error "Setup aborted due to missing dependencies"
            exit 1
        fi
        log_warn "Continuing despite missing dependencies (--skip-deps flag)"
    fi
    
    create_config
    create_launchers
    integrate_settings
    
    # System-specific setup
    if [[ "$IS_TERMUX" == true ]]; then
        setup_termux
    fi
    
    if [[ "$IS_SYSTEMD" == true ]]; then
        setup_systemd true  # Use user mode by default
    fi
    
    setup_monitoring
    
    finalize_setup
    
    log_success "Installation log saved to $INSTALL_LOG"
}

# Handle arguments
if [[ "$1" == "--help" ]]; then
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --skip-deps   Skip dependency checks"
    echo "  --system      Use system-wide systemd (requires sudo)"
    echo "  --help        Show this help message"
    exit 0
fi

main "$@"
