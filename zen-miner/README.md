# zen-miner

Projet renommé avec la version mise à jour et les nouvelles intégrations.

## Installation

```bash
chmod +x zen-miner/setup-universal.sh
./zen-miner/setup-universal.sh
```

## Utilisation

```bash
zen-miner start
zen-miner status
zen-miner logs
zen-miner config
```

## Fonctionnalités

- Détection automatique du système
- Support Termux, Linux, macOS, WSL
- Service d’arrière-plan
- Contrôle de santé
- Intégration avec les paramètres existants
- Fallback sans Flutter/Dart

## Fichiers principaux

- `zen-miner/setup-universal.sh`
- `bin/zen-miner`
- `.zen-miner-config.json`
- `.logs/`
