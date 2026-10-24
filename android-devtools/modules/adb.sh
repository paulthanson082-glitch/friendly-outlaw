#!/data/data/com.termux/files/usr/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/colors.sh" 2>/dev/null

adb_menu() {
  while true; do
    header
    echo -e "  ${WHITE}${BOLD}ADB & ANDROID DEBUG TOOLS${NC}"
    echo ""
    echo -e "  ${CYAN}[1]${NC}  List connected devices"
    echo -e "  ${CYAN}[2]${NC}  Wireless ADB setup (connect phone to itself)"
    echo -e "  ${CYAN}[3]${NC}  Interactive ADB shell"
    echo -e "  ${CYAN}[4]${NC}  Install APK"
    echo -e "  ${CYAN}[5]${NC}  Pull file from device"
    echo -e "  ${CYAN}[6]${NC}  Push file to device"
    echo -e "  ${CYAN}[7]${NC}  Screen capture (screenshot)"
    echo -e "  ${CYAN}[8]${NC}  Screen record"
    echo -e "  ${CYAN}[9]${NC}  Dump package info"
    echo -e "  ${CYAN}[a]${NC}  Launch activity"
    echo -e "  ${CYAN}[b]${NC}  Send broadcast intent"
    echo -e "  ${CYAN}[c]${NC}  Reboot options (normal / recovery / bootloader)"
    echo -e "  ${CYAN}[d]${NC}  Battery stats reset"
    echo -e "  ${CYAN}[e]${NC}  dumpsys — System service dumps"
    echo -e "  ${CYAN}[f]${NC}  List all installed packages"
    echo -e "  ${CYAN}[g]${NC}  Clear app data/cache"
    echo -e "  ${CYAN}[h]${NC}  Simulate key events"
    echo -e "  ${CYAN}[i]${NC}  Get device properties (getprop)"
    echo ""
    echo -e "  ${RED}[x]${NC}  Back"
    echo ""
    echo -ne "  ${BOLD}Choice → ${NC}"
    read -r choice

    case "$choice" in
      1) adb_devices ;;
      2) wireless_adb ;;
      3) adb shell 2>/dev/null || warn "No device connected" ;;
      4) install_apk ;;
      5) pull_file ;;
      6) push_file ;;
      7) screenshot ;;
      8) screenrecord_menu ;;
      9) dump_package ;;
      a|A) launch_activity ;;
      b|B) send_broadcast ;;
      c|C) reboot_menu ;;
      d|D) adb shell dumpsys batterystats --reset 2>/dev/null; success "Battery stats reset" ;;
      e|E) dumpsys_menu ;;
      f|F) list_packages ;;
      g|G) clear_app_data ;;
      h|H) key_events ;;
      i|I) getprop_menu ;;
      x|X) return ;;
      *) warn "Invalid"; sleep 1 ;;
    esac
  done
}

adb_devices() {
  header
  echo -e "  ${WHITE}${BOLD}ADB DEVICES${NC}"
  echo ""
  adb devices -l 2>/dev/null
  echo ""
  info "Tip: For wireless ADB on Android 11+, use option [2]."
  echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

wireless_adb() {
  header
  echo -e "  ${WHITE}${BOLD}WIRELESS ADB SETUP${NC}"
  echo ""
  info "On Android 11+ you can connect ADB wirelessly without USB."
  echo ""
  echo -e "  ${YELLOW}Steps:${NC}"
  echo -e "  1. Settings → Developer Options → Wireless Debugging → Enable"
  echo -e "  2. Tap 'Pair device with pairing code'"
  echo -e "  3. Note the pairing port and code shown on screen"
  echo ""
  echo -ne "  ${BOLD}Enter pairing address (IP:PORT from screen) → ${NC}"; read -r pair_addr
  echo -ne "  ${BOLD}Enter pairing code → ${NC}"; read -r pair_code

  if [ -n "$pair_addr" ] && [ -n "$pair_code" ]; then
    step "Pairing..."
    adb pair "$pair_addr" "$pair_code" 2>/dev/null
    echo ""
    echo -ne "  ${BOLD}Enter connection address (IP:PORT from Wireless Debugging screen) → ${NC}"
    read -r conn_addr
    if [ -n "$conn_addr" ]; then
      step "Connecting..."
      adb connect "$conn_addr" 2>/dev/null
      echo ""
      adb devices 2>/dev/null
    fi
  else
    warn "Addresses required. Enable Wireless Debugging first."
  fi
  echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

install_apk() {
  echo -ne "  ${BOLD}APK path → ${NC}"; read -r apk
  [ -z "$apk" ] && return
  step "Installing $apk..."
  adb install -r "$apk" 2>/dev/null
  echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

pull_file() {
  echo -ne "  ${BOLD}Remote path (on device) → ${NC}"; read -r remote
  echo -ne "  ${BOLD}Local save path → ${NC}"; read -r local
  [ -z "$remote" ] && return
  adb pull "$remote" "${local:-.}" 2>/dev/null
  echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

push_file() {
  echo -ne "  ${BOLD}Local file path → ${NC}"; read -r local
  echo -ne "  ${BOLD}Remote path on device → ${NC}"; read -r remote
  [ -z "$local" ] && return
  adb push "$local" "${remote:-/sdcard/}" 2>/dev/null
  echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

screenshot() {
  TS=$(date '+%Y%m%d_%H%M%S')
  OUTFILE="/sdcard/screenshot_${TS}.png"
  step "Capturing screenshot..."
  adb shell screencap -p "$OUTFILE" 2>/dev/null
  success "Saved to $OUTFILE"
  echo -ne "  Pull to local? [y/N]: "; read -r pull
  [ "$pull" = "y" ] && adb pull "$OUTFILE" . 2>/dev/null
  echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

screenrecord_menu() {
  echo -ne "  ${BOLD}Duration in seconds (default 30) → ${NC}"; read -r dur
  dur=${dur:-30}
  TS=$(date '+%Y%m%d_%H%M%S')
  OUTFILE="/sdcard/screenrecord_${TS}.mp4"
  step "Recording for ${dur}s..."
  adb shell screenrecord --time-limit "$dur" "$OUTFILE" 2>/dev/null
  success "Saved to $OUTFILE"
  echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

dump_package() {
  echo -ne "  ${BOLD}Package name (e.g. com.android.chrome) → ${NC}"; read -r pkg
  [ -z "$pkg" ] && return
  echo ""
  echo -e "  ${CYAN}── Package Info ─────────────────────────────────────────${NC}"
  adb shell pm dump "$pkg" 2>/dev/null | head -80
  echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

launch_activity() {
  echo -ne "  ${BOLD}Package/Activity (e.g. com.app/.MainActivity) → ${NC}"; read -r act
  [ -z "$act" ] && return
  adb shell am start -n "$act" 2>/dev/null
  echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

send_broadcast() {
  echo -ne "  ${BOLD}Intent action (e.g. android.intent.action.BOOT_COMPLETED) → ${NC}"; read -r action
  [ -z "$action" ] && return
  adb shell am broadcast -a "$action" 2>/dev/null
  echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

reboot_menu() {
  echo -e "\n  ${CYAN}[1]${NC} Reboot  ${CYAN}[2]${NC} Recovery  ${CYAN}[3]${NC} Bootloader  ${CYAN}[4]${NC} Cancel"
  echo -ne "  ${BOLD}Choice → ${NC}"; read -r c
  case "$c" in
    1) adb reboot 2>/dev/null ;;
    2) adb reboot recovery 2>/dev/null ;;
    3) adb reboot bootloader 2>/dev/null ;;
    *) return ;;
  esac
}

dumpsys_menu() {
  header
  echo -e "  ${WHITE}${BOLD}DUMPSYS — System Service Dumps${NC}"
  echo ""
  echo -e "  ${CYAN}[1]${NC}  Battery stats"
  echo -e "  ${CYAN}[2]${NC}  Memory info"
  echo -e "  ${CYAN}[3]${NC}  Activity manager"
  echo -e "  ${CYAN}[4]${NC}  Window manager"
  echo -e "  ${CYAN}[5]${NC}  Network stats"
  echo -e "  ${CYAN}[6]${NC}  WiFi info"
  echo -e "  ${CYAN}[7]${NC}  All services list"
  echo -e "  ${CYAN}[8]${NC}  Custom service"
  echo ""
  echo -ne "  ${BOLD}Choice → ${NC}"; read -r c
  case "$c" in
    1) adb shell dumpsys battery 2>/dev/null ;;
    2) adb shell dumpsys meminfo 2>/dev/null | head -50 ;;
    3) adb shell dumpsys activity 2>/dev/null | head -80 ;;
    4) adb shell dumpsys window 2>/dev/null | head -80 ;;
    5) adb shell dumpsys netstats 2>/dev/null | head -50 ;;
    6) adb shell dumpsys wifi 2>/dev/null | head -60 ;;
    7) adb shell service list 2>/dev/null ;;
    8) echo -ne "  Service name: "; read -r svc
       adb shell dumpsys "$svc" 2>/dev/null | head -100 ;;
  esac
  echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

list_packages() {
  header
  echo -e "  ${WHITE}${BOLD}INSTALLED PACKAGES${NC}"
  echo ""
  echo -e "  ${CYAN}[1]${NC}  All packages"
  echo -e "  ${CYAN}[2]${NC}  User-installed only"
  echo -e "  ${CYAN}[3]${NC}  System packages only"
  echo -e "  ${CYAN}[4]${NC}  Disabled packages"
  echo -e "  ${CYAN}[5]${NC}  Search by name"
  echo ""
  echo -ne "  ${BOLD}Choice → ${NC}"; read -r c
  case "$c" in
    1) adb shell pm list packages 2>/dev/null ;;
    2) adb shell pm list packages -3 2>/dev/null ;;
    3) adb shell pm list packages -s 2>/dev/null ;;
    4) adb shell pm list packages -d 2>/dev/null ;;
    5) echo -ne "  Search term: "; read -r q
       adb shell pm list packages 2>/dev/null | grep -i "$q" ;;
  esac | less 2>/dev/null || cat
  echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

clear_app_data() {
  echo -ne "  ${BOLD}Package name → ${NC}"; read -r pkg
  [ -z "$pkg" ] && return
  echo -ne "  Clear data? [y/N]: "; read -r confirm
  [ "$confirm" = "y" ] && adb shell pm clear "$pkg" 2>/dev/null
  echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

key_events() {
  header
  echo -e "  ${WHITE}${BOLD}SIMULATE KEY EVENTS${NC}"
  echo ""
  echo -e "  ${CYAN}Common key codes:${NC}"
  echo -e "  3=HOME  4=BACK  24=VOL+  25=VOL-  26=POWER  66=ENTER  67=DEL"
  echo -e "  82=MENU  164=MUTE  187=RECENTS  223=SLEEP"
  echo ""
  echo -ne "  ${BOLD}Key code → ${NC}"; read -r key
  [ -n "$key" ] && adb shell input keyevent "$key" 2>/dev/null
  echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

getprop_menu() {
  header
  echo -e "  ${WHITE}${BOLD}DEVICE PROPERTIES (getprop)${NC}"
  echo ""
  echo -e "  ${CYAN}[1]${NC}  All properties"
  echo -e "  ${CYAN}[2]${NC}  Build properties"
  echo -e "  ${CYAN}[3]${NC}  Network properties"
  echo -e "  ${CYAN}[4]${NC}  Search property"
  echo ""
  echo -ne "  ${BOLD}Choice → ${NC}"; read -r c
  case "$c" in
    1) getprop 2>/dev/null | less 2>/dev/null || getprop ;;
    2) getprop 2>/dev/null | grep "ro.build" ;;
    3) getprop 2>/dev/null | grep -E "net\.|wifi\." ;;
    4) echo -ne "  Search: "; read -r q; getprop 2>/dev/null | grep -i "$q" ;;
  esac
  echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

adb_menu
