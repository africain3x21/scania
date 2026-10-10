# zen-miner - Setup Guide

## Installation sur Termux

### Étape 1 : Installation du script

```bash
chmod +x zen-miner/setup-universal.sh
./zen-miner/setup-universal.sh
```

### Étape 2 : Démarrer le service

```bash
zen-miner start
```

### Étape 3 : Vérifier le statut

```bash
zen-miner status
```

## Commandes disponibles

| Commande | Description |
|----------|-------------|
| `zen-miner start` | Démarrer le service |
| `zen-miner stop` | Arrêter le service |
| `zen-miner restart` | Redémarrer le service |
| `zen-miner status` | Vérifier le statut |
| `zen-miner logs` | Afficher les logs en direct |
| `zen-miner config` | Afficher la configuration |
| `zen-miner-health` | Vérifier la santé du service |

## Fichiers importants

- `.zen-miner-config.json` - Configuration principale
- `.zen-miner.pid` - Fichier PID du processus
- `.logs/zen-miner.log` - Fichier de logs
- `bin/zen-miner` - Script de contrôle principal
- `bin/zen-miner-health` - Vérification de santé

## Dépannage

### Le service ne démarre pas

```bash
# Vérifier les logs
zen-miner logs

# Vérifier la configuration
zen-miner config

# Vérifier la santé
zen-miner-health
```

### Pas de logs

```bash
# Créer les répertoires
mkdir -p .logs .data .config

# Relancer
zen-miner start
```

### Dépendances manquantes

Sur Termux :
```bash
pkg update
pkg install flutter  # ou dart
pkg install git
```

## Configuration

Le fichier `.zen-miner-config.json` contient :

- **paths** : Chemins du projet
- **service** : Configuration du service
- **integrations** : Intégrations (Termux, systemd, settings modal)
- **monitoring** : Surveillance du service

## Intégrations

### Termux
- Notifications persistantes
- Wake lock
- Arrière-plan

### Linux (systemd)
- Service utilisateur
- Démarrage automatique
- Logs systéme

### macOS
- Launch agent
- Background service

## Environnement

Après installation, la variable d'environnement `ZEN_MINER_ROOT` est définie dans votre `.bashrc` / `.zshrc`.

```bash
export ZEN_MINER_ROOT="/chemin/vers/zen-miner"
export PATH="$ZEN_MINER_ROOT/bin:$PATH"
```

## Support

- Logs: `zen-miner logs`
- Config: `zen-miner config`
- Santé: `zen-miner-health`
