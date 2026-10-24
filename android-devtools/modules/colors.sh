#!/data/data/com.termux/files/usr/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

header() {
  clear
  echo -e "${CYAN}${BOLD}"
  echo "  ██████╗ ███████╗██╗   ██╗████████╗ ██████╗  ██████╗ ██╗     ███████╗"
  echo "  ██╔══██╗██╔════╝██║   ██║╚══██╔══╝██╔═══██╗██╔═══██╗██║     ██╔════╝"
  echo "  ██║  ██║█████╗  ██║   ██║   ██║   ██║   ██║██║   ██║██║     ███████╗"
  echo "  ██║  ██║██╔══╝  ╚██╗ ██╔╝   ██║   ██║   ██║██║   ██║██║     ╚════██║"
  echo "  ██████╔╝███████╗ ╚████╔╝    ██║   ╚██████╔╝╚██████╔╝███████╗███████║"
  echo "  ╚═════╝ ╚══════╝  ╚═══╝     ╚═╝    ╚═════╝  ╚═════╝ ╚══════╝╚══════╝"
  echo -e "${NC}"
  echo -e "  ${DIM}Samsung S24 Developer Toolkit — All Tools Unified${NC}"
  echo -e "  ${DIM}─────────────────────────────────────────────────${NC}"
  echo ""
}

success() { echo -e "${GREEN}[✔]${NC} $1"; }
info()    { echo -e "${CYAN}[ℹ]${NC} $1"; }
warn()    { echo -e "${YELLOW}[⚠]${NC} $1"; }
error()   { echo -e "${RED}[✘]${NC} $1"; }
step()    { echo -e "${BLUE}[→]${NC} $1"; }
