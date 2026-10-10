#!/data/data/com.termux/files/usr/bin/bash
# zen-miner Auto-Startup Script for Termux Boot

sleep 3

export HOME=/data/data/com.termux/files/home
export PATH=$HOME/zen-miner/bin:$PATH

# Start zen-miner
$HOME/zen-miner/bin/zen-miner start

# Send notification
if command -v termux-notification &>/dev/null; then
  termux-notification \
    --title "zen-miner" \
    --content "Service started at $(date)" \
    --id 1001 \
    --ongoing
fi

# Keep wake lock
if command -v termux-wake-lock &>/dev/null; then
  termux-wake-lock
fi
