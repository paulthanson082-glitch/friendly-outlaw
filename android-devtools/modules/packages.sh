#!/data/data/com.termux/files/usr/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/colors.sh" 2>/dev/null

packages_menu() {
  while true; do
    header
    echo -e "  ${WHITE}${BOLD}APK & PACKAGE TOOLS${NC}"
    echo ""
    echo -e "  ${CYAN}[1]${NC}  apktool — Decompile APK to smali"
    echo -e "  ${CYAN}[2]${NC}  apktool — Recompile smali to APK"
    echo -e "  ${CYAN}[3]${NC}  jadx — Decompile APK to Java source"
    echo -e "  ${CYAN}[4]${NC}  androguard — Static APK analysis (Python)"
    echo -e "  ${CYAN}[5]${NC}  APK info — permissions, activities, services"
    echo -e "  ${CYAN}[6]${NC}  Extract APK from installed app"
    echo -e "  ${CYAN}[7]${NC}  Sign APK (debug keystore)"
    echo -e "  ${CYAN}[8]${NC}  Verify APK signature"
    echo -e "  ${CYAN}[9]${NC}  Unzip APK and inspect contents"
    echo ""
    echo -e "  ${RED}[x]${NC}  Back"
    echo ""
    echo -ne "  ${BOLD}Choice → ${NC}"
    read -r choice

    case "$choice" in
      1) apktool_decompile ;;
      2) apktool_recompile ;;
      3) jadx_decompile ;;
      4) androguard_menu ;;
      5) apk_info ;;
      6) extract_installed_apk ;;
      7) sign_apk ;;
      8) verify_apk ;;
      9) inspect_apk ;;
      x|X) return ;;
      *) warn "Invalid"; sleep 1 ;;
    esac
  done
}

apktool_decompile() {
  if ! command -v apktool &>/dev/null; then
    warn "apktool not installed. Run install.sh first."
    echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r; return
  fi
  echo -ne "  ${BOLD}APK file path → ${NC}"; read -r apk
  [ -z "$apk" ] || [ ! -f "$apk" ] && { warn "File not found"; return; }
  OUT="${apk%.apk}_decompiled"
  step "Decompiling $apk → $OUT ..."
  apktool d "$apk" -o "$OUT" -f 2>/dev/null
  success "Output: $OUT"
  echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

apktool_recompile() {
  if ! command -v apktool &>/dev/null; then
    warn "apktool not installed."; echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r; return
  fi
  echo -ne "  ${BOLD}Decompiled directory → ${NC}"; read -r dir
  [ -z "$dir" ] || [ ! -d "$dir" ] && { warn "Directory not found"; return; }
  step "Recompiling $dir ..."
  apktool b "$dir" 2>/dev/null
  success "Output APK in ${dir}/dist/"
  echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

jadx_decompile() {
  if ! command -v jadx &>/dev/null; then
    warn "jadx not installed. Run install.sh first."
    echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r; return
  fi
  echo -ne "  ${BOLD}APK/DEX/JAR file → ${NC}"; read -r apk
  [ -z "$apk" ] || [ ! -f "$apk" ] && { warn "File not found"; return; }
  OUT="${apk%.apk}_jadx"
  step "Decompiling to Java source → $OUT ..."
  jadx "$apk" -d "$OUT" 2>/dev/null
  success "Java source output: $OUT"
  ls "$OUT/sources/" 2>/dev/null | head -20
  echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

androguard_menu() {
  if ! python3 -c "import androguard" 2>/dev/null; then
    warn "androguard not installed. Run: pip install androguard"
    echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r; return
  fi
  echo -ne "  ${BOLD}APK file → ${NC}"; read -r apk
  [ -z "$apk" ] || [ ! -f "$apk" ] && { warn "File not found"; return; }
  echo ""
  python3 - "$apk" <<'PYEOF'
import sys
from androguard.misc import AnalyzeAPK
apk_path = sys.argv[1]
print(f"[*] Analyzing {apk_path}...")
try:
    a, d, dx = AnalyzeAPK(apk_path)
    print(f"\n[Package] {a.get_package()}")
    print(f"[Version] {a.get_androidversion_name()} ({a.get_androidversion_code()})")
    print(f"[Min SDK] {a.get_min_sdk_version()}")
    print(f"[Target SDK] {a.get_target_sdk_version()}")
    print(f"\n[Permissions] ({len(a.get_permissions())} total)")
    for p in sorted(a.get_permissions()):
        print(f"  {p}")
    print(f"\n[Activities] ({len(a.get_activities())} total)")
    for act in a.get_activities()[:20]:
        print(f"  {act}")
    print(f"\n[Services] ({len(a.get_services())} total)")
    for svc in a.get_services():
        print(f"  {svc}")
    print(f"\n[Receivers]")
    for r in a.get_receivers():
        print(f"  {r}")
    print(f"\n[Libraries]")
    for lib in a.get_libraries():
        print(f"  {lib}")
except Exception as e:
    print(f"[!] Error: {e}")
PYEOF
  echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

apk_info() {
  echo -ne "  ${BOLD}APK file → ${NC}"; read -r apk
  [ -z "$apk" ] || [ ! -f "$apk" ] && { warn "File not found"; return; }
  echo ""
  echo -e "  ${CYAN}── aapt / aapt2 info ────────────────────────────────────${NC}"
  aapt2 dump badging "$apk" 2>/dev/null | head -30 || \
  aapt dump badging "$apk" 2>/dev/null | head -30 || {
    info "aapt not available — using unzip to extract manifest..."
    unzip -p "$apk" AndroidManifest.xml 2>/dev/null | strings | head -40
  }
  echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

extract_installed_apk() {
  echo -ne "  ${BOLD}Package name → ${NC}"; read -r pkg
  [ -z "$pkg" ] && return
  APK_PATH=$(adb shell pm path "$pkg" 2>/dev/null | sed 's/package://')
  if [ -z "$APK_PATH" ]; then
    APK_PATH=$(pm path "$pkg" 2>/dev/null | sed 's/package://')
  fi
  if [ -z "$APK_PATH" ]; then
    warn "Package not found: $pkg"; return
  fi
  step "APK path: $APK_PATH"
  OUTFILE="${pkg}.apk"
  adb pull "$APK_PATH" "$OUTFILE" 2>/dev/null || \
  cp "$APK_PATH" "$OUTFILE" 2>/dev/null
  success "Saved to: $OUTFILE"
  echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

sign_apk() {
  echo -ne "  ${BOLD}APK file to sign → ${NC}"; read -r apk
  [ -z "$apk" ] || [ ! -f "$apk" ] && { warn "File not found"; return; }
  KEYSTORE="$HOME/.devtools/debug.keystore"
  if [ ! -f "$KEYSTORE" ]; then
    step "Generating debug keystore..."
    keytool -genkey -v -keystore "$KEYSTORE" -storepass android \
      -alias androiddebugkey -keypass android -keyalg RSA -keysize 2048 \
      -validity 10000 -dname "CN=Android Debug,O=Android,C=US" 2>/dev/null
    success "Keystore created: $KEYSTORE"
  fi
  SIGNED="${apk%.apk}_signed.apk"
  step "Signing $apk..."
  jarsigner -verbose -sigalg SHA256withRSA -digestalg SHA-256 \
    -keystore "$KEYSTORE" -storepass android \
    -signedjar "$SIGNED" "$apk" androiddebugkey 2>/dev/null
  success "Signed APK: $SIGNED"
  echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

verify_apk() {
  echo -ne "  ${BOLD}APK file → ${NC}"; read -r apk
  [ -z "$apk" ] || [ ! -f "$apk" ] && { warn "File not found"; return; }
  echo ""
  jarsigner -verify -verbose -certs "$apk" 2>/dev/null | head -30 || \
  openssl pkcs7 -print_certs -inform DER 2>/dev/null || \
  warn "jarsigner not available"
  echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

inspect_apk() {
  echo -ne "  ${BOLD}APK file → ${NC}"; read -r apk
  [ -z "$apk" ] || [ ! -f "$apk" ] && { warn "File not found"; return; }
  OUT="$HOME/.devtools/apk_inspect_$(basename "$apk" .apk)"
  mkdir -p "$OUT"
  step "Unzipping $apk → $OUT ..."
  unzip -q "$apk" -d "$OUT" 2>/dev/null
  echo ""
  echo -e "  ${CYAN}── Contents ─────────────────────────────────────────────${NC}"
  find "$OUT" -type f | sed "s|$OUT/|  |" | sort
  echo ""
  echo -e "  ${CYAN}── Interesting files ────────────────────────────────────${NC}"
  find "$OUT" -name "*.xml" -o -name "*.json" -o -name "*.properties" \
    -o -name "*.so" | sed "s|$OUT/|  |" | head -20
  echo ""
  echo -e "  ${CYAN}── Native Libraries (.so) ───────────────────────────────${NC}"
  find "$OUT" -name "*.so" | while read sofile; do
    echo -e "  ${GREEN}$(basename "$sofile"):${NC} $(file "$sofile" 2>/dev/null | sed 's/.*://')"
  done
  echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r
}

packages_menu
