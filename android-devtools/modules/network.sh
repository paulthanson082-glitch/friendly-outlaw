#!/data/data/com.termux/files/usr/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/colors.sh" 2>/dev/null

network_menu() {
  while true; do
    header
    echo -e "  ${WHITE}${BOLD}NETWORK TOOLS${NC}"
    echo ""
    echo -e "  ${CYAN}[1]${NC}  nmap — Network/port scanner"
    echo -e "  ${CYAN}[2]${NC}  tshark — Packet capture & analysis (needs root/pcap)"
    echo -e "  ${CYAN}[3]${NC}  iperf3 — Bandwidth speed test"
    echo -e "  ${CYAN}[4]${NC}  mtr — Traceroute + ping combined"
    echo -e "  ${CYAN}[5]${NC}  DNS Tools — dig / nslookup / host"
    echo -e "  ${CYAN}[6]${NC}  HTTP Client — curl / httpx"
    echo -e "  ${CYAN}[7]${NC}  Active connections — netstat / ss"
    echo -e "  ${CYAN}[8]${NC}  WiFi Info — SSID, signal, channels"
    echo -e "  ${CYAN}[9]${NC}  Proxy setup — proxychains / Tor"
    echo -e "  ${CYAN}[a]${NC}  whois lookup"
    echo -e "  ${CYAN}[b]${NC}  socat relay"
    echo -e "  ${CYAN}[c]${NC}  netcat — port listener / sender"
    echo ""
    echo -e "  ${RED}[x]${NC}  Back"
    echo ""
    echo -ne "  ${BOLD}Choice → ${NC}"
    read -r choice

    case "$choice" in
      1) nmap_menu ;;
      2) tshark_menu ;;
      3) iperf_menu ;;
      4) mtr_menu ;;
      5) dns_tools ;;
      6) http_client ;;
      7) active_connections ;;
      8) wifi_info ;;
      9) proxy_setup ;;
      a|A) whois_lookup ;;
      b|B) socat_relay ;;
      c|C) netcat_menu ;;
      x|X) return ;;
      *) warn "Invalid"; sleep 1 ;;
    esac
  done
}

nmap_menu() {
  header
  echo -e "  ${WHITE}${BOLD}NMAP — Network Scanner${NC}"
  echo ""
  echo -e "  ${CYAN}[1]${NC}  Quick scan — top 1000 ports"
  echo -e "  ${CYAN}[2]${NC}  Full TCP port scan (1-65535)"
  echo -e "  ${CYAN}[3]${NC}  Service & version detection"
  echo -e "  ${CYAN}[4]${NC}  OS detection scan"
  echo -e "  ${CYAN}[5]${NC}  Ping sweep — find live hosts on subnet"
  echo -e "  ${CYAN}[6]${NC}  Aggressive scan (all detections)"
  echo -e "  ${CYAN}[7]${NC}  Custom nmap command"
  echo ""
  echo -ne "  ${BOLD}Scan type → ${NC}"; read -r scan_type
  echo -ne "  ${BOLD}Target IP/hostname/range → ${NC}"; read -r target
  [ -z "$target" ] && { warn "No target specified"; sleep 1; return; }

  echo ""
  case "$scan_type" in
    1) step "nmap -T4 $target"; nmap -T4 "$target" ;;
    2) step "nmap -T4 -p- $target"; nmap -T4 -p- "$target" ;;
    3) step "nmap -sV -T4 $target"; nmap -sV -T4 "$target" ;;
    4) step "nmap -O -T4 $target"; nmap -O -T4 "$target" 2>/dev/null || \
       warn "OS detection may need root. Trying without -O..."; nmap -sV "$target" ;;
    5) step "nmap -sn $target"; nmap -sn "$target" ;;
    6) step "nmap -A -T4 $target"; nmap -A -T4 "$target" ;;
    7) echo -ne "  ${BOLD}Enter full nmap command (nmap ...): ${NC}"; read -r cmd; eval "$cmd" ;;
    *) warn "Invalid" ;;
  esac
  echo ""
  echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

tshark_menu() {
  header
  echo -e "  ${WHITE}${BOLD}TSHARK — Packet Analysis${NC}"
  echo ""
  echo -e "  ${CYAN}[1]${NC}  List network interfaces"
  echo -e "  ${CYAN}[2]${NC}  Capture on wlan0 (20 packets)"
  echo -e "  ${CYAN}[3]${NC}  Capture HTTP traffic"
  echo -e "  ${CYAN}[4]${NC}  Capture DNS queries"
  echo -e "  ${CYAN}[5]${NC}  Capture to file (pcap)"
  echo -e "  ${CYAN}[6]${NC}  Analyze existing pcap file"
  echo -e "  ${CYAN}[7]${NC}  Custom tshark command"
  echo ""
  echo -ne "  ${BOLD}Choice → ${NC}"; read -r c
  case "$c" in
    1) tshark -D 2>/dev/null || echo "tshark not installed" ;;
    2) tshark -i wlan0 -c 20 2>/dev/null ;;
    3) tshark -i wlan0 -f "tcp port 80 or tcp port 8080" 2>/dev/null ;;
    4) tshark -i wlan0 -f "udp port 53" 2>/dev/null ;;
    5) echo -ne "  Output file path: "; read -r f
       tshark -i wlan0 -w "$f" 2>/dev/null ;;
    6) echo -ne "  pcap file path: "; read -r f
       tshark -r "$f" 2>/dev/null ;;
    7) echo -ne "  Command: "; read -r cmd; eval "$cmd" ;;
  esac
  echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

iperf_menu() {
  header
  echo -e "  ${WHITE}${BOLD}IPERF3 — Bandwidth Testing${NC}"
  echo ""
  echo -e "  ${CYAN}[1]${NC}  Run as server (waits for connections)"
  echo -e "  ${CYAN}[2]${NC}  Run as client (connect to iperf3 server)"
  echo -e "  ${CYAN}[3]${NC}  Bidirectional test"
  echo -e "  ${CYAN}[4]${NC}  UDP bandwidth test"
  echo ""
  echo -ne "  ${BOLD}Choice → ${NC}"; read -r c
  case "$c" in
    1) info "Starting iperf3 server on port 5201..."; iperf3 -s ;;
    2) echo -ne "  Server IP: "; read -r ip
       iperf3 -c "$ip" -t 10 ;;
    3) echo -ne "  Server IP: "; read -r ip
       iperf3 -c "$ip" -t 10 --bidir ;;
    4) echo -ne "  Server IP: "; read -r ip
       iperf3 -c "$ip" -u -b 100M -t 10 ;;
  esac
  echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

mtr_menu() {
  echo -ne "  ${BOLD}Target hostname/IP → ${NC}"; read -r target
  [ -z "$target" ] && return
  mtr --report --report-cycles 5 "$target" 2>/dev/null || \
  traceroute "$target" 2>/dev/null || \
  warn "mtr/traceroute not available"
  echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

dns_tools() {
  header
  echo -e "  ${WHITE}${BOLD}DNS TOOLS${NC}"
  echo ""
  echo -ne "  ${BOLD}Domain to query → ${NC}"; read -r domain
  [ -z "$domain" ] && return
  echo ""
  echo -e "  ${CYAN}── dig ─────────────────────────────────────${NC}"
  dig "$domain" 2>/dev/null || nslookup "$domain" 2>/dev/null
  echo ""
  echo -e "  ${CYAN}── MX Records ──────────────────────────────${NC}"
  dig MX "$domain" 2>/dev/null | grep -E "^$domain|MX"
  echo ""
  echo -e "  ${CYAN}── Reverse DNS ─────────────────────────────${NC}"
  IP=$(dig +short "$domain" 2>/dev/null | head -1)
  [ -n "$IP" ] && dig -x "$IP" +short 2>/dev/null
  echo ""
  echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

http_client() {
  header
  echo -e "  ${WHITE}${BOLD}HTTP CLIENT${NC}"
  echo ""
  echo -e "  ${CYAN}[1]${NC}  GET request"
  echo -e "  ${CYAN}[2]${NC}  GET with headers"
  echo -e "  ${CYAN}[3]${NC}  POST JSON"
  echo -e "  ${CYAN}[4]${NC}  Download file"
  echo -e "  ${CYAN}[5]${NC}  Follow redirects + show headers"
  echo -e "  ${CYAN}[6]${NC}  Spider — download all linked pages"
  echo ""
  echo -ne "  ${BOLD}Choice → ${NC}"; read -r c
  echo -ne "  ${BOLD}URL → ${NC}"; read -r url
  [ -z "$url" ] && return
  case "$c" in
    1) curl -sL "$url" | python3 -m json.tool 2>/dev/null || curl -sL "$url" ;;
    2) echo -ne "  Headers (e.g. 'Authorization: Bearer token'): "; read -r h
       curl -sL -H "$h" "$url" ;;
    3) echo -ne "  JSON body: "; read -r body
       curl -sL -X POST -H "Content-Type: application/json" -d "$body" "$url" ;;
    4) echo -ne "  Save as: "; read -r fname
       curl -L "$url" -o "${fname:-download}" --progress-bar ;;
    5) curl -sIL "$url" ;;
    6) wget --spider -r -nd "$url" 2>&1 | head -50 ;;
  esac
  echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

active_connections() {
  header
  echo -e "  ${WHITE}${BOLD}ACTIVE CONNECTIONS${NC}"
  echo ""
  echo -e "  ${CYAN}── TCP Connections ─────────────────────────────────────${NC}"
  ss -tnp 2>/dev/null || netstat -tnp 2>/dev/null | head -30
  echo ""
  echo -e "  ${CYAN}── UDP Sockets ─────────────────────────────────────────${NC}"
  ss -unp 2>/dev/null | head -20
  echo ""
  echo -e "  ${CYAN}── Listening Ports ─────────────────────────────────────${NC}"
  ss -tlnp 2>/dev/null || netstat -tlnp 2>/dev/null | head -20
  echo ""
  echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

wifi_info() {
  header
  echo -e "  ${WHITE}${BOLD}WIFI INFO${NC}"
  echo ""
  # Via termux-api
  if command -v termux-wifi-connectioninfo &>/dev/null; then
    info "Current connection:"
    termux-wifi-connectioninfo 2>/dev/null | python3 -m json.tool 2>/dev/null
  fi
  echo ""
  # Via iw/iwconfig
  if command -v iw &>/dev/null; then
    info "iw dev:"
    iw dev 2>/dev/null
    echo ""
    info "Station info:"
    iw dev wlan0 station dump 2>/dev/null | head -30
  fi
  # iwconfig fallback
  iwconfig 2>/dev/null | head -20
  echo ""
  echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

proxy_setup() {
  header
  echo -e "  ${WHITE}${BOLD}PROXY / TOR SETUP${NC}"
  echo ""
  echo -e "  ${CYAN}[1]${NC}  Start Tor (anonymous routing)"
  echo -e "  ${CYAN}[2]${NC}  Check Tor status / current IP"
  echo -e "  ${CYAN}[3]${NC}  Run command through proxychains"
  echo -e "  ${CYAN}[4]${NC}  Configure HTTP proxy env vars"
  echo ""
  echo -ne "  ${BOLD}Choice → ${NC}"; read -r c
  case "$c" in
    1) tor & sleep 3; curl -s --socks5 127.0.0.1:9050 https://check.torproject.org/api/ip 2>/dev/null | python3 -m json.tool ;;
    2) curl -s --socks5 127.0.0.1:9050 https://api.ipify.org 2>/dev/null && echo "" ;;
    3) echo -ne "  Command to run via proxychains: "; read -r cmd
       proxychains4 $cmd 2>/dev/null ;;
    4) echo -ne "  Proxy URL (e.g. http://192.168.1.5:8080): "; read -r proxy
       export http_proxy="$proxy"; export https_proxy="$proxy"
       echo "export http_proxy=\"$proxy\"" >> ~/.bashrc
       success "Proxy set: $proxy" ;;
  esac
  echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

whois_lookup() {
  echo -ne "  ${BOLD}Domain or IP → ${NC}"; read -r target
  [ -z "$target" ] && return
  whois "$target" 2>/dev/null | head -50
  echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

socat_relay() {
  header
  echo -e "  ${WHITE}${BOLD}SOCAT — Data Relay${NC}"
  echo ""
  echo -e "  ${CYAN}[1]${NC}  TCP port forward (e.g. localhost:8080 → remote:80)"
  echo -e "  ${CYAN}[2]${NC}  Listen on TCP port and show data"
  echo -e "  ${CYAN}[3]${NC}  Connect to TCP and send stdin"
  echo -e "  ${CYAN}[4]${NC}  SSL/TLS client connect"
  echo ""
  echo -ne "  ${BOLD}Choice → ${NC}"; read -r c
  case "$c" in
    1) echo -ne "  Local port: "; read -r lp
       echo -ne "  Remote host:port: "; read -r rp
       socat TCP-LISTEN:"$lp",reuseaddr,fork TCP:"$rp" ;;
    2) echo -ne "  Port to listen on: "; read -r p
       socat TCP-LISTEN:"$p",reuseaddr - ;;
    3) echo -ne "  host:port: "; read -r hp
       socat - TCP:"$hp" ;;
    4) echo -ne "  host:port: "; read -r hp
       socat - OPENSSL:"$hp" ;;
  esac
  echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

netcat_menu() {
  header
  echo -e "  ${WHITE}${BOLD}NETCAT${NC}"
  echo ""
  echo -e "  ${CYAN}[1]${NC}  Listen on port"
  echo -e "  ${CYAN}[2]${NC}  Connect to host:port"
  echo -e "  ${CYAN}[3]${NC}  Port scan (nc)"
  echo -e "  ${CYAN}[4]${NC}  Send file to remote"
  echo ""
  echo -ne "  ${BOLD}Choice → ${NC}"; read -r c
  case "$c" in
    1) echo -ne "  Port: "; read -r p; nc -lvp "$p" ;;
    2) echo -ne "  Host: "; read -r h; echo -ne "  Port: "; read -r p; nc "$h" "$p" ;;
    3) echo -ne "  Host: "; read -r h
       echo -ne "  Port range (e.g. 1-1000): "; read -r r
       nc -zv "$h" $r 2>&1 | grep succeeded ;;
    4) echo -ne "  File: "; read -r f
       echo -ne "  Host: "; read -r h; echo -ne "  Port: "; read -r p
       nc "$h" "$p" < "$f" ;;
  esac
  echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

network_menu
