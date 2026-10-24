#!/data/data/com.termux/files/usr/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/colors.sh" 2>/dev/null

FRIDA_SERVER_DIR="$HOME/.devtools/frida-server"
FRIDA_SERVER_BIN="$FRIDA_SERVER_DIR/frida-server"

frida_main() {
  # Allow calling with arg "start" to just start the server
  [ "$1" = "start" ] && { start_frida_server; return; }

  while true; do
    header
    echo -e "  ${WHITE}${BOLD}FRIDA TOOLS${NC}"
    echo ""

    FRIDA_VER=$(frida --version 2>/dev/null || echo "not installed")
    echo -e "  ${GREEN}frida-tools:${NC} $FRIDA_VER"
    if [ -f "$FRIDA_SERVER_BIN" ]; then
      echo -e "  ${GREEN}frida-server:${NC} available ($FRIDA_SERVER_DIR)"
    else
      echo -e "  ${YELLOW}frida-server:${NC} not downloaded"
    fi
    echo ""

    echo -e "  ${CYAN}── Setup ──────────────────────────────────────────────${NC}"
    echo -e "  ${CYAN}[1]${NC}  Install / update frida-tools (pip)"
    echo -e "  ${CYAN}[2]${NC}  Download matching frida-server"
    echo -e "  ${CYAN}[3]${NC}  Start frida-server (needs root/ADB)"
    echo -e "  ${CYAN}[4]${NC}  Stop frida-server"
    echo ""
    echo -e "  ${CYAN}── Process Listing ────────────────────────────────────${NC}"
    echo -e "  ${CYAN}[5]${NC}  List processes (USB device)"
    echo -e "  ${CYAN}[6]${NC}  List processes (local)"
    echo ""
    echo -e "  ${CYAN}── Instrumentation ────────────────────────────────────${NC}"
    echo -e "  ${CYAN}[7]${NC}  Attach + inject script"
    echo -e "  ${CYAN}[8]${NC}  Spawn app + inject script"
    echo -e "  ${CYAN}[9]${NC}  SSL pinning bypass script"
    echo -e "  ${CYAN}[a]${NC}  Root detection bypass script"
    echo -e "  ${CYAN}[b]${NC}  Enumerate Java classes & methods"
    echo -e "  ${CYAN}[c]${NC}  Hook Java method (interactive)"
    echo -e "  ${CYAN}[d]${NC}  Frida REPL"
    echo ""
    echo -e "  ${CYAN}── APK Patching (no root) ─────────────────────────────${NC}"
    echo -e "  ${CYAN}[e]${NC}  Patch APK with Frida gadget (objection)"
    echo ""
    echo -e "  ${RED}[x]${NC}  Back"
    echo ""
    echo -ne "  ${BOLD}Choice → ${NC}"
    read -r choice

    case "$choice" in
      1) pip install --upgrade frida-tools 2>/dev/null; success "frida-tools updated" ;;
      2) download_frida_server ;;
      3) start_frida_server ;;
      4) stop_frida_server ;;
      5) frida-ps -U 2>/dev/null ;;
      6) frida-ps 2>/dev/null ;;
      7) inject_script ;;
      8) spawn_inject ;;
      9) ssl_pinning_bypass ;;
      a|A) root_detection_bypass ;;
      b|B) enumerate_classes ;;
      c|C) hook_method ;;
      d|D) frida_repl ;;
      e|E) patch_apk_gadget ;;
      x|X) return ;;
      *) warn "Invalid"; sleep 1 ;;
    esac

    [ "$choice" != "x" ] && [ "$choice" != "X" ] && {
      echo ""; echo -ne "  ${DIM}Press Enter...${NC}"; read -r
    }
  done
}

download_frida_server() {
  if ! command -v frida &>/dev/null; then
    warn "frida-tools not installed. Run option [1] first."
    return
  fi
  FRIDA_VER=$(frida --version 2>/dev/null)
  info "Downloading frida-server v$FRIDA_VER for android-arm64..."
  mkdir -p "$FRIDA_SERVER_DIR"
  URL="https://github.com/frida/frida/releases/download/${FRIDA_VER}/frida-server-${FRIDA_VER}-android-arm64.xz"
  curl -L "$URL" -o "$FRIDA_SERVER_DIR/frida-server.xz" --progress-bar 2>/dev/null
  if [ -f "$FRIDA_SERVER_DIR/frida-server.xz" ]; then
    xz -df "$FRIDA_SERVER_DIR/frida-server.xz" 2>/dev/null
    mv "$FRIDA_SERVER_DIR/frida-server-${FRIDA_VER}-android-arm64" \
       "$FRIDA_SERVER_BIN" 2>/dev/null || true
    chmod +x "$FRIDA_SERVER_BIN" 2>/dev/null
    success "frida-server downloaded: $FRIDA_SERVER_BIN"
  else
    error "Download failed"
  fi
}

start_frida_server() {
  if [ ! -f "$FRIDA_SERVER_BIN" ]; then
    warn "frida-server not downloaded. Use option [2] first."
    return
  fi
  info "Pushing frida-server to device via ADB..."
  adb push "$FRIDA_SERVER_BIN" /data/local/tmp/frida-server 2>/dev/null
  adb shell chmod +x /data/local/tmp/frida-server 2>/dev/null
  info "Starting frida-server as root..."
  adb shell "su -c 'killall frida-server 2>/dev/null; /data/local/tmp/frida-server &'" 2>/dev/null || \
  adb shell "nohup /data/local/tmp/frida-server &>/dev/null &" 2>/dev/null
  sleep 2
  frida-ps -U 2>/dev/null | head -5 && success "frida-server running!" || \
  warn "Could not verify — may need root"
}

stop_frida_server() {
  adb shell "su -c 'killall frida-server'" 2>/dev/null || \
  adb shell "killall frida-server" 2>/dev/null
  success "frida-server stopped"
}

inject_script() {
  echo -ne "  ${BOLD}Script .js file → ${NC}"; read -r script
  [ ! -f "$script" ] && { warn "Script not found"; return; }
  echo -ne "  ${BOLD}Process name (USB) → ${NC}"; read -r proc
  frida -U -l "$script" "$proc" 2>/dev/null
}

spawn_inject() {
  echo -ne "  ${BOLD}Script .js file → ${NC}"; read -r script
  [ ! -f "$script" ] && { warn "Script not found"; return; }
  echo -ne "  ${BOLD}Package name (USB) → ${NC}"; read -r pkg
  frida -U -f "$pkg" -l "$script" --no-pause 2>/dev/null
}

ssl_pinning_bypass() {
  SSL_SCRIPT="$HOME/.devtools/scripts/ssl_bypass.js"
  cat > "$SSL_SCRIPT" << 'JSEOF'
// SSL Pinning Bypass — covers TrustManager, OkHttp, Conscrypt, Xamarin
Java.perform(function() {
    // Generic TrustManager bypass
    try {
        var TrustManager = Java.registerClass({
            name: 'com.devtools.TrustManager',
            implements: [Java.use('javax.net.ssl.X509TrustManager')],
            methods: {
                checkClientTrusted: function(chain, authType) {},
                checkServerTrusted: function(chain, authType) {},
                getAcceptedIssuers: function() { return []; }
            }
        });
        var SSLContext = Java.use('javax.net.ssl.SSLContext');
        var TrustManagerArr = Java.array('javax.net.ssl.TrustManager', [TrustManager.$new()]);
        var sc = SSLContext.getInstance('TLS');
        sc.init(null, TrustManagerArr, null);
        SSLContext.getDefault.implementation = function() { return sc; };
        console.log('[+] TrustManager bypassed');
    } catch(e) { console.log('[-] TrustManager: ' + e); }

    // OkHttp3 CertificatePinner bypass
    try {
        var CertificatePinner = Java.use('okhttp3.CertificatePinner');
        CertificatePinner.check.overload('java.lang.String', 'java.util.List').implementation = function(h, c) {
            console.log('[+] OkHttp3 CertificatePinner bypassed for: ' + h);
        };
        CertificatePinner.check.overload('java.lang.String', '[Ljava.security.cert.Certificate;').implementation = function(h, c) {
            console.log('[+] OkHttp3 check2 bypassed for: ' + h);
        };
    } catch(e) { console.log('[-] OkHttp3: ' + e); }

    // Conscrypt bypass
    try {
        var Conscrypt = Java.use('com.android.org.conscrypt.TrustManagerImpl');
        Conscrypt.verifyChain.implementation = function(u,c,a,b,h,s) {
            console.log('[+] Conscrypt bypassed');
            return u;
        };
    } catch(e) { console.log('[-] Conscrypt: ' + e); }

    console.log('[*] SSL Pinning bypass complete');
});
JSEOF
  echo -ne "  ${BOLD}Package name → ${NC}"; read -r pkg
  [ -z "$pkg" ] && return
  info "Injecting SSL pinning bypass into $pkg..."
  frida -U -f "$pkg" -l "$SSL_SCRIPT" --no-pause 2>/dev/null || \
  frida -U -l "$SSL_SCRIPT" "$pkg" 2>/dev/null
}

root_detection_bypass() {
  ROOT_SCRIPT="$HOME/.devtools/scripts/root_bypass.js"
  cat > "$ROOT_SCRIPT" << 'JSEOF'
Java.perform(function() {
    // Hide common root indicators
    var strings_to_hide = ['su', 'supersu', 'magisk', 'busybox', 'rootcloak'];

    // File.exists() bypass for root files
    try {
        var File = Java.use('java.io.File');
        File.exists.implementation = function() {
            var name = this.getAbsolutePath();
            var rootPaths = ['/su', '/sbin/su', '/system/bin/su', '/system/xbin/su',
                           '/data/local/xbin/su', '/data/local/bin/su',
                           '/system/xbin/busybox', '/magisk'];
            for (var i = 0; i < rootPaths.length; i++) {
                if (name.indexOf(rootPaths[i]) !== -1) {
                    console.log('[+] Root file check hidden: ' + name);
                    return false;
                }
            }
            return this.exists();
        };
        console.log('[+] File.exists bypass active');
    } catch(e) { console.log('[-] File bypass: ' + e); }

    // Runtime.exec() bypass for 'which su'
    try {
        var Runtime = Java.use('java.lang.Runtime');
        Runtime.exec.overload('java.lang.String').implementation = function(cmd) {
            if (cmd.indexOf('su') !== -1 || cmd.indexOf('which') !== -1) {
                console.log('[+] Runtime.exec blocked: ' + cmd);
                throw Java.use('java.io.IOException').$new('Permission denied');
            }
            return this.exec(cmd);
        };
    } catch(e) { console.log('[-] Runtime.exec: ' + e); }

    console.log('[*] Root detection bypass complete');
});
JSEOF
  echo -ne "  ${BOLD}Package name → ${NC}"; read -r pkg
  [ -z "$pkg" ] && return
  frida -U -f "$pkg" -l "$ROOT_SCRIPT" --no-pause 2>/dev/null || \
  frida -U -l "$ROOT_SCRIPT" "$pkg" 2>/dev/null
}

enumerate_classes() {
  ENUM_SCRIPT="$HOME/.devtools/scripts/enum_classes.js"
  cat > "$ENUM_SCRIPT" << 'JSEOF'
Java.perform(function() {
    Java.enumerateLoadedClasses({
        onMatch: function(cls) {
            if (!cls.startsWith('android') && !cls.startsWith('java') &&
                !cls.startsWith('sun') && !cls.startsWith('com.android') &&
                !cls.startsWith('dalvik') && !cls.startsWith('libcore')) {
                console.log(cls);
            }
        },
        onComplete: function() { console.log('[*] Enumeration complete'); }
    });
});
JSEOF
  echo -ne "  ${BOLD}Package name → ${NC}"; read -r pkg
  [ -z "$pkg" ] && return
  frida -U "$pkg" -l "$ENUM_SCRIPT" --no-pause 2>/dev/null | grep -v "^\[" | head -100
}

hook_method() {
  echo -ne "  ${BOLD}Class name (e.g. com.example.Auth) → ${NC}"; read -r classname
  echo -ne "  ${BOLD}Method name → ${NC}"; read -r method
  HOOK_SCRIPT="$HOME/.devtools/scripts/hook_${method}.js"
  cat > "$HOOK_SCRIPT" << JSEOF
Java.perform(function() {
    try {
        var cls = Java.use('${classname}');
        cls.${method}.implementation = function() {
            console.log('[*] ${classname}.${method} called');
            console.log('    args: ' + JSON.stringify(arguments));
            var ret = this.${method}.apply(this, arguments);
            console.log('    return: ' + ret);
            return ret;
        };
        console.log('[+] Hooked ${classname}.${method}');
    } catch(e) {
        console.log('[-] Hook failed: ' + e);
    }
});
JSEOF
  echo -ne "  ${BOLD}Package name → ${NC}"; read -r pkg
  [ -z "$pkg" ] && return
  frida -U "$pkg" -l "$HOOK_SCRIPT" --no-pause 2>/dev/null
}

frida_repl() {
  echo -ne "  ${BOLD}Process name or PID → ${NC}"; read -r proc
  [ -z "$proc" ] && return
  frida -U "$proc" 2>/dev/null
}

patch_apk_gadget() {
  if ! command -v objection &>/dev/null; then
    warn "objection not installed: pip install objection"
    return
  fi
  echo -ne "  ${BOLD}APK file → ${NC}"; read -r apk
  [ ! -f "$apk" ] && { warn "File not found"; return; }
  step "Patching $apk with Frida gadget..."
  objection patchapk -s "$apk" 2>/dev/null
  PATCHED="${apk%.apk}.objection.apk"
  [ -f "$PATCHED" ] && success "Patched APK: $PATCHED" || \
  info "Check output above for patched APK location"
}

frida_main "$@"
