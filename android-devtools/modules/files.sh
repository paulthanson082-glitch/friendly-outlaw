#!/data/data/com.termux/files/usr/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/colors.sh" 2>/dev/null

files_menu() {
  while true; do
    header
    echo -e "  ${WHITE}${BOLD}FILE & BINARY TOOLS${NC}"
    echo ""
    echo -e "  ${CYAN}[1]${NC}  File browser — list & navigate"
    echo -e "  ${CYAN}[2]${NC}  Find files by name/pattern"
    echo -e "  ${CYAN}[3]${NC}  Find files by content (grep)"
    echo -e "  ${CYAN}[4]${NC}  File type info (file command)"
    echo -e "  ${CYAN}[5]${NC}  Disk usage — find large files"
    echo -e "  ${CYAN}[6]${NC}  Archive: zip / unzip / tar"
    echo -e "  ${CYAN}[7]${NC}  Compare files (diff)"
    echo -e "  ${CYAN}[8]${NC}  Watch file changes (tail -f)"
    echo -e "  ${CYAN}[9]${NC}  File permissions — chmod/chown"
    echo -e "  ${CYAN}[a]${NC}  Sync folders (rsync)"
    echo -e "  ${CYAN}[b]${NC}  Checksums — verify file integrity"
    echo -e "  ${CYAN}[c]${NC}  Binary viewer (xxd / hexdump)"
    echo ""
    echo -e "  ${RED}[x]${NC}  Back"
    echo ""
    echo -ne "  ${BOLD}Choice → ${NC}"
    read -r choice

    case "$choice" in
      1) file_browser ;;
      2) find_files ;;
      3) grep_content ;;
      4) file_type_info ;;
      5) disk_usage ;;
      6) archive_tools ;;
      7) diff_files ;;
      8) watch_file ;;
      9) permissions_menu ;;
      a|A) rsync_menu ;;
      b|B) checksum_menu ;;
      c|C) binary_viewer ;;
      x|X) return ;;
      *) warn "Invalid"; sleep 1 ;;
    esac
  done
}

file_browser() {
  local dir="${1:-$HOME}"
  while true; do
    header
    echo -e "  ${WHITE}${BOLD}FILE BROWSER${NC}  ${DIM}$dir${NC}"
    echo ""
    # List with details
    ls -lAh "$dir" 2>/dev/null | awk '
      NR==1 {print "  " $0; next}
      /^d/ {printf "  \033[34m%-10s\033[0m  %4s  %s\n", $NF, $5, $6" "$7}
      /^-/ {printf "  \033[37m%-10s\033[0m  %4s  %s\n", $NF, $5, $6" "$7}
      /^l/ {printf "  \033[36m%-10s\033[0m  %4s  %s\n", $NF, $5, $6" "$7}
    ' | head -40
    echo ""
    echo -e "  ${DIM}[cd <dir>] [cat <file>] [..] [q=quit]${NC}"
    echo -ne "  ${BOLD}→ ${NC}"; read -r cmd

    case "$cmd" in
      "..") dir=$(dirname "$dir") ;;
      cd\ *) newdir="${cmd#cd }"; [ -d "$dir/$newdir" ] && dir="$dir/$newdir" ;;
      cat\ *) f="${cmd#cat }"; [ -f "$dir/$f" ] && less "$dir/$f" 2>/dev/null ;;
      q|quit|x) return ;;
      "") ;;
      *) [ -d "$dir/$cmd" ] && dir="$dir/$cmd" || \
         { [ -f "$dir/$cmd" ] && less "$dir/$cmd" 2>/dev/null; } ;;
    esac
  done
}

find_files() {
  echo -ne "  ${BOLD}Search path (default $HOME) → ${NC}"; read -r path; path=${path:-$HOME}
  echo -ne "  ${BOLD}Name pattern (e.g. *.apk, config*) → ${NC}"; read -r pattern
  echo -ne "  ${BOLD}Max depth (default 5) → ${NC}"; read -r depth; depth=${depth:-5}
  echo ""
  find "$path" -maxdepth "$depth" -name "$pattern" 2>/dev/null | while read f; do
    echo -e "  ${GREEN}$(ls -lh "$f" 2>/dev/null | awk '{print $5, $6, $7}')${NC}  $f"
  done | less 2>/dev/null || find "$path" -maxdepth "$depth" -name "$pattern" 2>/dev/null
  echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

grep_content() {
  echo -ne "  ${BOLD}Search pattern → ${NC}"; read -r pattern
  echo -ne "  ${BOLD}Search path (default $HOME) → ${NC}"; read -r path; path=${path:-$HOME}
  echo -ne "  ${BOLD}File type filter (e.g. *.txt, leave blank for all) → ${NC}"; read -r ext
  echo ""
  if [ -n "$ext" ]; then
    grep -r --include="$ext" -l "$pattern" "$path" 2>/dev/null | while read f; do
      echo -e "  ${GREEN}$f${NC}"
      grep -n "$pattern" "$f" 2>/dev/null | head -3 | sed 's/^/    /'
    done | less 2>/dev/null
  else
    grep -r -l "$pattern" "$path" 2>/dev/null | head -20
  fi
  echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

file_type_info() {
  echo -ne "  ${BOLD}File or directory → ${NC}"; read -r f
  [ -z "$f" ] && return
  if [ -d "$f" ]; then
    find "$f" -maxdepth 1 -type f | while read file; do
      info "$(file "$file" 2>/dev/null)"
    done
  else
    file "$f" 2>/dev/null
    echo ""
    # Extra info
    [ -f "$f" ] && {
      echo -e "  ${GREEN}Size:${NC}     $(ls -lh "$f" | awk '{print $5}')"
      echo -e "  ${GREEN}Modified:${NC} $(ls -lh "$f" | awk '{print $6, $7}')"
      echo -e "  ${GREEN}MD5:${NC}      $(md5sum "$f" 2>/dev/null | awk '{print $1}')"
    }
  fi
  echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

disk_usage() {
  header
  echo -e "  ${WHITE}${BOLD}DISK USAGE${NC}"
  echo ""
  echo -e "  ${CYAN}── Mount points ─────────────────────────────────────────${NC}"
  df -h 2>/dev/null | grep -v tmpfs | awk 'NR==1{print "  "$0} NR>1{print "  "$0}'
  echo ""
  echo -e "  ${CYAN}── Largest files in home ────────────────────────────────${NC}"
  find "$HOME" -type f -size +1M 2>/dev/null | \
    xargs ls -lh 2>/dev/null | sort -k5 -rh | head -15 | \
    awk '{printf "  \033[32m%-10s\033[0m  %s\n", $5, $NF}'
  echo ""
  echo -e "  ${CYAN}── Largest directories ──────────────────────────────────${NC}"
  du -sh "$HOME"/*/ 2>/dev/null | sort -rh | head -10 | \
    awk '{printf "  \033[33m%-10s\033[0m  %s\n", $1, $2}'
  echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

archive_tools() {
  header
  echo -e "  ${WHITE}${BOLD}ARCHIVE TOOLS${NC}"
  echo ""
  echo -e "  ${CYAN}[1]${NC}  Create zip"
  echo -e "  ${CYAN}[2]${NC}  Extract zip"
  echo -e "  ${CYAN}[3]${NC}  Create tar.gz"
  echo -e "  ${CYAN}[4]${NC}  Extract tar.gz"
  echo -e "  ${CYAN}[5]${NC}  List archive contents"
  echo -e "  ${CYAN}[6]${NC}  Extract 7z"
  echo ""
  echo -ne "  ${BOLD}Choice → ${NC}"; read -r c
  case "$c" in
    1) echo -ne "  Output zip file: "; read -r out
       echo -ne "  Files/dir to zip: "; read -r src
       zip -r "$out" $src 2>/dev/null; success "Created $out" ;;
    2) echo -ne "  Zip file: "; read -r f
       echo -ne "  Extract to (default .): "; read -r dest; dest=${dest:-.}
       unzip "$f" -d "$dest" 2>/dev/null ;;
    3) echo -ne "  Output tar.gz: "; read -r out
       echo -ne "  Source dir/files: "; read -r src
       tar czf "$out" $src 2>/dev/null; success "Created $out" ;;
    4) echo -ne "  tar.gz file: "; read -r f
       echo -ne "  Extract to (default .): "; read -r dest; dest=${dest:-.}
       tar xzf "$f" -C "$dest" 2>/dev/null ;;
    5) echo -ne "  Archive file: "; read -r f
       case "$f" in
         *.zip) unzip -l "$f" ;;
         *.tar*) tar tvf "$f" ;;
         *.7z) 7z l "$f" 2>/dev/null ;;
         *) warn "Unknown archive format" ;;
       esac ;;
    6) echo -ne "  7z file: "; read -r f
       echo -ne "  Extract to (default .): "; read -r dest; dest=${dest:-.}
       7z x "$f" -o"$dest" 2>/dev/null ;;
  esac
  echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

diff_files() {
  echo -ne "  ${BOLD}File 1 → ${NC}"; read -r f1
  echo -ne "  ${BOLD}File 2 → ${NC}"; read -r f2
  [ -z "$f1" ] || [ -z "$f2" ] && return
  diff --color=always "$f1" "$f2" 2>/dev/null | less 2>/dev/null || diff "$f1" "$f2"
  echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

watch_file() {
  echo -ne "  ${BOLD}File to watch → ${NC}"; read -r f
  [ -z "$f" ] && return
  info "Watching $f — Ctrl+C to stop"
  tail -f "$f" 2>/dev/null
}

permissions_menu() {
  echo -ne "  ${BOLD}File/directory → ${NC}"; read -r f
  [ -z "$f" ] && return
  echo -e "\n  Current: $(ls -la "$f" 2>/dev/null | head -2)"
  echo -e "\n  ${CYAN}[1]${NC} chmod  ${CYAN}[2]${NC} chmod -R (recursive)  ${CYAN}[3]${NC} chown"
  echo -ne "  ${BOLD}Choice → ${NC}"; read -r c
  case "$c" in
    1) echo -ne "  Mode (e.g. 755, +x): "; read -r mode; chmod "$mode" "$f" 2>/dev/null ;;
    2) echo -ne "  Mode: "; read -r mode; chmod -R "$mode" "$f" 2>/dev/null ;;
    3) echo -ne "  owner:group: "; read -r own; chown "$own" "$f" 2>/dev/null ;;
  esac
  echo "  New: $(ls -la "$f" 2>/dev/null | head -2)"
  echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

rsync_menu() {
  echo -ne "  ${BOLD}Source → ${NC}"; read -r src
  echo -ne "  ${BOLD}Destination → ${NC}"; read -r dest
  [ -z "$src" ] || [ -z "$dest" ] && return
  step "rsync -avh $src $dest"
  rsync -avh --progress "$src" "$dest" 2>/dev/null
  echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

checksum_menu() {
  echo -ne "  ${BOLD}File → ${NC}"; read -r f
  [ -z "$f" ] || [ ! -f "$f" ] && { warn "File not found"; return; }
  echo ""
  echo -e "  ${GREEN}MD5:    ${NC}$(md5sum "$f" 2>/dev/null)"
  echo -e "  ${GREEN}SHA1:   ${NC}$(sha1sum "$f" 2>/dev/null)"
  echo -e "  ${GREEN}SHA256: ${NC}$(sha256sum "$f" 2>/dev/null)"
  echo -e "  ${GREEN}SHA512: ${NC}$(sha512sum "$f" 2>/dev/null)"
  echo ""
  echo -ne "  Verify against known hash? [y/N]: "; read -r v
  if [ "$v" = "y" ]; then
    echo -ne "  Known hash: "; read -r known
    actual=$(sha256sum "$f" 2>/dev/null | awk '{print $1}')
    [ "$actual" = "$known" ] && success "Hashes match!" || error "Hashes DO NOT match!"
  fi
  echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

binary_viewer() {
  echo -ne "  ${BOLD}File → ${NC}"; read -r f
  [ -z "$f" ] || [ ! -f "$f" ] && { warn "File not found"; return; }
  echo -ne "  ${BOLD}Bytes to view (default 256) → ${NC}"; read -r n; n=${n:-256}
  echo ""
  xxd "$f" 2>/dev/null | head -$((n/16)) || \
  hexdump -C "$f" | head -$((n/16))
  echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

files_menu
