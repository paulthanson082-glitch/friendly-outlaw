#!/data/data/com.termux/files/usr/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/colors.sh" 2>/dev/null

logs_menu() {
  while true; do
    header
    echo -e "  ${WHITE}${BOLD}LOG VIEWER${NC}"
    echo ""
    echo -e "  ${CYAN}[1]${NC}  Live logcat — all logs"
    echo -e "  ${CYAN}[2]${NC}  Live logcat — filter by package"
    echo -e "  ${CYAN}[3]${NC}  Live logcat — errors only"
    echo -e "  ${CYAN}[4]${NC}  Live logcat — crash & ANR only"
    echo -e "  ${CYAN}[5]${NC}  Dump last N lines of logcat"
    echo -e "  ${CYAN}[6]${NC}  Save logcat to file"
    echo -e "  ${CYAN}[7]${NC}  Kernel logs (dmesg)"
    echo -e "  ${CYAN}[8]${NC}  Termux session log viewer"
    echo -e "  ${CYAN}[9]${NC}  Clear logcat buffer"
    echo -e "  ${CYAN}[a]${NC}  Search logcat for keyword"
    echo -e "  ${CYAN}[b]${NC}  Crash logs — tombstones"
    echo -e "  ${CYAN}[c]${NC}  ANR traces"
    echo ""
    echo -e "  ${RED}[x]${NC}  Back"
    echo ""
    echo -ne "  ${BOLD}Choice → ${NC}"
    read -r choice

    case "$choice" in
      1) logcat_live ;;
      2) logcat_package ;;
      3) logcat_errors ;;
      4) logcat_crashes ;;
      5) logcat_dump ;;
      6) logcat_save ;;
      7) dmesg_view ;;
      8) less "${HOME}/.termux/termux-session.log" 2>/dev/null || warn "No session log found" ;;
      9) logcat -c 2>/dev/null; success "Logcat buffer cleared" ;;
      a|A) logcat_search ;;
      b|B) tombstone_view ;;
      c|C) anr_traces ;;
      x|X) return ;;
      *) warn "Invalid"; sleep 1 ;;
    esac
  done
}

colorize_logcat() {
  # Colorize logcat levels
  sed \
    -e "s/^.\/.* E /$(printf '\033[31m')&$(printf '\033[0m')/" \
    -e "s/^.\/.* W /$(printf '\033[33m')&$(printf '\033[0m')/" \
    -e "s/^.\/.* I /$(printf '\033[32m')&$(printf '\033[0m')/" \
    -e "s/^.\/.* D /$(printf '\033[36m')&$(printf '\033[0m')/" \
    -e "s/^.\/.* V /$(printf '\033[37m')&$(printf '\033[0m')/" 2>/dev/null || cat
}

logcat_live() {
  info "Live logcat — Ctrl+C to stop"
  echo ""
  logcat -v threadtime 2>/dev/null | colorize_logcat
}

logcat_package() {
  echo -ne "  ${BOLD}Package name (e.g. com.android.chrome) → ${NC}"; read -r pkg
  [ -z "$pkg" ] && return
  # Get PID of package
  PID=$(adb shell pidof "$pkg" 2>/dev/null || pidof "$pkg" 2>/dev/null)
  if [ -n "$PID" ]; then
    info "Filtering logcat for PID $PID ($pkg) — Ctrl+C to stop"
    logcat --pid="$PID" -v time 2>/dev/null | colorize_logcat
  else
    info "Package not running — showing all logs containing package name..."
    logcat -v time 2>/dev/null | grep --line-buffered "$pkg" | colorize_logcat
  fi
}

logcat_errors() {
  info "Showing ERROR and FATAL — Ctrl+C to stop"
  logcat "*:E" -v time 2>/dev/null | colorize_logcat
}

logcat_crashes() {
  info "Showing crashes & ANRs — Ctrl+C to stop"
  logcat -v time 2>/dev/null | grep --line-buffered \
    -E "FATAL|AndroidRuntime|ANR in|CRASH|backtrace|signal [0-9]|SIGSEGV|SIGABRT" | \
    colorize_logcat
}

logcat_dump() {
  echo -ne "  ${BOLD}Lines to show (default 200) → ${NC}"; read -r n; n=${n:-200}
  logcat -d -v time 2>/dev/null | tail -n "$n" | colorize_logcat | less 2>/dev/null || \
  logcat -d -v time 2>/dev/null | tail -n "$n" | colorize_logcat
  echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

logcat_save() {
  TS=$(date '+%Y%m%d_%H%M%S')
  OUTFILE="${HOME}/logcat_${TS}.txt"
  echo -ne "  ${BOLD}Save path (default: $OUTFILE) → ${NC}"; read -r f
  f=${f:-$OUTFILE}
  info "Logging to $f — Ctrl+C to stop"
  logcat -v time 2>/dev/null | tee "$f"
  success "Saved to $f"
}

dmesg_view() {
  header
  echo -e "  ${WHITE}${BOLD}KERNEL LOG (dmesg)${NC}"
  echo ""
  echo -e "  ${CYAN}[1]${NC}  Full dmesg"
  echo -e "  ${CYAN}[2]${NC}  Last 50 lines"
  echo -e "  ${CYAN}[3]${NC}  Live dmesg (follow)"
  echo -e "  ${CYAN}[4]${NC}  Search dmesg"
  echo ""
  echo -ne "  ${BOLD}Choice → ${NC}"; read -r c
  case "$c" in
    1) dmesg 2>/dev/null | less ;;
    2) dmesg 2>/dev/null | tail -50 ;;
    3) dmesg -w 2>/dev/null ;;
    4) echo -ne "  Search: "; read -r q; dmesg 2>/dev/null | grep -i "$q" ;;
  esac
  echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

logcat_search() {
  echo -ne "  ${BOLD}Search keyword → ${NC}"; read -r q
  [ -z "$q" ] && return
  echo -ne "  Live or dump? [l/d]: "; read -r mode
  if [ "$mode" = "l" ]; then
    logcat -v time 2>/dev/null | grep --line-buffered -i "$q" | colorize_logcat
  else
    logcat -d -v time 2>/dev/null | grep -i "$q" | colorize_logcat | less 2>/dev/null || \
    logcat -d -v time 2>/dev/null | grep -i "$q" | colorize_logcat
  fi
  echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

tombstone_view() {
  header
  echo -e "  ${WHITE}${BOLD}CRASH TOMBSTONES${NC}"
  echo ""
  TOMBSTONE_DIR="/data/tombstones"
  if [ -d "$TOMBSTONE_DIR" ]; then
    ls -lth "$TOMBSTONE_DIR" 2>/dev/null | head -15
    echo ""
    echo -ne "  View tombstone (0-9, or filename): "; read -r t
    [ -n "$t" ] && {
      FILE="$TOMBSTONE_DIR/tombstone_0${t}"
      [ ! -f "$FILE" ] && FILE="$TOMBSTONE_DIR/$t"
      [ -f "$FILE" ] && cat "$FILE" | less 2>/dev/null || \
      warn "Cannot read (needs root)"
    }
  else
    warn "Tombstone dir not accessible (needs root)"
    info "Trying via adb..."
    adb shell ls /data/tombstones 2>/dev/null | head -10
    echo -ne "  View which tombstone: "; read -r t
    [ -n "$t" ] && adb shell cat "/data/tombstones/$t" 2>/dev/null | less 2>/dev/null
  fi
  echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

anr_traces() {
  header
  echo -e "  ${WHITE}${BOLD}ANR TRACES${NC}"
  echo ""
  ANR_FILE="/data/anr/traces.txt"
  if adb shell test -f "$ANR_FILE" 2>/dev/null; then
    adb shell cat "$ANR_FILE" 2>/dev/null | less 2>/dev/null
  elif [ -f "$ANR_FILE" ]; then
    cat "$ANR_FILE" | less 2>/dev/null
  else
    warn "ANR traces not found or need root"
    info "Recent ANRs in logcat:"
    logcat -d 2>/dev/null | grep -i "ANR in" | tail -20
  fi
  echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

logs_menu
