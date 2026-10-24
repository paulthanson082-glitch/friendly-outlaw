#!/data/data/com.termux/files/usr/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/colors.sh" 2>/dev/null

security_menu() {
  while true; do
    header
    echo -e "  ${WHITE}${BOLD}SECURITY & PENTESTING TOOLS${NC}"
    echo -e "  ${DIM}  For authorized testing, CTF, and security research only.${NC}"
    echo ""
    echo -e "  ${CYAN}── Dynamic Analysis ───────────────────────────────────${NC}"
    echo -e "  ${CYAN}[1]${NC}  Frida — Dynamic instrumentation"
    echo -e "  ${CYAN}[2]${NC}  Objection — Runtime mobile exploration"
    echo ""
    echo -e "  ${CYAN}── Network Security ───────────────────────────────────${NC}"
    echo -e "  ${CYAN}[3]${NC}  sqlmap — SQL injection testing"
    echo -e "  ${CYAN}[4]${NC}  hydra — Credential brute-force (authorized only)"
    echo -e "  ${CYAN}[5]${NC}  SSL/TLS certificate check"
    echo -e "  ${CYAN}[6]${NC}  scapy — Packet crafting (Python)"
    echo ""
    echo -e "  ${CYAN}── Static Analysis ────────────────────────────────────${NC}"
    echo -e "  ${CYAN}[7]${NC}  strings — Extract strings from binary"
    echo -e "  ${CYAN}[8]${NC}  objdump — Disassemble binary"
    echo -e "  ${CYAN}[9]${NC}  readelf — ELF binary analysis"
    echo -e "  ${CYAN}[a]${NC}  hexdump — Hex view of file"
    echo -e "  ${CYAN}[b]${NC}  strace — Trace system calls of process"
    echo ""
    echo -e "  ${CYAN}── Crypto & Hashing ───────────────────────────────────${NC}"
    echo -e "  ${CYAN}[c]${NC}  Hash file / text (md5, sha1, sha256)"
    echo -e "  ${CYAN}[d]${NC}  Base64 encode / decode"
    echo -e "  ${CYAN}[e]${NC}  Generate random passwords"
    echo ""
    echo -e "  ${RED}[x]${NC}  Back"
    echo ""
    echo -ne "  ${BOLD}Choice → ${NC}"
    read -r choice

    case "$choice" in
      1) frida_menu ;;
      2) objection_menu ;;
      3) sqlmap_menu ;;
      4) hydra_menu ;;
      5) ssl_check ;;
      6) scapy_shell ;;
      7) strings_menu ;;
      8) objdump_menu ;;
      9) readelf_menu ;;
      a|A) hexdump_menu ;;
      b|B) strace_menu ;;
      c|C) hash_menu ;;
      d|D) base64_menu ;;
      e|E) gen_passwords ;;
      x|X) return ;;
      *) warn "Invalid"; sleep 1 ;;
    esac
  done
}

frida_menu() {
  header
  echo -e "  ${WHITE}${BOLD}FRIDA — Dynamic Instrumentation${NC}"
  echo ""
  if ! command -v frida &>/dev/null; then
    warn "frida-tools not installed. Run: pip install frida-tools"
    echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r; return
  fi
  echo -e "  ${CYAN}[1]${NC}  List running processes (USB)"
  echo -e "  ${CYAN}[2]${NC}  List running processes (local/Termux)"
  echo -e "  ${CYAN}[3]${NC}  Attach to process by name (USB)"
  echo -e "  ${CYAN}[4]${NC}  Attach to process by name (local)"
  echo -e "  ${CYAN}[5]${NC}  Spawn & hook app by package"
  echo -e "  ${CYAN}[6]${NC}  Frida REPL — interactive JS shell"
  echo -e "  ${CYAN}[7]${NC}  Run Frida script on app"
  echo -e "  ${CYAN}[8]${NC}  SSL pinning bypass (via Objection)"
  echo -e "  ${CYAN}[9]${NC}  Start Frida server (needs root/ADB)"
  echo ""
  echo -ne "  ${BOLD}Choice → ${NC}"; read -r c
  case "$c" in
    1) frida-ps -U 2>/dev/null ;;
    2) frida-ps 2>/dev/null ;;
    3) echo -ne "  Process name: "; read -r p; frida -U "$p" 2>/dev/null ;;
    4) echo -ne "  Process name: "; read -r p; frida "$p" 2>/dev/null ;;
    5) echo -ne "  Package name: "; read -r pkg
       frida -U -f "$pkg" --no-pause 2>/dev/null ;;
    6) echo -ne "  Process (name or PID): "; read -r p
       frida -U "$p" 2>/dev/null ;;
    7) echo -ne "  Script .js file: "; read -r script
       echo -ne "  Package/process: "; read -r p
       frida -U -l "$script" "$p" 2>/dev/null ;;
    8) echo -ne "  Package name: "; read -r pkg
       objection -g "$pkg" explore --startup-command "android sslpinning disable" 2>/dev/null ;;
    9) bash "$SCRIPT_DIR/../modules/frida.sh" start 2>/dev/null || start-frida-server 2>/dev/null ;;
  esac
  echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

objection_menu() {
  header
  echo -e "  ${WHITE}${BOLD}OBJECTION — Runtime Mobile Exploration${NC}"
  echo ""
  if ! command -v objection &>/dev/null; then
    warn "objection not installed. Run: pip install objection"
    echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r; return
  fi
  echo -e "  ${CYAN}[1]${NC}  Explore app (interactive shell)"
  echo -e "  ${CYAN}[2]${NC}  Disable SSL pinning"
  echo -e "  ${CYAN}[3]${NC}  Patch APK with Frida gadget (no root needed)"
  echo -e "  ${CYAN}[4]${NC}  Dump memory"
  echo -e "  ${CYAN}[5]${NC}  List Android classes in app"
  echo ""
  echo -ne "  ${BOLD}Choice → ${NC}"; read -r c
  echo -ne "  ${BOLD}Package name → ${NC}"; read -r pkg
  [ -z "$pkg" ] && return
  case "$c" in
    1) objection -g "$pkg" explore 2>/dev/null ;;
    2) objection -g "$pkg" explore --startup-command "android sslpinning disable" 2>/dev/null ;;
    3) echo -ne "  APK file path: "; read -r apk
       objection patchapk -s "$apk" 2>/dev/null ;;
    4) objection -g "$pkg" explore --startup-command "memory dump all /sdcard/memdump" 2>/dev/null ;;
    5) objection -g "$pkg" explore --startup-command "android hooking list classes" 2>/dev/null ;;
  esac
  echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

sqlmap_menu() {
  header
  echo -e "  ${WHITE}${BOLD}SQLMAP — SQL Injection Testing${NC}"
  echo -e "  ${DIM}  Authorized targets only.${NC}"
  echo ""
  echo -e "  ${CYAN}[1]${NC}  Test URL for SQL injection"
  echo -e "  ${CYAN}[2]${NC}  Test with POST data"
  echo -e "  ${CYAN}[3]${NC}  Enumerate databases"
  echo -e "  ${CYAN}[4]${NC}  Dump table"
  echo -e "  ${CYAN}[5]${NC}  Custom sqlmap command"
  echo ""
  echo -ne "  ${BOLD}Choice → ${NC}"; read -r c
  case "$c" in
    1) echo -ne "  URL: "; read -r url; sqlmap -u "$url" --batch 2>/dev/null ;;
    2) echo -ne "  URL: "; read -r url
       echo -ne "  POST data: "; read -r data
       sqlmap -u "$url" --data="$data" --batch 2>/dev/null ;;
    3) echo -ne "  URL: "; read -r url; sqlmap -u "$url" --dbs --batch 2>/dev/null ;;
    4) echo -ne "  URL: "; read -r url
       echo -ne "  DB name: "; read -r db
       echo -ne "  Table name: "; read -r tbl
       sqlmap -u "$url" -D "$db" -T "$tbl" --dump --batch 2>/dev/null ;;
    5) echo -ne "  Full command: "; read -r cmd; eval "$cmd" ;;
  esac
  echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

hydra_menu() {
  header
  echo -e "  ${WHITE}${BOLD}HYDRA — Credential Testing${NC}"
  echo -e "  ${DIM}  Authorized targets only.${NC}"
  echo ""
  echo -e "  ${CYAN}[1]${NC}  SSH brute-force"
  echo -e "  ${CYAN}[2]${NC}  HTTP form brute-force"
  echo -e "  ${CYAN}[3]${NC}  FTP brute-force"
  echo -e "  ${CYAN}[4]${NC}  Custom hydra command"
  echo ""
  echo -ne "  ${BOLD}Choice → ${NC}"; read -r c
  echo -ne "  ${BOLD}Target host → ${NC}"; read -r host
  echo -ne "  ${BOLD}Username or wordlist → ${NC}"; read -r user
  echo -ne "  ${BOLD}Password wordlist → ${NC}"; read -r passlist
  case "$c" in
    1) hydra -l "$user" -P "$passlist" "$host" ssh 2>/dev/null ;;
    2) echo -ne "  Login URL path: "; read -r path
       echo -ne "  POST form data (user=^USER^&pass=^PASS^): "; read -r form
       echo -ne "  Failure string: "; read -r fail
       hydra -l "$user" -P "$passlist" "$host" http-post-form "${path}:${form}:${fail}" 2>/dev/null ;;
    3) hydra -l "$user" -P "$passlist" "$host" ftp 2>/dev/null ;;
    4) echo -ne "  Full command: "; read -r cmd; eval "$cmd" ;;
  esac
  echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

ssl_check() {
  echo -ne "  ${BOLD}Host (e.g. example.com) → ${NC}"; read -r host
  echo -ne "  ${BOLD}Port (default 443) → ${NC}"; read -r port
  port=${port:-443}
  echo ""
  echo -e "  ${CYAN}── Certificate Info ─────────────────────────────────────${NC}"
  echo | openssl s_client -connect "${host}:${port}" 2>/dev/null | \
    openssl x509 -noout -text 2>/dev/null | \
    grep -E "Subject:|Issuer:|Not Before|Not After|DNS:|IP Address" | \
    sed 's/^/  /'
  echo ""
  echo -e "  ${CYAN}── Supported TLS Versions ──────────────────────────────${NC}"
  for tls in tls1 tls1_1 tls1_2 tls1_3; do
    result=$(echo | openssl s_client -connect "${host}:${port}" -$tls 2>/dev/null | grep -c "Cipher is")
    [ "$result" -gt 0 ] && echo -e "  ${GREEN}✔${NC} $tls supported" || echo -e "  ${RED}✘${NC} $tls not supported"
  done
  echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

scapy_shell() {
  if ! python3 -c "import scapy" 2>/dev/null; then
    warn "scapy not installed. Run: pip install scapy"
    echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r; return
  fi
  info "Launching Scapy interactive shell..."
  python3 -c "
from scapy.all import *
print('[Scapy] Loaded. Try: pkt = IP(dst=\"1.1.1.1\")/ICMP(); send(pkt)')
" 2>/dev/null
  python3 -m scapy 2>/dev/null
  echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

strings_menu() {
  echo -ne "  ${BOLD}Binary/APK file → ${NC}"; read -r f
  [ -z "$f" ] || [ ! -f "$f" ] && { warn "File not found"; return; }
  echo -ne "  Min string length (default 4): "; read -r n; n=${n:-4}
  strings -n "$n" "$f" 2>/dev/null | less
  echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

objdump_menu() {
  echo -ne "  ${BOLD}Binary file → ${NC}"; read -r f
  [ -z "$f" ] || [ ! -f "$f" ] && { warn "File not found"; return; }
  echo -e "\n  ${CYAN}[1]${NC} Disassemble  ${CYAN}[2]${NC} Symbol table  ${CYAN}[3]${NC} Section headers  ${CYAN}[4]${NC} All"
  echo -ne "  ${BOLD}Choice → ${NC}"; read -r c
  case "$c" in
    1) objdump -d "$f" 2>/dev/null | less ;;
    2) objdump -t "$f" 2>/dev/null | less ;;
    3) objdump -h "$f" 2>/dev/null ;;
    4) objdump -x "$f" 2>/dev/null | less ;;
  esac
}

readelf_menu() {
  echo -ne "  ${BOLD}ELF file → ${NC}"; read -r f
  [ -z "$f" ] || [ ! -f "$f" ] && { warn "File not found"; return; }
  echo -e "\n  ${CYAN}[1]${NC} Header  ${CYAN}[2]${NC} Sections  ${CYAN}[3]${NC} Symbols  ${CYAN}[4]${NC} Dynamic  ${CYAN}[5]${NC} All"
  echo -ne "  ${BOLD}Choice → ${NC}"; read -r c
  case "$c" in
    1) readelf -h "$f" ;;
    2) readelf -S "$f" ;;
    3) readelf -s "$f" | less ;;
    4) readelf -d "$f" ;;
    5) readelf -a "$f" | less ;;
  esac
  echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

hexdump_menu() {
  echo -ne "  ${BOLD}File → ${NC}"; read -r f
  echo -ne "  Bytes to show (default 512): "; read -r n; n=${n:-512}
  [ -z "$f" ] || [ ! -f "$f" ] && { warn "File not found"; return; }
  xxd "$f" 2>/dev/null | head -$((n/16)) | less 2>/dev/null || \
  hexdump -C "$f" | head -$((n/16))
  echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

strace_menu() {
  echo -ne "  ${BOLD}PID or command to trace → ${NC}"; read -r target
  [ -z "$target" ] && return
  if [[ "$target" =~ ^[0-9]+$ ]]; then
    strace -p "$target" 2>/dev/null | head -100
  else
    strace $target 2>&1 | head -100
  fi
  echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

hash_menu() {
  echo -ne "  ${BOLD}File or text to hash → ${NC}"; read -r input
  echo ""
  if [ -f "$input" ]; then
    echo -e "  ${GREEN}MD5:${NC}    $(md5sum "$input" | awk '{print $1}')"
    echo -e "  ${GREEN}SHA1:${NC}   $(sha1sum "$input" | awk '{print $1}')"
    echo -e "  ${GREEN}SHA256:${NC} $(sha256sum "$input" | awk '{print $1}')"
  else
    echo -e "  ${GREEN}MD5:${NC}    $(echo -n "$input" | md5sum | awk '{print $1}')"
    echo -e "  ${GREEN}SHA1:${NC}   $(echo -n "$input" | sha1sum | awk '{print $1}')"
    echo -e "  ${GREEN}SHA256:${NC} $(echo -n "$input" | sha256sum | awk '{print $1}')"
  fi
  echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

base64_menu() {
  echo -e "\n  ${CYAN}[1]${NC} Encode  ${CYAN}[2]${NC} Decode  ${CYAN}[3]${NC} Encode file  ${CYAN}[4]${NC} Decode file"
  echo -ne "  ${BOLD}Choice → ${NC}"; read -r c
  case "$c" in
    1) echo -ne "  Text: "; read -r t; echo -n "$t" | base64 ;;
    2) echo -ne "  Base64: "; read -r t; echo "$t" | base64 -d ;;
    3) echo -ne "  File: "; read -r f; base64 "$f" ;;
    4) echo -ne "  Base64 file: "; read -r f; base64 -d "$f" ;;
  esac
  echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

gen_passwords() {
  echo -ne "  ${BOLD}Length (default 24) → ${NC}"; read -r len; len=${len:-24}
  echo -ne "  ${BOLD}Count (default 10) → ${NC}"; read -r count; count=${count:-10}
  echo ""
  for i in $(seq 1 "$count"); do
    cat /dev/urandom | tr -dc 'A-Za-z0-9!@#$%^&*' | head -c "$len"; echo
  done
  echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

security_menu
