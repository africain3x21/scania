# zen-miner - Complete Installation & Features

## ✅ Installed Features

### 1. Auto-Startup on Termux Boot
- Location: `~/.termux/boot/zen-miner-startup.sh`
- Automatically starts zen-miner when Termux boots
- Sends notification when service starts
- Keeps wake lock active

### 2. Live Dashboard (Terminal)
- Command: `zen-miner-dashboard`
- Real-time service monitoring
- Shows: Status, PID, Uptime, Memory, Device info, Recent logs
- Auto-refresh every 5 seconds
- Press Ctrl+C to exit

### 3. Web Dashboard (Browser)
- Command: `zen-miner-web 3000`
- Access: `http://localhost:3000`
- Beautiful green terminal-style UI
- Live status updates
- Control buttons: Start/Stop/Restart/Refresh
- Recent logs display
- Works on mobile browser

### 4. REST API Server
- Command: `zen-miner-api-server 3001`
- Endpoints:
  - `GET /api/status` - Get service status
  - `GET /api/logs` - Get recent logs
  - `POST /api/start` - Start service
  - `POST /api/stop` - Stop service
  - `POST /api/restart` - Restart service
- Perfect for integrations

### 5. Cloudflare Tunnel Integration
- Command: `zen-miner-install-cloudflare`
- Expose zen-miner to internet securely
- No port forwarding needed
- Access from anywhere
- Auto-configured for dashboard

### 6. Termux Notifications
- Command: `zen-miner-notify {start|stop|health|error}`
- Persistent notifications for service status
- Health check alerts
- Error notifications
- Examples:
  - `zen-miner-notify start`
  - `zen-miner-notify health "Process running"`
  - `zen-miner-notify error "Service crashed"`

### 7. Termux Boot Integration
- Auto-start service on device boot
- Acquire wake lock to prevent sleep
- Send startup notification
- Configured in `~/.termux/boot/zen-miner-startup.sh`

---

## 🚀 Quick Start

### Setup Everything at Once
```bash
zen-miner-full-setup
```

### Manual Setup

1. **Start the service**
   ```bash
   zen-miner start
   ```

2. **View terminal dashboard**
   ```bash
   zen-miner-dashboard
   ```

3. **Access web dashboard**
   ```bash
   zen-miner-web 3000
   ```
   Then open browser: `http://localhost:3000`

4. **Start API server**
   ```bash
   zen-miner-api-server 3001
   ```
   Test: `curl http://localhost:3001/api/status`

5. **Setup Cloudflare**
   ```bash
   zen-miner-install-cloudflare
   ```

6. **Enable notifications**
   ```bash
   zen-miner-notify start
   zen-miner-notify health "Service is running"
   ```

---

## 📊 Service Commands

```bash
# Core Commands
zen-miner start         # Start service
zen-miner stop          # Stop service
zen-miner restart       # Restart service
zen-miner status        # Check status
zen-miner logs          # View live logs
zen-miner config        # Show configuration

# Dashboard & Monitoring
zen-miner-dashboard     # Terminal dashboard (live)
zen-miner-web 3000      # Web dashboard (browser)
zen-miner-api-server    # REST API server
zen-miner-health        # Health check

# Integrations
zen-miner-notify        # Send notifications
zen-miner-install-cloudflare  # Setup Cloudflare tunnel

# Auto-start
zen-miner-full-setup    # Complete setup wizard
```

---

## 🌐 Access Points

| Service | Port | URL |
|---------|------|-----|
| zen-miner | 8080 | http://localhost:8080 |
| Web Dashboard | 3000 | http://localhost:3000 |
| API Server | 3001 | http://localhost:3001 |
| Cloudflare | custom | https://zen-miner.example.com |

---

## 📱 Termux Specific Features

- **Wake Lock**: Prevents device from sleeping
- **Notifications**: Persistent status indicators
- **Boot Script**: Auto-start on device reboot
- **Notification Channel**: Ongoing notification while running
- **Storage Access**: Full file system access

---

## 🔧 Configuration Files

```
~/zen-miner/
├── .zen-miner-config.json      # Main config
├── .zen-miner.pid              # Process ID
├── bin/
│   ├── zen-miner               # Main service
│   ├── zen-miner-dashboard     # Terminal UI
│   ├── zen-miner-web           # Web server
│   ├── zen-miner-api-server    # REST API
│   ├── zen-miner-notify        # Notifications
│   ├── zen-miner-health        # Health check
│   ├── zen-miner-install-cloudflare
│   └── zen-miner-full-setup    # Setup wizard
├── dashboard/
│   └── index.html              # Web UI
└── .logs/
    └── zen-miner.log           # Service logs

~/.termux/
└── boot/
    └── zen-miner-startup.sh    # Auto-start script

~/.config/cloudflared/
└── config.yml                  # Cloudflare config
```

---

## 🔐 Security Notes

- API server listens on localhost only (no external access)
- Cloudflare tunnel authenticates with your account
- Logs stored locally in `~/.logs/`
- PID file for process tracking
- No hardcoded credentials

---

## ⚠️ Troubleshooting

### Service won't start
```bash
zen-miner logs
```

### Dashboard not loading
```bash
# Make sure web server is running
zen-miner-web 3000

# Test API
curl http://localhost:3001/api/status
```

### Notifications not working
```bash
# Check if termux-notification is available
command -v termux-notification

# Try manually
termux-notification --title "Test" --content "Works!"
```

### Cloudflare tunnel not connecting
```bash
# Re-authenticate
$HOME/bin/cloudflared tunnel login

# Check config
cat ~/.config/cloudflared/config.yml
```

---

## 🎯 Use Cases

1. **Always-on Service**: Run on Termux device 24/7
2. **Remote Monitoring**: Access dashboard from anywhere via Cloudflare
3. **Mobile Deployment**: Run services on Android phone
4. **Development**: Test services on real mobile device
5. **IoT**: Turn Android phone into IoT edge node

---

## 📞 Support

For issues, check:
1. Logs: `zen-miner logs`
2. Status: `zen-miner status`
3. Health: `zen-miner-health`
4. Dashboard: `zen-miner-dashboard`

