#!/data/data/com.termux/files/usr/bin/bash
# =============================================================================
# DevTools Main Menu — Samsung S24 Developer Toolkit
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/colors.sh" 2>/dev/null || source "$HOME/.devtools/scripts/colors.sh" 2>/dev/null

main_menu() {
  while true; do
    header
    echo -e "  ${WHITE}${BOLD}SELECT A TOOL CATEGORY${NC}"
    echo ""
    echo -e "  ${CYAN}[1]${NC}  ${WHITE}System Info & Hardware${NC}        ${DIM}CPU, RAM, battery, sensors${NC}"
    echo -e "  ${CYAN}[2]${NC}  ${WHITE}Performance Monitor${NC}            ${DIM}Real-time CPU/GPU/temp/RAM${NC}"
    echo -e "  ${CYAN}[3]${NC}  ${WHITE}Network Tools${NC}                  ${DIM}nmap, tshark, iperf3, mtr, DNS${NC}"
    echo -e "  ${CYAN}[4]${NC}  ${WHITE}ADB & Android Debug${NC}            ${DIM}adb shell, logcat, wireless ADB${NC}"
    echo -e "  ${CYAN}[5]${NC}  ${WHITE}Security & Pentesting${NC}          ${DIM}Frida, objection, sqlmap, hydra${NC}"
    echo -e "  ${CYAN}[6]${NC}  ${WHITE}APK & Package Tools${NC}            ${DIM}apktool, jadx, androguard${NC}"
    echo -e "  ${CYAN}[7]${NC}  ${WHITE}Log Viewer${NC}                     ${DIM}logcat, filtered logs, crash logs${NC}"
    echo -e "  ${CYAN}[8]${NC}  ${WHITE}File & Binary Tools${NC}            ${DIM}strings, objdump, hexdump, strace${NC}"
    echo -e "  ${CYAN}[9]${NC}  ${WHITE}SSH Server${NC}                     ${DIM}Start/stop SSH, manage keys${NC}"
    echo -e "  ${CYAN}[0]${NC}  ${WHITE}Quick Commands${NC}                 ${DIM}Common one-liners cheat sheet${NC}"
    echo ""
    echo -e "  ${RED}[q]${NC}  Exit"
    echo ""
    echo -ne "  ${BOLD}Choice → ${NC}"
    read -r choice

    case "$choice" in
      1) bash "$SCRIPT_DIR/device-info.sh" ;;
      2) bash "$SCRIPT_DIR/performance.sh" ;;
      3) bash "$SCRIPT_DIR/network.sh" ;;
      4) bash "$SCRIPT_DIR/adb.sh" ;;
      5) bash "$SCRIPT_DIR/security.sh" ;;
      6) bash "$SCRIPT_DIR/packages.sh" ;;
      7) bash "$SCRIPT_DIR/logs.sh" ;;
      8) bash "$SCRIPT_DIR/files.sh" ;;
      9) bash "$SCRIPT_DIR/ssh.sh" ;;
      0) bash "$SCRIPT_DIR/quickref.sh" ;;
      q|Q|quit|exit) echo ""; info "Goodbye."; echo ""; exit 0 ;;
      *) warn "Invalid option. Press Enter to continue."; read -r ;;
    esac
  done
}

main_menu
