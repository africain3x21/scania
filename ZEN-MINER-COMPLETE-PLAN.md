# ZEN-MINER - Installation Plan Complet

## Plan d'Installation avec `cat`

### Étape 1 : Créer la structure du projet

```bash
mkdir -p zen-miner/{bin,.logs,.data,.config}
cd zen-miner
```

### Étape 2 : Créer le fichier de configuration

```bash
cat > .zen-miner-config.json <<'EOF'
{
  "app": "zen-miner",
  "version": "2.0.0",
  "installed": "2026-10-10",
  "system": "termux",
  "paths": {
    "root": "/root/zen-miner",
    "bin": "/root/zen-miner/bin",
    "logs": "/root/zen-miner/.logs",
    "data": "/root/zen-miner/.data"
  },
  "service": {
    "name": "zen-miner",
    "autostart": true,
    "pid_file": "/root/zen-miner/.zen-miner.pid"
  },
  "integrations": {
    "termux": true,
    "systemd": false,
    "settings_modal": true
  }
}
EOF
```

### Étape 3 : Créer le script principal `zen-miner`

```bash
cat > bin/zen-miner <<'EOF'
#!/bin/bash

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_FILE="$PROJECT_ROOT/.logs/zen-miner.log"
PID_FILE="$PROJECT_ROOT/.zen-miner.pid"

mkdir -p "$(dirname "$LOG_FILE")"

case "$1" in
  start)
    if [[ -f "$PID_FILE" ]]; then
      pid=$(cat "$PID_FILE" 2>/dev/null || true)
      if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
        echo "✓ zen-miner already running (pid $pid)"
        exit 0
      fi
    fi
    
    echo "[$(date)] zen-miner starting..." >> "$LOG_FILE"
    
    if command -v flutter >/dev/null 2>&1; then
      nohup bash -c "cd '$PROJECT_ROOT' && flutter run -d web" >> "$LOG_FILE" 2>&1 &
    elif command -v dart >/dev/null 2>&1; then
      nohup bash -c "cd '$PROJECT_ROOT' && dart run" >> "$LOG_FILE" 2>&1 &
    else
      nohup bash -c "while true; do echo '[$(date)] zen-miner running'; sleep 60; done" >> "$LOG_FILE" 2>&1 &
    fi
    
    pid=$!
    echo $pid > "$PID_FILE"
    echo "✓ zen-miner started (PID: $pid)"
    ;;
  
  stop)
    if [[ -f "$PID_FILE" ]]; then
      pid=$(cat "$PID_FILE" 2>/dev/null || true)
      if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
        kill "$pid" 2>/dev/null
        sleep 1
      fi
      rm -f "$PID_FILE"
      echo "✓ zen-miner stopped"
    else
      echo "zen-miner not running"
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
        echo "✓ zen-miner running (PID: $pid)"
        exit 0
      fi
    fi
    echo "✗ zen-miner not running"
    exit 1
    ;;
  
  logs)
    tail -f "$LOG_FILE"
    ;;
  
  config)
    cat "$PROJECT_ROOT/.zen-miner-config.json"
    ;;
  
  *)
    echo "Usage: zen-miner {start|stop|restart|status|logs|config}"
    exit 1
    ;;
esac
EOF

chmod +x bin/zen-miner
```

### Étape 4 : Créer le script de santé `zen-miner-health`

```bash
cat > bin/zen-miner-health <<'EOF'
#!/bin/bash

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PID_FILE="$PROJECT_ROOT/.zen-miner.pid"

echo "=== ZEN-MINER HEALTH CHECK ==="
if [[ -f "$PID_FILE" ]]; then
  pid=$(cat "$PID_FILE" 2>/dev/null || true)
  if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
    echo "✓ Process: Running (PID: $pid)"
  else
    echo "✗ Process: Not alive"
  fi
else
  echo "✗ Service: Not started"
fi
echo "=== END ==="
EOF

chmod +x bin/zen-miner-health
```

### Étape 5 : Intégrer dans `.bashrc`

```bash
cat >> ~/.bashrc <<'EOF'

# ZEN-MINER
export ZEN_MINER_ROOT="/root/zen-miner"
export PATH="$ZEN_MINER_ROOT/bin:$PATH"
alias zen-miner='$ZEN_MINER_ROOT/bin/zen-miner'
EOF

source ~/.bashrc
```

### Étape 6 : Tester l'installation

```bash
zen-miner start
zen-miner status
zen-miner logs
zen-miner config
zen-miner-health
```

---

## Installation Rapide (One-Liner)

Copier/coller tout ça d'un coup :

```bash
mkdir -p zen-miner/{bin,.logs,.data,.config} && cd zen-miner && \
cat > .zen-miner-config.json <<'EOF'
{
  "app": "zen-miner",
  "version": "2.0.0",
  "installed": "2026-10-10",
  "system": "termux",
  "paths": {
    "root": "/root/zen-miner",
    "bin": "/root/zen-miner/bin",
    "logs": "/root/zen-miner/.logs",
    "data": "/root/zen-miner/.data"
  },
  "service": {
    "name": "zen-miner",
    "autostart": true,
    "pid_file": "/root/zen-miner/.zen-miner.pid"
  }
}
EOF
```

Puis créer le script principal :

```bash
cat > bin/zen-miner <<'EOF'
#!/bin/bash
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_FILE="$PROJECT_ROOT/.logs/zen-miner.log"
PID_FILE="$PROJECT_ROOT/.zen-miner.pid"
mkdir -p "$(dirname "$LOG_FILE")"

case "$1" in
  start)
    if [[ -f "$PID_FILE" ]]; then
      pid=$(cat "$PID_FILE" 2>/dev/null || true)
      if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
        echo "✓ Running (pid $pid)"
        exit 0
      fi
    fi
    echo "[$(date)] Starting..." >> "$LOG_FILE"
    if command -v flutter >/dev/null 2>&1; then
      nohup bash -c "cd '$PROJECT_ROOT' && flutter run -d web" >> "$LOG_FILE" 2>&1 &
    elif command -v dart >/dev/null 2>&1; then
      nohup bash -c "cd '$PROJECT_ROOT' && dart run" >> "$LOG_FILE" 2>&1 &
    else
      nohup bash -c "while true; do echo '[$(date)]' Running; sleep 60; done" >> "$LOG_FILE" 2>&1 &
    fi
    echo $! > "$PID_FILE"
    echo "✓ Started"
    ;;
  stop)
    if [[ -f "$PID_FILE" ]]; then
      kill $(cat "$PID_FILE") 2>/dev/null || true
      rm -f "$PID_FILE"
      echo "✓ Stopped"
    fi
    ;;
  status)
    if [[ -f "$PID_FILE" ]]; then
      pid=$(cat "$PID_FILE" 2>/dev/null || true)
      if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
        echo "✓ Running (PID: $pid)"
        exit 0
      fi
    fi
    echo "✗ Not running"
    exit 1
    ;;
  logs)
    tail -f "$LOG_FILE"
    ;;
  config)
    cat "$PROJECT_ROOT/.zen-miner-config.json"
    ;;
esac
EOF

chmod +x bin/zen-miner
```

Puis la santé :

```bash
cat > bin/zen-miner-health <<'EOF'
#!/bin/bash
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PID_FILE="$PROJECT_ROOT/.zen-miner.pid"
echo "=== ZEN-MINER HEALTH ==="
if [[ -f "$PID_FILE" ]]; then
  pid=$(cat "$PID_FILE" 2>/dev/null || true)
  if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
    echo "✓ Running (PID: $pid)"
  else
    echo "✗ Not alive"
  fi
else
  echo "✗ Not started"
fi
EOF

chmod +x bin/zen-miner-health
```

Puis l'intégration shell :

```bash
cat >> ~/.bashrc <<'EOF'

# ZEN-MINER
export ZEN_MINER_ROOT="/root/zen-miner"
export PATH="$ZEN_MINER_ROOT/bin:$PATH"
alias zen-miner='$ZEN_MINER_ROOT/bin/zen-miner'
EOF

source ~/.bashrc
```

Puis tester :

```bash
zen-miner start
zen-miner status
zen-miner logs
```

---

## Commandes Disponibles

| Commande | Effet |
|----------|-------|
| `zen-miner start` | Démarrer le service |
| `zen-miner stop` | Arrêter le service |
| `zen-miner restart` | Redémarrer |
| `zen-miner status` | Vérifier l'état |
| `zen-miner logs` | Afficher logs en direct |
| `zen-miner config` | Voir configuration |
| `zen-miner-health` | Vérifier la santé |

---

## Fichiers Créés

```
zen-miner/
├── .zen-miner-config.json      # Config principale
├── .zen-miner.pid               # PID du processus
├── bin/
│   ├── zen-miner               # Script principal
│   └── zen-miner-health        # Vérification santé
├── .logs/
│   └── zen-miner.log           # Logs du service
├── .data/                       # Données
└── .config/                     # Config additionnelle
```

---

## Dépannage

```bash
# Voir les logs
zen-miner logs

# Vérifier config
zen-miner config

# Vérifier santé
zen-miner-health

# Voir processus
ps aux | grep zen-miner

# Tuer manuellement
kill -9 $(cat zen-miner/.zen-miner.pid)
```

---

## Termux Spécifique

Sur Termux, si vous voulez que le service survive à la fermeture de l'app :

```bash
cat >> ~/.bashrc <<'EOF'

# Keep Termux running
if command -v termux-wake-lock &>/dev/null; then
  termux-wake-lock
fi
EOF
```

Puis relancer : `source ~/.bashrc`

