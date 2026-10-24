#!/data/data/com.termux/files/usr/bin/bash
# =============================================================================
# DevTools Complete Installer for Samsung S24 / Android (Termux)
# Run this once after installing Termux from F-Droid.
# Usage: bash install.sh
# =============================================================================

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/modules/colors.sh" 2>/dev/null || {
  GREEN='\033[0;32m'; CYAN='\033[0;36m'; RED='\033[0;31m'; NC='\033[0m'
  success() { echo -e "${GREEN}[✔]${NC} $1"; }
  info()    { echo -e "${CYAN}[ℹ]${NC} $1"; }
  error()   { echo -e "${RED}[✘]${NC} $1"; }
  step()    { echo -e "[→] $1"; }
}

clear
echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║     Samsung S24 DevTools — Full Installer v1.0       ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════╝${NC}"
echo ""

# Verify we're in Termux
if [ ! -d "/data/data/com.termux" ]; then
  error "This script must run inside Termux on Android."
  error "Install Termux from F-Droid: https://f-droid.org"
  exit 1
fi

INSTALL_DIR="$HOME/.devtools"
mkdir -p "$INSTALL_DIR"

# ── STEP 1: Storage Permission ────────────────────────────────────────────────
echo ""
echo -e "${CYAN}[1/9] Storage Access${NC}"
info "Requesting storage permission..."
termux-setup-storage 2>/dev/null || true
sleep 1
success "Storage access configured"

# ── STEP 2: Update Packages ───────────────────────────────────────────────────
echo ""
echo -e "${CYAN}[2/9] Updating Package Lists${NC}"
step "Running pkg update..."
pkg update -y 2>/dev/null | tail -3
pkg upgrade -y 2>/dev/null | tail -3
success "Packages updated"

# ── STEP 3: Core System Tools ─────────────────────────────────────────────────
echo ""
echo -e "${CYAN}[3/9] Installing Core Tools${NC}"

CORE_PACKAGES=(
  termux-api        # Device sensor/hardware access
  android-tools     # adb + fastboot
  openssh           # SSH client & server
  git               # Version control
  curl wget         # HTTP tools
  vim nano          # Editors
  htop              # Process monitor
  neofetch          # System info
  tree              # Directory viewer
  zip unzip p7zip   # Archive tools
  file              # File type detection
  lsof              # Open file/connection lister
  strace            # System call tracer
  binutils          # Binary utilities (strings, objdump, nm, readelf)
  proot             # Fake root environment
  tsu               # Root shell (if rooted)
  diffutils         # diff, patch
  gawk sed          # Text processing
  jq                # JSON processor
  bc                # Calculator
)

for pkg in "${CORE_PACKAGES[@]}"; do
  step "Installing $pkg..."
  pkg install -y $pkg 2>/dev/null && success "$pkg" || warn "$pkg skipped (unavailable)"
done

# ── STEP 4: Network Tools ─────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}[4/9] Installing Network Tools${NC}"

NET_PACKAGES=(
  nmap              # Network scanner
  netcat-openbsd    # Network swiss army knife
  tcpdump           # Packet capture (needs root)
  tshark            # Wireshark CLI — packet analysis
  iperf3            # Bandwidth testing
  mtr               # Network diagnostic (ping + traceroute)
  dnsutils          # dig, nslookup, host
  net-tools         # ifconfig, netstat, arp
  iproute2          # ip command
  whois             # WHOIS lookups
  socat             # Data relay between connections
  proxychains-ng    # Route traffic through proxies
  tor               # Anonymous routing
  hydra             # Password brute-force (authorized testing only)
  masscan           # High-speed port scanner
)

for pkg in "${NET_PACKAGES[@]}"; do
  step "Installing $pkg..."
  pkg install -y $pkg 2>/dev/null && success "$pkg" || warn "$pkg skipped"
done

# ── STEP 5: Development Tools ─────────────────────────────────────────────────
echo ""
echo -e "${CYAN}[5/9] Installing Development Tools${NC}"

DEV_PACKAGES=(
  python            # Python 3
  python-pip        # pip package manager
  nodejs            # Node.js + npm
  ruby              # Ruby runtime
  clang             # C/C++ compiler
  make cmake        # Build tools
  gdb               # GNU Debugger
  lldb              # LLVM Debugger
  openjdk-17        # Java (for apktool, jadx)
  gradle            # Java build tool
)

for pkg in "${DEV_PACKAGES[@]}"; do
  step "Installing $pkg..."
  pkg install -y $pkg 2>/dev/null && success "$pkg" || warn "$pkg skipped"
done

# ── STEP 6: Python Security Tools ─────────────────────────────────────────────
echo ""
echo -e "${CYAN}[6/9] Installing Python Security Tools${NC}"

pip install --upgrade pip 2>/dev/null | tail -1

PIP_PACKAGES=(
  "frida-tools"         # Dynamic instrumentation framework
  "objection"           # Runtime mobile exploration (Frida-based)
  "sqlmap"              # SQL injection testing
  "requests"            # HTTP library
  "scapy"               # Packet crafting & sniffing
  "impacket"            # Network protocol implementation
  "pwntools"            # CTF & exploit dev toolkit
  "paramiko"            # SSH library
  "cryptography"        # Crypto primitives
  "pyOpenSSL"           # TLS/SSL library
  "dnspython"           # DNS toolkit
  "httpx"               # Modern HTTP client
  "rich"                # Beautiful terminal output
  "click"               # CLI framework
  "pycparser"           # C parser (used by tools)
  "androguard"          # Android APK analysis
  "apkutils2"           # APK utilities
  "jadx-python"         # JADX Python bindings (if available)
  "volatility3"         # Memory forensics
)

for pkg in "${PIP_PACKAGES[@]}"; do
  step "pip install $pkg..."
  pip install "$pkg" 2>/dev/null | tail -1 && success "$pkg" || warn "$pkg skipped"
done

# ── STEP 7: APK Tools ─────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}[7/9] Installing APK Analysis Tools${NC}"

# apktool
if ! command -v apktool &>/dev/null; then
  step "Installing apktool..."
  mkdir -p "$INSTALL_DIR/apktool"
  APKTOOL_VER="2.9.3"
  curl -sL "https://github.com/iBotPeaches/Apktool/releases/download/v${APKTOOL_VER}/apktool_${APKTOOL_VER}.jar" \
    -o "$INSTALL_DIR/apktool/apktool.jar" 2>/dev/null
  cat > "$PREFIX/bin/apktool" <<'APKTOOL_EOF'
#!/data/data/com.termux/files/usr/bin/bash
java -jar "$HOME/.devtools/apktool/apktool.jar" "$@"
APKTOOL_EOF
  chmod +x "$PREFIX/bin/apktool"
  success "apktool installed"
else
  success "apktool already present"
fi

# jadx
if ! command -v jadx &>/dev/null; then
  step "Installing jadx (APK decompiler)..."
  mkdir -p "$INSTALL_DIR/jadx"
  JADX_VER="1.5.0"
  curl -sL "https://github.com/skylot/jadx/releases/download/v${JADX_VER}/jadx-${JADX_VER}.zip" \
    -o "$INSTALL_DIR/jadx/jadx.zip" 2>/dev/null
  unzip -qo "$INSTALL_DIR/jadx/jadx.zip" -d "$INSTALL_DIR/jadx/" 2>/dev/null
  ln -sf "$INSTALL_DIR/jadx/bin/jadx" "$PREFIX/bin/jadx" 2>/dev/null
  success "jadx installed"
else
  success "jadx already present"
fi

# ── STEP 8: Frida Server Setup ────────────────────────────────────────────────
echo ""
echo -e "${CYAN}[8/9] Setting Up Frida Server${NC}"

FRIDA_VER=$(frida --version 2>/dev/null || echo "")
if [ -n "$FRIDA_VER" ]; then
  step "Downloading Frida server v${FRIDA_VER} for arm64..."
  FRIDA_SERVER="$INSTALL_DIR/frida-server"
  mkdir -p "$FRIDA_SERVER"
  FRIDA_URL="https://github.com/frida/frida/releases/download/${FRIDA_VER}/frida-server-${FRIDA_VER}-android-arm64.xz"
  if curl -sL "$FRIDA_URL" -o "$FRIDA_SERVER/frida-server.xz" 2>/dev/null; then
    xz -df "$FRIDA_SERVER/frida-server.xz" -o "$FRIDA_SERVER/frida-server" 2>/dev/null
    chmod +x "$FRIDA_SERVER/frida-server"
    cat > "$PREFIX/bin/start-frida-server" <<FRIDA_EOF
#!/data/data/com.termux/files/usr/bin/bash
# Requires root. Push frida-server to /data/local/tmp/ and run as root.
echo "[Frida] Copying frida-server to /data/local/tmp/..."
adb push "$HOME/.devtools/frida-server/frida-server" /data/local/tmp/ 2>/dev/null
adb shell "chmod +x /data/local/tmp/frida-server" 2>/dev/null
echo "[Frida] Starting frida-server (needs root via adb)..."
adb shell "su -c '/data/local/tmp/frida-server &'" 2>/dev/null || \
  adb shell "/data/local/tmp/frida-server &" 2>/dev/null
echo "[Frida] Server started. Run: frida-ps -U"
FRIDA_EOF
    chmod +x "$PREFIX/bin/start-frida-server"
    success "Frida server v${FRIDA_VER} ready — run: start-frida-server"
  else
    warn "Could not download Frida server (network issue) — run start-frida-server later"
  fi
else
  warn "frida-tools not installed — Frida server setup skipped"
fi

# ── STEP 9: Install DevTools Suite & Aliases ─────────────────────────────────
echo ""
echo -e "${CYAN}[9/9] Configuring DevTools Suite${NC}"

# Copy devtools scripts
DEVTOOLS_DEST="$HOME/.devtools/scripts"
mkdir -p "$DEVTOOLS_DEST"
cp -r "$SCRIPT_DIR/modules/"* "$DEVTOOLS_DEST/" 2>/dev/null || true
cp "$SCRIPT_DIR/devtools.sh" "$DEVTOOLS_DEST/" 2>/dev/null || true

# Create main launcher in PATH
cat > "$PREFIX/bin/devtools" <<LAUNCHER_EOF
#!/data/data/com.termux/files/usr/bin/bash
bash "$HOME/.devtools/scripts/devtools.sh" "\$@"
LAUNCHER_EOF
chmod +x "$PREFIX/bin/devtools"

# Add aliases to ~/.bashrc
ALIAS_BLOCK='
# ── DevTools Suite ──────────────────────────────────
alias dt="devtools"
alias sysinfo="bash ~/.devtools/scripts/device-info.sh"
alias nettools="bash ~/.devtools/scripts/network.sh"
alias perfmon="bash ~/.devtools/scripts/performance.sh"
alias logwatch="bash ~/.devtools/scripts/logs.sh"
alias adbtools="bash ~/.devtools/scripts/adb.sh"
alias sectools="bash ~/.devtools/scripts/security.sh"
alias pkgtools="bash ~/.devtools/scripts/packages.sh"
alias sshserver="bash ~/.devtools/scripts/ssh.sh"
alias fridatools="bash ~/.devtools/scripts/frida.sh"
# ─────────────────────────────────────────────────────
'

if ! grep -q "DevTools Suite" ~/.bashrc 2>/dev/null; then
  echo "$ALIAS_BLOCK" >> ~/.bashrc
  success "Aliases added to ~/.bashrc"
fi

# SSH server config
mkdir -p ~/.ssh
ssh-keygen -A 2>/dev/null || true

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║           ✔  Installation Complete!                  ║${NC}"
echo -e "${GREEN}╠══════════════════════════════════════════════════════╣${NC}"
echo -e "${GREEN}║  Launch:   devtools          (main menu)             ║${NC}"
echo -e "${GREEN}║  Aliases:  sysinfo / nettools / perfmon / logwatch   ║${NC}"
echo -e "${GREEN}║  Reload:   source ~/.bashrc                          ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${NC}"
echo ""
info "Run: source ~/.bashrc && devtools"
