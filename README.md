# System Monitor

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Bash](https://img.shields.io/badge/Bash-4.0+-green.svg)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20macOS-blue.svg)](https://github.com/Mehdi-dev-sudo/system-monitor)

Lightweight system monitoring tool with beautiful CLI interface and smart alerting. Zero dependencies, works out of the box.

---

## Features

- ⚡ **Zero Setup** — Download, run, done
- 📊 **Real-time Display** — Color-coded progress bars
- 🔔 **Smart Alerts** — Auto-logs threshold breaches
- ⚙️ **Configurable** — Adjust thresholds via config or menu
- 🌍 **Cross-Platform** — Linux & macOS support
- 💾 **Lightweight** — <1% CPU, ~3MB memory

---

## Quick Start
```bash
curl -O https://raw.githubusercontent.com/Mehdi-dev-sudo/system-monitor/main/system_monitor.sh
chmod +x system_monitor.sh
./system_monitor.sh

---

## Demo


════════════════════════════════════════════════════════════
  System Monitor v2.0.0
════════════════════════════════════════════════════════════

CPU Usage:      [████████████░░░░░░░░░░░░░]  45% ✓ NORMAL
Memory Usage:   [██████████████████░░░░░░░]  72% ⚠ WARNING
Disk Usage:     [███████████░░░░░░░░░░░░░░]  44% ✓ NORMAL

────────────────────────────────────────────────────────────
Hostname: myserver  |  Uptime: 3d 4h  |  Load: 0.45 0.52 0.48
────────────────────────────────────────────────────────────
```

**Menu Options:**
1. Display current status
2. Continuous monitoring (auto-refresh)
3. View alert history
4. Configure thresholds
5. Generate system report
6. Cleanup old logs

---

## Configuration

Edit `~/.config/system-monitor/config`:

bash
# Thresholds (0-100%)
CPU_THRESHOLD=80
MEM_THRESHOLD=85
DISK_THRESHOLD=90

# Behavior
CHECK_INTERVAL=5        # Refresh interval (seconds)
ENABLE_ALERTS=true      # Log when thresholds exceeded
LOG_RETENTION=30        # Delete logs older than N days

**Quick config:** Run script → Option 4 → Adjust values

---

## Installation (Optional)

**System-wide:**

bash
sudo install -m 755 system_monitor.sh /usr/local/bin/sysmon
sysmon  # Run from anywhere

**Uninstall:**

bash
sudo rm /usr/local/bin/sysmon
rm -rf ~/.config/system-monitor ~/.local/share/system-monitor

---

## Requirements

- Bash 4.0+
- Linux (any distro) or macOS 11+
- Standard Unix tools (awk, grep, df, ps)

**Tested on:** Ubuntu 20.04+, Debian 11+, macOS Big Sur+, Arch Linux

---

## Usage Examples

**Continuous monitoring:**

bash
./system_monitor.sh
# Select: 2 → Press Ctrl+C to stop

**Generate report:**

bash
./system_monitor.sh
# Select: 5 → Saved to ~/.local/share/system-monitor/logs/

**View alerts:**

bash
tail -20 ~/.local/share/system-monitor/logs/alerts.log

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Permission denied | `chmod +x system_monitor.sh` |
| CPU shows 0% | Linux: Check `/proc/stat` exists<br>macOS: Verify `top` works |
| Config not loading | Delete config file and restart script |

**Need help?** [Open an issue](https://github.com/Mehdi-dev-sudo/system-monitor/issues)

---

## Performance

| Metric | Value |
|--------|-------|
| Memory | ~3MB |
| CPU (active) | 0.5% |
| Startup | <100ms |

---

## Contributing

1. Fork and create feature branch
2. Test on Linux/macOS
3. Run `shellcheck system_monitor.sh`
4. Submit PR

**Ideas:** Network monitoring, email alerts, Docker stats

---

## License

MIT License — see [LICENSE](LICENSE)

---

## Author

**Mehdi**  
[@Mehdi-dev-sudo](https://github.com/Mehdi-dev-sudo)

---

<p align="center">⭐ <b>Star this repo if it's useful!</b></p>
