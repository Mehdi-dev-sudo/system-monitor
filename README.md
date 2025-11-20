# System Monitor

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Bash](https://img.shields.io/badge/Bash-4.0+-green.svg)](https://www.gnu.org/software/bash/)

A lightweight, zero-dependency Bash script for real-time system monitoring with beautiful CLI interface and smart alerting.

---

## Why This Tool?

- **🚀 Zero Setup** - Download and run, no installation needed
- **📊 Beautiful Interface** - Color-coded progress bars and status indicators
- **⚡ Lightning Fast** - < 1% CPU usage, < 5MB memory footprint
- **🔔 Smart Alerts** - Automatic logging when thresholds are breached
- **🎯 Configurable** - Adjust thresholds to your needs
- **🌍 Cross-Platform** - Works on Linux and macOS out of the box

---

## Quick Start
```bash
# Download
curl -O https://raw.githubusercontent.com/yourusername/system-monitor/main/system_monitor.sh

# Make executable
chmod +x system_monitor.sh

# Run
./system_monitor.sh

**That's it!** The script will auto-configure on first run.

---

## Features

### Real-time Monitoring
Monitor CPU, memory, and disk usage with auto-refreshing display:


════════════════════════════════════════════════════════════
  System Monitor v2.0.0
════════════════════════════════════════════════════════════

CPU Usage:      [████████████░░░░░░░░░░░░░]  45% ✓ NORMAL
Memory Usage:   [██████████████████░░░░░░░]  72% ✓ NORMAL
Disk Usage:     [███████████░░░░░░░░░░░░░░]  44% ✓ NORMAL

────────────────────────────────────────────────────────────
System Information:
  Hostname:      myserver
  Uptime:        3 days
  Processes:     187
  Load Average:  0.45, 0.52, 0.48
────────────────────────────────────────────────────────────

### Interactive Menu

1. **Display Current Status** - Quick system snapshot
2. **Continuous Monitoring** - Auto-refresh every N seconds
3. **View Alert History** - See when thresholds were exceeded
4. **Configuration** - Adjust thresholds and intervals
5. **Generate Report** - Full system report with top processes
6. **Cleanup Logs** - Remove old log files

### Smart Alerting

Automatically logs when resources exceed thresholds:
- 🟢 **Normal** - Below threshold
- 🟡 **Warning** - Within 10% of threshold
- 🔴 **Critical** - Above threshold

Logs saved to `~/.local/share/system-monitor/logs/alerts.log`

---

## Configuration

Edit `~/.config/system-monitor/config`:

bash
# Thresholds (0-100%)
CPU_THRESHOLD=80
MEM_THRESHOLD=85
DISK_THRESHOLD=90

# Monitoring
CHECK_INTERVAL=5        # Refresh interval (seconds)
ENABLE_ALERTS=true      # Enable/disable logging

# Cleanup
LOG_RETENTION=30        # Delete logs older than N days

**Quick config via menu:**
- Run script → Select option 4 → Adjust values

---

## Requirements

**Minimum:**
- Bash 4.0+
- Standard Unix utilities (awk, grep, sed, df, ps)

**Tested on:**
- Ubuntu 20.04+
- Debian 11+
- CentOS 8+
- macOS 11+ (Big Sur and newer)
- Arch Linux

---

## Examples

### One-Time Check
bash
./system_monitor.sh
# Select option 1

### Continuous Monitoring (5s refresh)
bash
./system_monitor.sh
# Select option 2
# Press Ctrl+C to stop

### Generate Full Report
bash
./system_monitor.sh
# Select option 5
# Report saved to ~/.local/share/system-monitor/logs/

### Custom Alert Threshold
bash
./system_monitor.sh
# Select option 4
# Set CPU threshold to 60%
# Return to main menu and start monitoring

---

## File Locations

Following XDG Base Directory specification:

- **Config:** `~/.config/system-monitor/config`
- **Logs:** `~/.local/share/system-monitor/logs/`
  - `alerts.log` - Alert history
  - `report_*.txt` - Generated reports

---

## Troubleshooting

**Script won't run:**
bash
bash --version  # Check Bash version (need 4.0+)

**Permission denied:**
bash
chmod +x system_monitor.sh

**CPU showing 0%:**
bash
# Linux: Check /proc/stat exists
cat /proc/stat | grep "^cpu "

# macOS: Ensure 'top' command works
top -l 1 | grep "CPU usage"

**Config not loading:**
bash
# Check config file exists
cat ~/.config/system-monitor/config

# Recreate default config
rm ~/.config/system-monitor/config
./system_monitor.sh  # Will auto-create

---

## Installation (Optional)

**System-wide installation:**
bash
sudo cp system_monitor.sh /usr/local/bin/sysmon
sudo chmod +x /usr/local/bin/sysmon

# Now run from anywhere:
sysmon

**Uninstall:**
bash
sudo rm /usr/local/bin/sysmon
rm -rf ~/.config/system-monitor
rm -rf ~/.local/share/system-monitor

---

## Performance

Tested on Ubuntu 22.04 (4GB RAM):

| Metric | Value |
|--------|-------|
| Memory Usage | ~3MB |
| CPU Usage (monitoring) | ~0.5% |
| Startup Time | < 100ms |
| Disk I/O | Minimal |

---

## Contributing

Found a bug or want to add a feature?

1. Fork the repo
2. Create a branch: `git checkout -b feature-name`
3. Make your changes
4. Test on Linux/macOS
5. Submit a pull request

**Before PR:**
bash
shellcheck system_monitor.sh  # Lint your code

---

## License

MIT License - see [LICENSE](LICENSE) file

---

## Author

**Mehdi-dev-sudo**  
GitHub: [@Mehdi-dev-sudo](https://github.com/Mehdi-dev-sudo)

---

**Star ⭐ this repo if you find it useful!**
