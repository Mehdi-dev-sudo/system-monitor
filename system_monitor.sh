#!/usr/bin/env bash
# system_monitor.sh - Lightweight System Resource Monitor
# Author: Mehdi
# License: MIT
# Version: 2.0.0

set -euo pipefail  # Exit on error, undefined vars, pipe failures

#===========================================
# Constants and Configuration
#===========================================
readonly SCRIPT_NAME="System Monitor"
readonly VERSION="2.0.0"
readonly CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/system-monitor/config"
readonly LOG_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/system-monitor/logs"
readonly ALERT_FILE="$LOG_DIR/alerts.log"

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly BOLD='\033[1m'
readonly NC='\033[0m'

# Icons
readonly CHECK="✓"
readonly WARN="⚠"
readonly CRIT="⛔"
readonly INFO="ℹ"

#===========================================
# Signal Handlers
#===========================================
cleanup() {
    echo -e "\n${YELLOW}Shutting down gracefully...${NC}"
    tput cnorm 2>/dev/null || true  # Restore cursor
    exit 0
}

trap cleanup SIGINT SIGTERM

#===========================================
# Logging Functions
#===========================================
log() {
    local level=$1
    shift
    local message="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$ALERT_FILE"
}

error() {
    echo -e "${RED}Error: $*${NC}" >&2
    log "ERROR" "$*"
}

warn() {
    echo -e "${YELLOW}Warning: $*${NC}" >&2
    log "WARN" "$*"
}

info() {
    echo -e "${CYAN}${INFO} $*${NC}"
}

#===========================================
# Dependency Checking
#===========================================
check_dependencies() {
    local missing_deps=()
    local required_cmds=(awk sed grep tail head wc date hostname uname)
    
    for cmd in "${required_cmds[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        error "Missing required commands: ${missing_deps[*]}"
        echo "Please install the missing utilities and try again."
        exit 1
    fi
}

#===========================================
# Initialization
#===========================================
init_system() {
    local config_dir
    config_dir=$(dirname "$CONFIG_FILE")
    
    # Create directories
    for dir in "$config_dir" "$LOG_DIR"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir" || {
                error "Cannot create directory: $dir"
                exit 1
            }
        fi
    done
    
    # Initialize alert log
    if [ ! -f "$ALERT_FILE" ]; then
        touch "$ALERT_FILE" || {
            error "Cannot create alert log file"
            exit 1
        }
        log "INFO" "System Monitor initialized"
    fi
    
    # Create default config if needed
    if [ ! -f "$CONFIG_FILE" ]; then
        create_default_config
    fi
}

#===========================================
# Configuration Management
#===========================================
create_default_config() {
    cat > "$CONFIG_FILE" << 'EOF'
# System Monitor Configuration
# Threshold values (0-100)
CPU_THRESHOLD=80
MEM_THRESHOLD=85
DISK_THRESHOLD=90

# Monitoring interval (seconds)
CHECK_INTERVAL=5

# Alert notifications (true/false)
ENABLE_ALERTS=true

# Log retention (days)
LOG_RETENTION=30
EOF
    info "Default configuration created at $CONFIG_FILE"
}

load_config() {
    # Default values
    CPU_THRESHOLD=80
    MEM_THRESHOLD=85
    DISK_THRESHOLD=90
    CHECK_INTERVAL=5
    ENABLE_ALERTS=true
    LOG_RETENTION=30
    
    if [ ! -f "$CONFIG_FILE" ]; then
        warn "Config file not found. Using defaults."
        create_default_config
        return
    fi
    
    # Safe config parsing
    while IFS='=' read -r key value; do
        # Strip whitespace and comments
        key=$(echo "$key" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        value=$(echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | cut -d'#' -f1)
        
        # Skip empty lines and comments
        [[ -z "$key" || "$key" =~ ^# ]] && continue
        
        # Validate and assign
        case "$key" in
            CPU_THRESHOLD|MEM_THRESHOLD|DISK_THRESHOLD)
                if [[ "$value" =~ ^[0-9]+$ ]] && [ "$value" -ge 0 ] && [ "$value" -le 100 ]; then
                    declare -g "$key=$value"
                else
                    warn "Invalid value for $key: $value (using default)"
                fi
                ;;
            CHECK_INTERVAL)
                if [[ "$value" =~ ^[0-9]+$ ]] && [ "$value" -gt 0 ]; then
                    declare -g "$key=$value"
                else
                    warn "Invalid value for $key: $value (using default)"
                fi
                ;;
            ENABLE_ALERTS)
                if [[ "$value" =~ ^(true|false)$ ]]; then
                    declare -g "$key=$value"
                fi
                ;;
            LOG_RETENTION)
                if [[ "$value" =~ ^[0-9]+$ ]]; then
                    declare -g "$key=$value"
                fi
                ;;
        esac
    done < "$CONFIG_FILE"
}

update_config() {
    local key=$1
    local value=$2
    
    if [ ! -f "$CONFIG_FILE" ]; then
        error "Config file not found"
        return 1
    fi
    
    # Cross-platform sed
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/^${key}=.*/${key}=${value}/" "$CONFIG_FILE"
    else
        sed -i "s/^${key}=.*/${key}=${value}/" "$CONFIG_FILE"
    fi
    
    info "Configuration updated: $key=$value"
}

#===========================================
# System Monitoring Functions
#===========================================
get_cpu_usage() {
    local cpu_usage=0
    
    # Method 1: Try /proc/stat (Linux only)
    if [ -f /proc/stat ]; then
        local stats1 stats2
        stats1=$(grep '^cpu ' /proc/stat | awk '{print $2+$3+$4+$5+$6+$7+$8}')
        sleep 0.1
        stats2=$(grep '^cpu ' /proc/stat | awk '{print $2+$3+$4+$5+$6+$7+$8}')
        
        if [[ -n "$stats1" && -n "$stats2" && "$stats2" -gt "$stats1" ]]; then
            local idle1 idle2
            idle1=$(grep '^cpu ' /proc/stat | head -1 | awk '{print $5}')
            sleep 0.1
            idle2=$(grep '^cpu ' /proc/stat | tail -1 | awk '{print $5}')
            
            local total_diff=$((stats2 - stats1))
            local idle_diff=$((idle2 - idle1))
            
            if [ "$total_diff" -gt 0 ]; then
                cpu_usage=$(( (total_diff - idle_diff) * 100 / total_diff ))
            fi
        fi
    fi
    
    # Method 2: Fallback to top (universal but slower)
    if [ "$cpu_usage" -eq 0 ] && command -v top &> /dev/null; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            cpu_usage=$(top -l 2 -n 0 2>/dev/null | grep "CPU usage" | tail -1 | awk '{print $3}' | cut -d'%' -f1 | cut -d'.' -f1)
        else
            # Linux
            cpu_usage=$(top -bn2 2>/dev/null | grep "Cpu(s)" | tail -1 | awk '{print 100 - $8}' | cut -d'.' -f1)
        fi
    fi
    
    # Ensure valid number
    if ! [[ "$cpu_usage" =~ ^[0-9]+$ ]]; then
        cpu_usage=0
    fi
    
    echo "$cpu_usage"
}

get_memory_usage() {
    local mem_percent=0
    
    # Method 1: /proc/meminfo (Linux)
    if [ -f /proc/meminfo ]; then
        local mem_total mem_available
        mem_total=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        mem_available=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
        
        if [[ -n "$mem_total" && -n "$mem_available" && "$mem_total" -gt 0 ]]; then
            local mem_used=$((mem_total - mem_available))
            mem_percent=$((mem_used * 100 / mem_total))
        fi
    # Method 2: free command
    elif command -v free &> /dev/null; then
        local mem_total mem_used
        mem_total=$(free 2>/dev/null | awk '/^Mem:/ {print $2}')
        mem_used=$(free 2>/dev/null | awk '/^Mem:/ {print $3}')
        
        if [[ -n "$mem_total" && "$mem_total" -gt 0 ]]; then
            mem_percent=$((mem_used * 100 / mem_total))
        fi
    # Method 3: vm_stat (macOS)
    elif command -v vm_stat &> /dev/null; then
        local page_size pages_free pages_active pages_inactive pages_wired
        page_size=$(pagesize 2>/dev/null || echo 4096)
        pages_free=$(vm_stat | grep "Pages free" | awk '{print $3}' | tr -d '.')
        pages_active=$(vm_stat | grep "Pages active" | awk '{print $3}' | tr -d '.')
        pages_inactive=$(vm_stat | grep "Pages inactive" | awk '{print $3}' | tr -d '.')
        pages_wired=$(vm_stat | grep "Pages wired down" | awk '{print $4}' | tr -d '.')
        
        local mem_used=$(( (pages_active + pages_inactive + pages_wired) * page_size / 1024 / 1024 ))
        local mem_total=$(( (pages_free + pages_active + pages_inactive + pages_wired) * page_size / 1024 / 1024 ))
        
        if [ "$mem_total" -gt 0 ]; then
            mem_percent=$((mem_used * 100 / mem_total))
        fi
    fi
    
    echo "$mem_percent"
}

get_disk_usage() {
    local disk_usage=0
    
    if command -v df &> /dev/null; then
        # Get root filesystem usage
        disk_usage=$(df -h / 2>/dev/null | awk 'NR==2 {print $5}' | tr -d '%')
        
        # Validate
        if ! [[ "$disk_usage" =~ ^[0-9]+$ ]]; then
            disk_usage=0
        fi
    fi
    
    echo "$disk_usage"
}

get_process_count() {
    if command -v ps &> /dev/null; then
        ps aux 2>/dev/null | wc -l | awk '{print $1}'
    else
        echo "N/A"
    fi
}

get_load_average() {
    if command -v uptime &> /dev/null; then
        uptime 2>/dev/null | awk -F'load average:' '{print $2}' | sed 's/^[[:space:]]*//'
    else
        echo "N/A"
    fi
}

get_uptime() {
    if command -v uptime &> /dev/null; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            uptime | awk '{print $3" "$4}' | sed 's/,$//'
        else
            uptime -p 2>/dev/null || uptime | awk '{print $3" "$4}' | sed 's/,$//'
        fi
    else
        echo "N/A"
    fi
}

#===========================================
# Display Functions
#===========================================
show_progress_bar() {
    local percentage=$1
    local bar_length=25
    
    # Remove decimals and validate
    percentage=${percentage%.*}
    [[ ! "$percentage" =~ ^[0-9]+$ ]] && percentage=0
    [[ "$percentage" -lt 0 ]] && percentage=0
    [[ "$percentage" -gt 100 ]] && percentage=100
    
    local filled=$((percentage * bar_length / 100))
    local empty=$((bar_length - filled))
    
    # Color based on percentage
    local bar_color=$GREEN
    [ "$percentage" -ge 70 ] && bar_color=$YELLOW
    [ "$percentage" -ge 90 ] && bar_color=$RED
    
    printf "${bar_color}["
    printf "%${filled}s" | tr ' ' '█'
    printf "%${empty}s" | tr ' ' '░'
    printf "]${NC}"
}

get_status() {
    local value=$1
    local threshold=$2
    local warning_threshold=$((threshold - 10))
    
    [[ ! "$value" =~ ^[0-9]+$ ]] && value=0
    
    if [ "$value" -ge "$threshold" ]; then
        echo -e "${RED}${CRIT} CRITICAL${NC}"
        return 2
    elif [ "$value" -ge "$warning_threshold" ]; then
        echo -e "${YELLOW}${WARN} WARNING${NC}"
        return 1
    else
        echo -e "${GREEN}${CHECK} NORMAL${NC}"
        return 0
    fi
}

display_header() {
    echo "════════════════════════════════════════════════════════"
    echo -e "  ${BOLD}${CYAN}$SCRIPT_NAME v$VERSION${NC}"
    echo "════════════════════════════════════════════════════════"
    echo
}

display_system_status() {
    clear
    display_header
    
    # Gather metrics
    local cpu mem disk processes load uptime
    cpu=$(get_cpu_usage)
    mem=$(get_memory_usage)
    disk=$(get_disk_usage)
    processes=$(get_process_count)
    load=$(get_load_average)
    uptime=$(get_uptime)
    
    # Display metrics
    printf "${BOLD}CPU Usage:${NC}      "
    show_progress_bar "$cpu"
    printf " %3d%% " "$cpu"
    get_status "$cpu" "$CPU_THRESHOLD"
    echo
    
    printf "${BOLD}Memory Usage:${NC}   "
    show_progress_bar "$mem"
    printf " %3d%% " "$mem"
    get_status "$mem" "$MEM_THRESHOLD"
    echo
    
    printf "${BOLD}Disk Usage:${NC}     "
    show_progress_bar "$disk"
    printf " %3d%% " "$disk"
    get_status "$disk" "$DISK_THRESHOLD"
    echo
    
    echo
    echo "────────────────────────────────────────────────────────"
    printf "${BOLD}System Information:${NC}\n"
    printf "  Hostname:      %s\n" "$(hostname)"
    printf "  Uptime:        %s\n" "$uptime"
    printf "  Processes:     %s\n" "$processes"
    printf "  Load Average:  %s\n" "$load"
    printf "  Timestamp:     %s\n" "$(date '+%Y-%m-%d %H:%M:%S')"
    echo "────────────────────────────────────────────────────────"
    
    # Check and log alerts
    check_alerts "$cpu" "$mem" "$disk"
}

check_alerts() {
    local cpu=$1
    local mem=$2
    local disk=$3
    
    if [ "$ENABLE_ALERTS" != "true" ]; then
        return
    fi
    
    [[ "$cpu" =~ ^[0-9]+$ ]] && [ "$cpu" -ge "$CPU_THRESHOLD" ] && \
        log "CRITICAL" "CPU usage is ${cpu}% (threshold: ${CPU_THRESHOLD}%)"
    
    [[ "$mem" =~ ^[0-9]+$ ]] && [ "$mem" -ge "$MEM_THRESHOLD" ] && \
        log "CRITICAL" "Memory usage is ${mem}% (threshold: ${MEM_THRESHOLD}%)"
    
    [[ "$disk" =~ ^[0-9]+$ ]] && [ "$disk" -ge "$DISK_THRESHOLD" ] && \
        log "CRITICAL" "Disk usage is ${disk}% (threshold: ${DISK_THRESHOLD}%)"
}

#===========================================
# Continuous Monitoring
#===========================================
continuous_monitor() {
    info "Starting continuous monitoring (Press Ctrl+C to stop)"
    sleep 2
    
    while true; do
        display_system_status
        echo
        echo -e "${BLUE}Next update in ${CHECK_INTERVAL}s...${NC}"
        sleep "$CHECK_INTERVAL"
    done
}

#===========================================
# Alert History
#===========================================
show_alerts() {
    clear
    display_header
    echo -e "${BOLD}Recent Alerts (Last 30 entries)${NC}"
    echo "────────────────────────────────────────────────────────"
    echo
    
    if [ ! -f "$ALERT_FILE" ] || [ ! -s "$ALERT_FILE" ]; then
        info "No alerts recorded yet."
        return
    fi
    
    tail -n 30 "$ALERT_FILE" | while IFS= read -r line; do
        if [[ $line == *"CRITICAL"* ]]; then
            echo -e "${RED}$line${NC}"
        elif [[ $line == *"WARN"* ]]; then
            echo -e "${YELLOW}$line${NC}"
        elif [[ $line == *"ERROR"* ]]; then
            echo -e "${RED}$line${NC}"
        else
            echo "$line"
        fi
    done
}

#===========================================
# Configuration Menu
#===========================================
configure_settings() {
    while true; do
        clear
        display_header
        echo -e "${BOLD}Configuration Settings${NC}"
        echo "────────────────────────────────────────────────────────"
        echo
        
        load_config
        
        echo "Current Settings:"
        echo "  1) CPU Threshold:        ${CPU_THRESHOLD}%"
        echo "  2) Memory Threshold:     ${MEM_THRESHOLD}%"
        echo "  3) Disk Threshold:       ${DISK_THRESHOLD}%"
        echo "  4) Check Interval:       ${CHECK_INTERVAL}s"
        echo "  5) Enable Alerts:        ${ENABLE_ALERTS}"
        echo "  6) Log Retention:        ${LOG_RETENTION} days"
        echo "  7) Return to Main Menu"
        echo
        
        read -rp "Select option [1-7]: " choice
        
        case $choice in
            1|2|3)
                local key
                case $choice in
                    1) key="CPU_THRESHOLD" ;;
                    2) key="MEM_THRESHOLD" ;;
                    3) key="DISK_THRESHOLD" ;;
                esac
                
                read -rp "Enter new threshold (0-100): " new_value
                if [[ $new_value =~ ^[0-9]+$ ]] && [ "$new_value" -ge 0 ] && [ "$new_value" -le 100 ]; then
                    update_config "$key" "$new_value"
                else
                    error "Invalid value! Must be between 0-100"
                    sleep 2
                fi
                ;;
            4)
                read -rp "Enter check interval in seconds (min 1): " new_value
                if [[ $new_value =~ ^[0-9]+$ ]] && [ "$new_value" -gt 0 ]; then
                    update_config "CHECK_INTERVAL" "$new_value"
                else
                    error "Invalid value! Must be greater than 0"
                    sleep 2
                fi
                ;;
            5)
                read -rp "Enable alerts? (true/false): " new_value
                if [[ $new_value =~ ^(true|false)$ ]]; then
                    update_config "ENABLE_ALERTS" "$new_value"
                else
                    error "Invalid value! Must be 'true' or 'false'"
                    sleep 2
                fi
                ;;
            6)
                read -rp "Enter log retention in days: " new_value
                if [[ $new_value =~ ^[0-9]+$ ]]; then
                    update_config "LOG_RETENTION" "$new_value"
                else
                    error "Invalid value! Must be a number"
                    sleep 2
                fi
                ;;
            7)
                return
                ;;
            *)
                error "Invalid option!"
                sleep 1
                ;;
        esac
    done
}

#===========================================
# System Report
#===========================================
generate_report() {
    clear
    display_header
    
    local report_file="$LOG_DIR/report_$(date +%Y%m%d_%H%M%S).txt"
    
    info "Generating comprehensive system report..."
    
    {
        echo "═══════════════════════════════════════════════════════"
        echo "  System Monitor - Comprehensive Report"
        echo "═══════════════════════════════════════════════════════"
        echo
        echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
        echo
        echo "─── System Information ───"
        echo "Hostname:       $(hostname)"
        echo "Kernel:         $(uname -sr)"
        echo "Uptime:         $(get_uptime)"
        echo
        echo "─── Resource Usage ───"
        echo "CPU:            $(get_cpu_usage)%"
        echo "Memory:         $(get_memory_usage)%"
        echo "Disk (root):    $(get_disk_usage)%"
        echo "Processes:      $(get_process_count)"
        echo "Load Average:   $(get_load_average)"
        echo
        echo "─── Disk Usage ───"
        if command -v df &> /dev/null; then
            df -h 2>/dev/null | head -n 10
        else
            echo "df command not available"
        fi
        echo
        echo "─── Top Processes (by CPU) ───"
        if command -v ps &> /dev/null; then
            if [[ "$OSTYPE" == "darwin"* ]]; then
                ps aux | head -n 11
            else
                ps aux --sort=-%cpu 2>/dev/null | head -n 11 || ps aux | head -n 11
            fi
        else
            echo "ps command not available"
        fi
        echo
        echo "─── Top Processes (by Memory) ───"
        if command -v ps &> /dev/null; then
            if [[ "$OSTYPE" == "darwin"* ]]; then
                ps aux -m | head -n 11
            else
                ps aux --sort=-%mem 2>/dev/null | head -n 11 || ps aux | head -n 11
            fi
        else
            echo "ps command not available"
        fi
        echo
        echo "─── Recent Alerts ───"
        if [ -f "$ALERT_FILE" ] && [ -s "$ALERT_FILE" ]; then
            tail -n 20 "$ALERT_FILE"
        else
            echo "No alerts recorded"
        fi
        echo
        echo "═══════════════════════════════════════════════════════"
    } | tee "$report_file"
    
    echo
    info "Report saved to: $report_file"
}

#===========================================
# Log Cleanup
#===========================================
cleanup_old_logs() {
    if [ -d "$LOG_DIR" ]; then
        find "$LOG_DIR" -name "report_*.txt" -type f -mtime "+${LOG_RETENTION}" -delete 2>/dev/null || true
        info "Old log files cleaned up"
    fi
}

#===========================================
# Main Menu
#===========================================
show_menu() {
    clear
    display_header
    
    cat << EOF
  ${BOLD}Main Menu${NC}
  
  1) Display Current Status
  2) Continuous Monitoring
  3) View Alert History
  4) Configuration Settings
  5) Generate System Report
  6) Cleanup Old Logs
  7) Exit
  
════════════════════════════════════════════════════════════
EOF
    
    read -rp "Select option [1-7]: " choice
}

#===========================================
# Main Function
#===========================================
main() {
    # Pre-flight checks
    check_dependencies
    
    # Initialize
    init_system
    load_config
    
    # Main loop
    while true; do
        show_menu
        
        case $choice in
            1)
                display_system_status
                echo
                read -rp "Press Enter to continue..."
                ;;
            2)
                continuous_monitor
                ;;
            3)
                show_alerts
                echo
                read -rp "Press Enter to continue..."
                ;;
            4)
                configure_settings
                load_config
                ;;
            5)
                generate_report
                echo
                read -rp "Press Enter to continue..."
                ;;
            6)
                cleanup_old_logs
                sleep 2
                ;;
            7)
                echo -e "${GREEN}${CHECK} Goodbye!${NC}"
                exit 0
                ;;
            *)
                error "Invalid option!"
                sleep 1
                ;;
        esac
    done
}

#===========================================
# Entry Point
#===========================================
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi
