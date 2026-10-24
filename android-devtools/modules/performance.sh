#!/data/data/com.termux/files/usr/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/colors.sh" 2>/dev/null

performance_menu() {
  while true; do
    header
    echo -e "  ${WHITE}${BOLD}PERFORMANCE MONITOR${NC}"
    echo ""
    echo -e "  ${CYAN}[1]${NC}  Live CPU & RAM Dashboard (refreshes every 2s)"
    echo -e "  ${CYAN}[2]${NC}  htop — Interactive process manager"
    echo -e "  ${CYAN}[3]${NC}  CPU Frequency per-core (snapshot)"
    echo -e "  ${CYAN}[4]${NC}  GPU Load & Frequency"
    echo -e "  ${CYAN}[5]${NC}  All Thermal Zones (temps)"
    echo -e "  ${CYAN}[6]${NC}  Top Memory Consumers"
    echo -e "  ${CYAN}[7]${NC}  I/O Stats (disk read/write)"
    echo -e "  ${CYAN}[8]${NC}  Battery Live Monitor"
    echo -e "  ${CYAN}[9]${NC}  Network Bandwidth Live"
    echo ""
    echo -e "  ${RED}[b]${NC}  Back"
    echo ""
    echo -ne "  ${BOLD}Choice → ${NC}"
    read -r choice

    case "$choice" in
      1) live_dashboard ;;
      2) htop 2>/dev/null || top ;;
      3) cpu_frequencies ;;
      4) gpu_info ;;
      5) thermal_zones ;;
      6) memory_consumers ;;
      7) io_stats ;;
      8) battery_live ;;
      9) network_bandwidth ;;
      b|B) return ;;
      *) warn "Invalid"; sleep 1 ;;
    esac
  done
}

live_dashboard() {
  info "Live dashboard — Ctrl+C to stop"
  echo ""
  while true; do
    clear
    echo -e "${CYAN}${BOLD}  ── LIVE PERFORMANCE DASHBOARD ─────────────────────────────── $(date '+%H:%M:%S') ──${NC}"
    echo ""

    # CPU usage
    CPU_IDLE=$(awk '/cpu / {idle=$5; total=0; for(i=2;i<=NF;i++) total+=$i; printf "%.1f", idle/total*100}' /proc/stat)
    CPU_USED=$(awk "BEGIN{printf \"%.1f\", 100 - $CPU_IDLE}")
    CPU_BAR=$(awk "BEGIN{
      n=int($CPU_USED/5)
      bar=\"\"
      for(i=0;i<n;i++) bar=bar\"█\"
      for(i=n;i<20;i++) bar=bar\"░\"
      print bar
    }")
    echo -e "  ${GREEN}CPU Usage:${NC}   [${RED}${CPU_BAR}${NC}] ${CPU_USED}%"

    # RAM
    MEM_TOTAL=$(awk '/MemTotal/{print $2}' /proc/meminfo)
    MEM_AVAIL=$(awk '/MemAvailable/{print $2}' /proc/meminfo)
    MEM_USED=$((MEM_TOTAL - MEM_AVAIL))
    MEM_PCT=$(awk "BEGIN{printf \"%.1f\", $MEM_USED/$MEM_TOTAL*100}")
    MEM_USED_MB=$((MEM_USED / 1024))
    MEM_TOTAL_MB=$((MEM_TOTAL / 1024))
    MEM_BAR=$(awk "BEGIN{
      n=int($MEM_PCT/5)
      bar=\"\"
      for(i=0;i<n;i++) bar=bar\"█\"
      for(i=n;i<20;i++) bar=bar\"░\"
      print bar
    }")
    echo -e "  ${GREEN}RAM:${NC}         [${YELLOW}${MEM_BAR}${NC}] ${MEM_PCT}% (${MEM_USED_MB}/${MEM_TOTAL_MB} MB)"

    # Swap
    SWAP_TOTAL=$(awk '/SwapTotal/{print $2}' /proc/meminfo)
    SWAP_FREE=$(awk '/SwapFree/{print $2}' /proc/meminfo)
    if [ "$SWAP_TOTAL" -gt 0 ]; then
      SWAP_USED=$((SWAP_TOTAL - SWAP_FREE))
      SWAP_PCT=$(awk "BEGIN{printf \"%.1f\", $SWAP_USED/$SWAP_TOTAL*100}")
      echo -e "  ${GREEN}Swap:${NC}        ${SWAP_PCT}% used ($((SWAP_USED/1024))/$((SWAP_TOTAL/1024)) MB)"
    fi

    echo ""

    # CPU frequencies
    echo -ne "  ${GREEN}CPU Cores:${NC}   "
    core=0
    for f in /sys/devices/system/cpu/cpu[0-9]*/cpufreq/scaling_cur_freq; do
      [ -f "$f" ] && echo -ne "c${core}:$(($(cat "$f")/1000))MHz " && core=$((core+1))
    done
    echo ""

    # Temps
    echo -ne "  ${GREEN}Temps:${NC}       "
    for zone in /sys/class/thermal/thermal_zone*/temp; do
      [ -f "$zone" ] && {
        raw=$(cat "$zone" 2>/dev/null)
        [ "${#raw}" -gt 3 ] && t=$((raw/1000)) || t=$raw
        [ "$t" -gt 0 ] 2>/dev/null && echo -ne "${t}°C "
      }
    done
    echo ""

    # Battery
    BAT="/sys/class/power_supply/battery"
    if [ -d "$BAT" ]; then
      BAT_CAP=$(cat "$BAT/capacity" 2>/dev/null)
      BAT_STATUS=$(cat "$BAT/status" 2>/dev/null)
      BAT_CURRENT_RAW=$(cat "$BAT/current_now" 2>/dev/null || echo "0")
      BAT_CURRENT=$(awk "BEGIN{printf \"%.0f\", ${BAT_CURRENT_RAW#-}/1000}")
      echo -e "  ${GREEN}Battery:${NC}     ${BAT_CAP}% — ${BAT_STATUS} @ ${BAT_CURRENT}mA"
    fi

    # Network I/O
    echo -ne "  ${GREEN}Network:${NC}     "
    for iface in wlan0 rmnet_data0 eth0; do
      RX_FILE="/sys/class/net/$iface/statistics/rx_bytes"
      TX_FILE="/sys/class/net/$iface/statistics/tx_bytes"
      [ -f "$RX_FILE" ] && {
        RX=$(cat "$RX_FILE")
        TX=$(cat "$TX_FILE")
        echo -ne "${iface} RX:$((RX/1024/1024))MB TX:$((TX/1024/1024))MB  "
      }
    done
    echo ""

    echo ""
    echo -e "  ${DIM}Updating every 2s — Ctrl+C to stop${NC}"
    sleep 2
  done
}

cpu_frequencies() {
  header
  echo -e "  ${WHITE}${BOLD}CPU FREQUENCIES (per core)${NC}"
  echo ""
  core=0
  for cpu_dir in /sys/devices/system/cpu/cpu[0-9]*/cpufreq/; do
    if [ -f "${cpu_dir}scaling_cur_freq" ]; then
      CUR=$(cat "${cpu_dir}scaling_cur_freq" 2>/dev/null)
      MAX=$(cat "${cpu_dir}cpuinfo_max_freq" 2>/dev/null || echo "0")
      MIN=$(cat "${cpu_dir}cpuinfo_min_freq" 2>/dev/null || echo "0")
      GOV=$(cat "${cpu_dir}scaling_governor" 2>/dev/null || echo "N/A")
      PCT=$(awk "BEGIN{printf \"%.0f\", $CUR/$MAX*100}" 2>/dev/null || echo "0")
      BAR=$(awk "BEGIN{n=int($PCT/5); b=\"\"; for(i=0;i<n;i++) b=b\"█\"; for(i=n;i<20;i++) b=b\"░\"; print b}" 2>/dev/null)
      echo -e "  ${GREEN}Core ${core}:${NC}  [${CYAN}${BAR}${NC}] $((CUR/1000))MHz / $((MAX/1000))MHz  gov:${GOV}"
      core=$((core+1))
    fi
  done
  echo ""
  echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

gpu_info() {
  header
  echo -e "  ${WHITE}${BOLD}GPU INFO${NC}"
  echo ""
  # Adreno GPU paths (Snapdragon 8 Gen 3)
  for path in \
    /sys/class/kgsl/kgsl-3d0 \
    /sys/kernel/gpu \
    /sys/devices/platform/soc/3d00000.qcom,kgsl-3d0/kgsl/kgsl-3d0; do
    if [ -d "$path" ]; then
      info "GPU path: $path"
      for attr in gpu_busy_percentage clock_mhz min_clock_mhz max_clock_mhz \
                  gpuclk perfcounter_update_period devfreq/cur_freq \
                  devfreq/min_freq devfreq/max_freq; do
        val_path="$path/$attr"
        [ -f "$val_path" ] && echo -e "  ${GREEN}${attr}:${NC} $(cat "$val_path" 2>/dev/null)"
      done
      break
    fi
  done
  echo ""
  GPU_RENDERER=$(getprop ro.hardware.egl 2>/dev/null || echo "N/A")
  GPU_VENDOR=$(getprop ro.hardware.vulkan 2>/dev/null || echo "N/A")
  echo -e "  ${GREEN}EGL Driver:${NC}    $GPU_RENDERER"
  echo -e "  ${GREEN}Vulkan Driver:${NC} $GPU_VENDOR"
  echo ""
  echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

thermal_zones() {
  header
  echo -e "  ${WHITE}${BOLD}ALL THERMAL ZONES${NC}"
  echo ""
  for zone_dir in /sys/class/thermal/thermal_zone*/; do
    zone=$(basename "$zone_dir")
    type=$(cat "${zone_dir}type" 2>/dev/null || echo "unknown")
    temp_raw=$(cat "${zone_dir}temp" 2>/dev/null || echo "0")
    [ "${#temp_raw}" -gt 3 ] && temp=$((temp_raw/1000)) || temp=$temp_raw
    [ "$temp" -gt 0 ] 2>/dev/null && {
      if [ "$temp" -ge 80 ]; then
        color="$RED"
      elif [ "$temp" -ge 60 ]; then
        color="$YELLOW"
      else
        color="$GREEN"
      fi
      printf "  ${GREEN}%-35s${NC} ${color}%3d°C${NC}\n" "$zone ($type)" "$temp"
    }
  done
  echo ""
  echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

memory_consumers() {
  header
  echo -e "  ${WHITE}${BOLD}TOP MEMORY CONSUMERS${NC}"
  echo ""
  ps aux 2>/dev/null | sort -rn -k4 | head -20 | awk '{
    printf "  \033[32m%-8s\033[0m  \033[33m%5s%%\033[0m  %s\n", $1, $4, $11
  }' 2>/dev/null || \
  cat /proc/*/status 2>/dev/null | awk '
    /^Name:/{name=$2} /^VmRSS:/{printf "  %-30s %s kB\n", name, $2}
  ' | sort -t' ' -k3 -rn | head -20
  echo ""
  echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

io_stats() {
  header
  echo -e "  ${WHITE}${BOLD}DISK I/O STATS${NC}"
  echo ""
  cat /proc/diskstats 2>/dev/null | awk '{
    if ($3 ~ /^sd|^mmcblk|^nvme/) {
      printf "  \033[32m%-15s\033[0m  reads:%s  writes:%s  io_ms:%s\n", $3, $4, $8, $13
    }
  }'
  echo ""
  echo -e "  ${CYAN}── iostat (if available) ────────────────────────────────${NC}"
  iostat 2>/dev/null | head -20 || echo "  iostat not available"
  echo ""
  echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

battery_live() {
  info "Battery live monitor — Ctrl+C to stop"
  BAT="/sys/class/power_supply/battery"
  while true; do
    clear
    echo -e "${CYAN}${BOLD}  ── BATTERY LIVE ──────────────────── $(date '+%H:%M:%S') ──${NC}"
    echo ""
    if [ -d "$BAT" ]; then
      CAP=$(cat "$BAT/capacity" 2>/dev/null)
      STATUS=$(cat "$BAT/status" 2>/dev/null)
      TEMP_RAW=$(cat "$BAT/temp" 2>/dev/null || echo "0")
      TEMP=$((TEMP_RAW / 10))
      VOLT_RAW=$(cat "$BAT/voltage_now" 2>/dev/null || echo "0")
      VOLT=$(awk "BEGIN{printf \"%.3f\", $VOLT_RAW/1000000}")
      CURR_RAW=$(cat "$BAT/current_now" 2>/dev/null || echo "0")
      CURR=$(awk "BEGIN{printf \"%.0f\", ${CURR_RAW#-}/1000}")
      CHARGE_FULL=$(cat "$BAT/charge_full" 2>/dev/null || echo "0")
      CHARGE_NOW=$(cat "$BAT/charge_now" 2>/dev/null || echo "0")
      POWER=$(awk "BEGIN{printf \"%.2f\", $VOLT * ${CURR_RAW#-} / 1000000000000}")

      BAR_N=$((CAP / 5))
      BAR=$(awk "BEGIN{b=\"\"; for(i=0;i<$BAR_N;i++) b=b\"█\"; for(i=$BAR_N;i<20;i++) b=b\"░\"; print b}")
      [ "$CAP" -ge 50 ] && BCOLOR="$GREEN" || { [ "$CAP" -ge 20 ] && BCOLOR="$YELLOW" || BCOLOR="$RED"; }

      echo -e "  ${GREEN}Capacity:${NC}   [${BCOLOR}${BAR}${NC}] ${CAP}%"
      echo -e "  ${GREEN}Status:${NC}     ${STATUS}"
      echo -e "  ${GREEN}Voltage:${NC}    ${VOLT}V"
      echo -e "  ${GREEN}Current:${NC}    ${CURR}mA"
      echo -e "  ${GREEN}Power:${NC}      ${POWER}W"
      echo -e "  ${GREEN}Temp:${NC}       ${TEMP}°C"
      [ "$CHARGE_FULL" -gt 0 ] && {
        HEALTH_PCT=$(awk "BEGIN{printf \"%.1f\", $CHARGE_NOW/$CHARGE_FULL*100}")
        echo -e "  ${GREEN}Charge Lvl:${NC} ${HEALTH_PCT}% of rated capacity"
      }
    fi
    echo ""
    echo -e "  ${DIM}Updating every 3s — Ctrl+C to stop${NC}"
    sleep 3
  done
}

network_bandwidth() {
  info "Network bandwidth monitor — Ctrl+C to stop"
  declare -A prev_rx prev_tx
  for iface in wlan0 wlan1 rmnet_data0 eth0 usb0; do
    [ -f "/sys/class/net/$iface/statistics/rx_bytes" ] && {
      prev_rx[$iface]=$(cat "/sys/class/net/$iface/statistics/rx_bytes")
      prev_tx[$iface]=$(cat "/sys/class/net/$iface/statistics/tx_bytes")
    }
  done
  while true; do
    sleep 1
    clear
    echo -e "${CYAN}${BOLD}  ── NETWORK BANDWIDTH ──────────────────── $(date '+%H:%M:%S') ──${NC}"
    echo ""
    printf "  ${GREEN}%-12s  %-18s  %-18s  %-15s  %-15s${NC}\n" \
      "Interface" "RX Speed" "TX Speed" "Total RX" "Total TX"
    echo -e "  ${DIM}─────────────────────────────────────────────────────────────────${NC}"
    for iface in wlan0 wlan1 rmnet_data0 eth0 usb0; do
      RX_FILE="/sys/class/net/$iface/statistics/rx_bytes"
      TX_FILE="/sys/class/net/$iface/statistics/tx_bytes"
      [ -f "$RX_FILE" ] || continue
      cur_rx=$(cat "$RX_FILE"); cur_tx=$(cat "$TX_FILE")
      rx_speed=$(( cur_rx - ${prev_rx[$iface]:-0} ))
      tx_speed=$(( cur_tx - ${prev_tx[$iface]:-0} ))
      prev_rx[$iface]=$cur_rx; prev_tx[$iface]=$cur_tx
      format_speed() {
        local b=$1
        [ "$b" -gt 1048576 ] && echo "${b}B/s" && return
        [ "$b" -gt 1024 ] && awk "BEGIN{printf \"%.1f KB/s\",$b/1024}" && return
        echo "${b} B/s"
      }
      printf "  %-12s  %-18s  %-18s  %-15s  %-15s\n" \
        "$iface" \
        "$(format_speed $rx_speed)" \
        "$(format_speed $tx_speed)" \
        "$((cur_rx/1024/1024))MB" \
        "$((cur_tx/1024/1024))MB"
    done
    echo ""
    echo -e "  ${DIM}Ctrl+C to stop${NC}"
  done
}

performance_menu
