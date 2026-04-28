#!/data/data/com.termux/files/usr/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/colors.sh" 2>/dev/null

ssh_menu() {
  while true; do
    header
    echo -e "  ${WHITE}${BOLD}SSH SERVER & CLIENT${NC}"
    echo ""

    # Show SSH server status
    if pgrep -x sshd >/dev/null 2>&1; then
      echo -e "  ${GREEN}● SSH Server: RUNNING${NC}"
      SSH_PORT=$(grep "^Port" ~/.ssh/sshd_config 2>/dev/null | awk '{print $2}' || echo "8022")
      DEVICE_IP=$(ip route get 1 2>/dev/null | awk '{print $7; exit}' || hostname -I 2>/dev/null | awk '{print $1}')
      echo -e "  ${DIM}  Connect from PC: ssh -p ${SSH_PORT} $(whoami)@${DEVICE_IP}${NC}"
    else
      echo -e "  ${RED}● SSH Server: STOPPED${NC}"
    fi
    echo ""

    echo -e "  ${CYAN}── Server ─────────────────────────────────────────────${NC}"
    echo -e "  ${CYAN}[1]${NC}  Start SSH server"
    echo -e "  ${CYAN}[2]${NC}  Stop SSH server"
    echo -e "  ${CYAN}[3]${NC}  Show connection info"
    echo -e "  ${CYAN}[4]${NC}  Change SSH port"
    echo -e "  ${CYAN}[5]${NC}  Manage authorized keys"
    echo ""
    echo -e "  ${CYAN}── Client ─────────────────────────────────────────────${NC}"
    echo -e "  ${CYAN}[6]${NC}  Connect to remote host"
    echo -e "  ${CYAN}[7]${NC}  Generate SSH key pair"
    echo -e "  ${CYAN}[8]${NC}  Copy public key to remote"
    echo -e "  ${CYAN}[9]${NC}  SCP — copy files to/from remote"
    echo -e "  ${CYAN}[a]${NC}  SSH tunnel (port forward)"
    echo -e "  ${CYAN}[b]${NC}  SFTP interactive session"
    echo ""
    echo -e "  ${RED}[x]${NC}  Back"
    echo ""
    echo -ne "  ${BOLD}Choice → ${NC}"
    read -r choice

    case "$choice" in
      1) start_sshd ;;
      2) stop_sshd ;;
      3) show_ssh_info ;;
      4) change_ssh_port ;;
      5) manage_keys ;;
      6) ssh_connect ;;
      7) gen_key ;;
      8) copy_key ;;
      9) scp_menu ;;
      a|A) ssh_tunnel ;;
      b|B) sftp_menu ;;
      x|X) return ;;
      *) warn "Invalid"; sleep 1 ;;
    esac
  done
}

start_sshd() {
  if pgrep -x sshd >/dev/null 2>&1; then
    warn "SSH server already running"
  else
    # Ensure host keys exist
    ssh-keygen -A 2>/dev/null
    sshd 2>/dev/null
    sleep 1
    if pgrep -x sshd >/dev/null 2>&1; then
      success "SSH server started"
      show_ssh_info
    else
      error "Failed to start SSH server"
    fi
  fi
  echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

stop_sshd() {
  pkill sshd 2>/dev/null && success "SSH server stopped" || warn "SSH server was not running"
  echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

show_ssh_info() {
  header
  echo -e "  ${WHITE}${BOLD}SSH CONNECTION INFO${NC}"
  echo ""
  SSH_PORT=$(grep "^Port" "$PREFIX/etc/ssh/sshd_config" 2>/dev/null | awk '{print $2}' || echo "8022")
  WIFI_IP=$(ip route get 1 2>/dev/null | awk '{print $7; exit}' || \
            ip addr show wlan0 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
  USB_IP=$(ip addr show rndis0 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d/ -f1 || \
           ip addr show usb0 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
  USER=$(whoami)

  echo -e "  ${GREEN}Username:${NC}   $USER"
  echo -e "  ${GREEN}SSH Port:${NC}   $SSH_PORT"
  echo ""
  [ -n "$WIFI_IP" ] && {
    echo -e "  ${CYAN}── Via WiFi ────────────────────────────────────────────${NC}"
    echo -e "  ${GREEN}WiFi IP:${NC}    $WIFI_IP"
    echo -e "  ${YELLOW}Connect:${NC}    ssh -p $SSH_PORT $USER@$WIFI_IP"
    echo -e "  ${YELLOW}VSCode:${NC}     Remote-SSH: $USER@$WIFI_IP:$SSH_PORT"
  }
  [ -n "$USB_IP" ] && {
    echo ""
    echo -e "  ${CYAN}── Via USB ─────────────────────────────────────────────${NC}"
    echo -e "  ${GREEN}USB IP:${NC}     $USB_IP"
    echo -e "  ${YELLOW}Connect:${NC}    ssh -p $SSH_PORT $USER@$USB_IP"
  }
  echo ""
  echo -e "  ${GREEN}Public key:${NC}"
  cat ~/.ssh/authorized_keys 2>/dev/null | head -3 | sed 's/^/    /' || \
  info "No authorized keys yet — use option [7] to generate a key"
  echo ""
  echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

change_ssh_port() {
  SSHD_CONFIG="$PREFIX/etc/ssh/sshd_config"
  CURRENT=$(grep "^Port" "$SSHD_CONFIG" 2>/dev/null | awk '{print $2}' || echo "8022")
  echo -ne "  ${BOLD}New port (current: $CURRENT) → ${NC}"; read -r port
  [ -z "$port" ] && return
  if grep -q "^Port" "$SSHD_CONFIG" 2>/dev/null; then
    sed -i "s/^Port.*/Port $port/" "$SSHD_CONFIG"
  else
    echo "Port $port" >> "$SSHD_CONFIG"
  fi
  success "SSH port changed to $port — restart SSH to apply"
  echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

manage_keys() {
  header
  echo -e "  ${WHITE}${BOLD}AUTHORIZED KEYS${NC}"
  echo ""
  echo -e "  ${CYAN}[1]${NC}  View authorized keys"
  echo -e "  ${CYAN}[2]${NC}  Add public key"
  echo -e "  ${CYAN}[3]${NC}  Remove a key"
  echo -e "  ${CYAN}[4]${NC}  Show my public key"
  echo ""
  echo -ne "  ${BOLD}Choice → ${NC}"; read -r c
  case "$c" in
    1) cat ~/.ssh/authorized_keys 2>/dev/null || warn "No authorized keys" ;;
    2) echo "Paste public key (one line):"; read -r key
       echo "$key" >> ~/.ssh/authorized_keys
       success "Key added" ;;
    3) cat -n ~/.ssh/authorized_keys 2>/dev/null
       echo -ne "  Line number to remove: "; read -r n
       sed -i "${n}d" ~/.ssh/authorized_keys 2>/dev/null
       success "Key removed" ;;
    4) cat ~/.ssh/id_rsa.pub 2>/dev/null || cat ~/.ssh/id_ed25519.pub 2>/dev/null || \
       warn "No public key — generate one first" ;;
  esac
  echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

ssh_connect() {
  echo -ne "  ${BOLD}user@host → ${NC}"; read -r host
  echo -ne "  ${BOLD}Port (default 22) → ${NC}"; read -r port; port=${port:-22}
  [ -z "$host" ] && return
  ssh -p "$port" "$host"
}

gen_key() {
  echo -e "\n  ${CYAN}[1]${NC} ed25519 (recommended)  ${CYAN}[2]${NC} RSA 4096"
  echo -ne "  ${BOLD}Choice → ${NC}"; read -r c
  echo -ne "  ${BOLD}Key filename (default: id_ed25519) → ${NC}"; read -r fname
  fname=${fname:-id_ed25519}
  case "$c" in
    2) ssh-keygen -t rsa -b 4096 -f "$HOME/.ssh/$fname" ;;
    *) ssh-keygen -t ed25519 -f "$HOME/.ssh/$fname" ;;
  esac
  echo ""
  echo -e "  ${GREEN}Public key:${NC}"
  cat "$HOME/.ssh/${fname}.pub" 2>/dev/null | sed 's/^/  /'
  echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

copy_key() {
  echo -ne "  ${BOLD}user@remote-host → ${NC}"; read -r host
  echo -ne "  ${BOLD}Remote port (default 22) → ${NC}"; read -r port; port=${port:-22}
  [ -z "$host" ] && return
  ssh-copy-id -p "$port" "$host" 2>/dev/null || {
    # Manual fallback
    PUBKEY=$(cat ~/.ssh/id_ed25519.pub 2>/dev/null || cat ~/.ssh/id_rsa.pub 2>/dev/null)
    [ -n "$PUBKEY" ] && \
    ssh -p "$port" "$host" "mkdir -p ~/.ssh && echo '$PUBKEY' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
  }
  echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

scp_menu() {
  echo -e "\n  ${CYAN}[1]${NC} Upload (local → remote)  ${CYAN}[2]${NC} Download (remote → local)"
  echo -ne "  ${BOLD}Choice → ${NC}"; read -r c
  echo -ne "  ${BOLD}Remote user@host → ${NC}"; read -r host
  echo -ne "  ${BOLD}Remote port (default 22) → ${NC}"; read -r port; port=${port:-22}
  case "$c" in
    1) echo -ne "  Local file: "; read -r local
       echo -ne "  Remote path: "; read -r remote
       scp -P "$port" "$local" "${host}:${remote}" ;;
    2) echo -ne "  Remote file path: "; read -r remote
       echo -ne "  Local save path: "; read -r local; local=${local:-.}
       scp -P "$port" "${host}:${remote}" "$local" ;;
  esac
  echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

ssh_tunnel() {
  header
  echo -e "  ${WHITE}${BOLD}SSH TUNNEL (Port Forward)${NC}"
  echo ""
  echo -e "  ${CYAN}[1]${NC}  Local forward (access remote service locally)"
  echo -e "  ${CYAN}[2]${NC}  Remote forward (expose local service to remote)"
  echo -e "  ${CYAN}[3]${NC}  Dynamic SOCKS5 proxy"
  echo ""
  echo -ne "  ${BOLD}Choice → ${NC}"; read -r c
  echo -ne "  ${BOLD}SSH server user@host → ${NC}"; read -r host
  echo -ne "  ${BOLD}SSH port (default 22) → ${NC}"; read -r sport; sport=${sport:-22}
  case "$c" in
    1) echo -ne "  Local port: "; read -r lp
       echo -ne "  Remote host:port: "; read -r rp
       info "Forwarding localhost:$lp → $rp via $host"
       ssh -p "$sport" -L "$lp:$rp" -N "$host" ;;
    2) echo -ne "  Remote port: "; read -r rp
       echo -ne "  Local host:port: "; read -r lp
       info "Exposing $lp as $host:$rp"
       ssh -p "$sport" -R "$rp:$lp" -N "$host" ;;
    3) echo -ne "  Local SOCKS5 port (default 1080): "; read -r sp; sp=${sp:-1080}
       info "SOCKS5 proxy on localhost:$sp via $host"
       ssh -p "$sport" -D "$sp" -N "$host" ;;
  esac
  echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

sftp_menu() {
  echo -ne "  ${BOLD}user@host → ${NC}"; read -r host
  echo -ne "  ${BOLD}Port (default 22) → ${NC}"; read -r port; port=${port:-22}
  [ -z "$host" ] && return
  sftp -P "$port" "$host"
}

ssh_menu
