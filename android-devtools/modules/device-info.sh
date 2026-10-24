#!/data/data/com.termux/files/usr/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/colors.sh" 2>/dev/null

show_device_info() {
  header
  echo -e "  ${WHITE}${BOLD}SYSTEM INFO & HARDWARE${NC}"
  echo ""

  # ── Android / Build ────────────────────────────────────────────────────────
  echo -e "  ${CYAN}── Android & Build ─────────────────────────────────────${NC}"
  ANDROID_VER=$(getprop ro.build.version.release 2>/dev/null || echo "N/A")
  SDK_VER=$(getprop ro.build.version.sdk 2>/dev/null || echo "N/A")
  SECURITY_PATCH=$(getprop ro.build.version.security_patch 2>/dev/null || echo "N/A")
  BUILD_ID=$(getprop ro.build.id 2>/dev/null || echo "N/A")
  FINGERPRINT=$(getprop ro.build.fingerprint 2>/dev/null || echo "N/A")
  DEVICE=$(getprop ro.product.device 2>/dev/null || echo "N/A")
  MODEL=$(getprop ro.product.model 2>/dev/null || echo "N/A")
  BRAND=$(getprop ro.product.brand 2>/dev/null || echo "N/A")
  MANUFACTURER=$(getprop ro.product.manufacturer 2>/dev/null || echo "N/A")

  echo -e "  ${GREEN}Device:${NC}          $MANUFACTURER $MODEL ($DEVICE)"
  echo -e "  ${GREEN}Android:${NC}         $ANDROID_VER (SDK $SDK_VER)"
  echo -e "  ${GREEN}Security Patch:${NC}  $SECURITY_PATCH"
  echo -e "  ${GREEN}Build ID:${NC}        $BUILD_ID"
  echo -e "  ${GREEN}Fingerprint:${NC}     ${DIM}$FINGERPRINT${NC}"
  echo ""

  # ── CPU ────────────────────────────────────────────────────────────────────
  echo -e "  ${CYAN}── CPU ─────────────────────────────────────────────────${NC}"
  CPU_HARDWARE=$(grep -m1 'Hardware' /proc/cpuinfo 2>/dev/null | awk -F': ' '{print $2}' || echo "N/A")
  CPU_CORES=$(nproc 2>/dev/null || grep -c '^processor' /proc/cpuinfo 2>/dev/null || echo "N/A")
  CPU_ARCH=$(uname -m 2>/dev/null || echo "N/A")
  CPU_ABI=$(getprop ro.product.cpu.abi 2>/dev/null || echo "N/A")

  # Per-core frequencies
  echo -e "  ${GREEN}Hardware:${NC}        $CPU_HARDWARE"
  echo -e "  ${GREEN}Architecture:${NC}    $CPU_ARCH ($CPU_ABI)"
  echo -e "  ${GREEN}Cores:${NC}           $CPU_CORES"

  echo -ne "  ${GREEN}Frequencies:${NC}     "
  for cpu_dir in /sys/devices/system/cpu/cpu[0-9]*/cpufreq/; do
    if [ -f "${cpu_dir}scaling_cur_freq" ]; then
      freq=$(cat "${cpu_dir}scaling_cur_freq" 2>/dev/null)
      if [ -n "$freq" ]; then
        mhz=$((freq / 1000))
        echo -ne "${mhz}MHz "
      fi
    fi
  done
  echo ""

  # CPU temp
  for temp_path in \
    /sys/class/thermal/thermal_zone0/temp \
    /sys/class/thermal/thermal_zone1/temp \
    /sys/devices/virtual/thermal/thermal_zone0/temp; do
    if [ -f "$temp_path" ]; then
      raw=$(cat "$temp_path" 2>/dev/null)
      [ "${#raw}" -gt 3 ] && temp_c=$((raw / 1000)) || temp_c=$raw
      echo -e "  ${GREEN}CPU Temp:${NC}        ${temp_c}°C"
      break
    fi
  done
  echo ""

  # ── Memory ─────────────────────────────────────────────────────────────────
  echo -e "  ${CYAN}── Memory ──────────────────────────────────────────────${NC}"
  if [ -f /proc/meminfo ]; then
    MEM_TOTAL=$(awk '/MemTotal/{printf "%.0f MB", $2/1024}' /proc/meminfo)
    MEM_FREE=$(awk '/MemAvailable/{printf "%.0f MB", $2/1024}' /proc/meminfo)
    MEM_USED=$(awk '/MemTotal/{t=$2} /MemAvailable/{a=$2} END{printf "%.0f MB", (t-a)/1024}' /proc/meminfo)
    SWAP_TOTAL=$(awk '/SwapTotal/{printf "%.0f MB", $2/1024}' /proc/meminfo)
    echo -e "  ${GREEN}Total RAM:${NC}       $MEM_TOTAL"
    echo -e "  ${GREEN}Used RAM:${NC}        $MEM_USED"
    echo -e "  ${GREEN}Available:${NC}       $MEM_FREE"
    echo -e "  ${GREEN}Swap:${NC}            $SWAP_TOTAL"
  fi
  echo ""

  # ── Storage ────────────────────────────────────────────────────────────────
  echo -e "  ${CYAN}── Storage ─────────────────────────────────────────────${NC}"
  df -h /data /sdcard /storage/emulated/0 2>/dev/null | awk 'NR>1 {
    printf "  \033[32m%-30s\033[0m  Used: %-8s  Free: %-8s  Total: %s\n", $6, $3, $4, $2
  }'
  echo ""

  # ── Battery ────────────────────────────────────────────────────────────────
  echo -e "  ${CYAN}── Battery ─────────────────────────────────────────────${NC}"
  BAT_BASE="/sys/class/power_supply/battery"
  if [ -d "$BAT_BASE" ]; then
    BAT_CAP=$(cat "$BAT_BASE/capacity" 2>/dev/null || echo "N/A")
    BAT_STATUS=$(cat "$BAT_BASE/status" 2>/dev/null || echo "N/A")
    BAT_TEMP_RAW=$(cat "$BAT_BASE/temp" 2>/dev/null || echo "0")
    BAT_TEMP=$((BAT_TEMP_RAW / 10))
    BAT_VOLTAGE_RAW=$(cat "$BAT_BASE/voltage_now" 2>/dev/null || echo "0")
    BAT_VOLTAGE=$(awk "BEGIN{printf \"%.2f\", $BAT_VOLTAGE_RAW/1000000}")
    BAT_CURRENT_RAW=$(cat "$BAT_BASE/current_now" 2>/dev/null || echo "0")
    BAT_CURRENT=$(awk "BEGIN{printf \"%.0f\", ${BAT_CURRENT_RAW#-}/1000}")
    BAT_HEALTH=$(cat "$BAT_BASE/health" 2>/dev/null || echo "N/A")
    BAT_TECH=$(cat "$BAT_BASE/technology" 2>/dev/null || echo "N/A")
    echo -e "  ${GREEN}Capacity:${NC}        ${BAT_CAP}% (${BAT_STATUS})"
    echo -e "  ${GREEN}Voltage:${NC}         ${BAT_VOLTAGE}V"
    echo -e "  ${GREEN}Current:${NC}         ${BAT_CURRENT}mA"
    echo -e "  ${GREEN}Temperature:${NC}     ${BAT_TEMP}°C"
    echo -e "  ${GREEN}Health:${NC}          $BAT_HEALTH"
    echo -e "  ${GREEN}Technology:${NC}      $BAT_TECH"
  else
    # Fallback via termux-battery-status
    if command -v termux-battery-status &>/dev/null; then
      termux-battery-status 2>/dev/null | python3 -c "
import sys,json
d=json.load(sys.stdin)
for k,v in d.items(): print(f'  \033[32m{k}:\033[0m {v}')
" 2>/dev/null || echo "  Battery info unavailable"
    fi
  fi
  echo ""

  # ── Network Interfaces ─────────────────────────────────────────────────────
  echo -e "  ${CYAN}── Network Interfaces ──────────────────────────────────${NC}"
  ip addr 2>/dev/null | awk '
    /^[0-9]+: / { iface=$2; gsub(/:$/,"",iface) }
    /inet / { printf "  \033[32m%-12s\033[0m  %s\n", iface, $2 }
  ' || ifconfig 2>/dev/null | grep -E "(inet |HWaddr)" | \
    awk '{printf "  %s\n", $0}'
  echo ""

  # ── Kernel ─────────────────────────────────────────────────────────────────
  echo -e "  ${CYAN}── Kernel & Runtime ────────────────────────────────────${NC}"
  echo -e "  ${GREEN}Kernel:${NC}          $(uname -r)"
  echo -e "  ${GREEN}Hostname:${NC}        $(hostname 2>/dev/null || echo 'N/A')"
  echo -e "  ${GREEN}Uptime:${NC}          $(uptime -p 2>/dev/null || uptime | awk '{print $3,$4}' | sed 's/,//')"
  echo -e "  ${GREEN}Load Avg:${NC}        $(cat /proc/loadavg | awk '{print $1, $2, $3}')"
  JAVA_VER=$(java -version 2>&1 | head -1 || echo "N/A")
  echo -e "  ${GREEN}Java:${NC}            $JAVA_VER"
  PY_VER=$(python3 --version 2>/dev/null || echo "N/A")
  echo -e "  ${GREEN}Python:${NC}          $PY_VER"
  NODE_VER=$(node --version 2>/dev/null || echo "N/A")
  echo -e "  ${GREEN}Node.js:${NC}         $NODE_VER"
  echo ""

  # ── Termux-API Extras ──────────────────────────────────────────────────────
  if command -v termux-wifi-connectioninfo &>/dev/null; then
    echo -e "  ${CYAN}── WiFi (via termux-api) ────────────────────────────────${NC}"
    termux-wifi-connectioninfo 2>/dev/null | python3 -c "
import sys,json
try:
  d=json.load(sys.stdin)
  for k,v in d.items(): print(f'  \033[32m{k}:\033[0m {v}')
except: print('  WiFi info unavailable')
" 2>/dev/null
    echo ""
  fi

  echo -ne "  ${DIM}Press Enter to return...${NC}"; read -r
}

show_device_info
