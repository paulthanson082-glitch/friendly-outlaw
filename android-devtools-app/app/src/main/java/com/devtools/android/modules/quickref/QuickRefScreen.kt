package com.devtools.android.modules.quickref

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.text.selection.SelectionContainer
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ExpandLess
import androidx.compose.material.icons.filled.ExpandMore
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.unit.dp

// ── Static content ─────────────────────────────────────────────────────────

private data class QuickRefSection(val title: String, val content: String)

private val SECTIONS = listOf(
    QuickRefSection(
        title = "ADB Commands",
        content = """
# Device
adb devices -l
adb connect <host>:<port>
adb disconnect
adb shell
adb root
adb remount

# App management
adb install -r <apk>
adb uninstall <pkg>
adb shell pm list packages -3
adb shell pm list packages -f
adb shell am start -n <pkg>/<activity>
adb shell am force-stop <pkg>
adb shell am startservice <pkg>/<service>

# File transfer
adb push <local> <remote>
adb pull <remote> <local>

# Debugging
adb logcat -c
adb logcat *:E
adb logcat -s <TAG>
adb bugreport > bugreport.zip
adb shell dumpsys activity
adb shell dumpsys battery
adb shell dumpsys meminfo <pkg>

# Screen
adb shell screencap /sdcard/screen.png
adb shell screenrecord /sdcard/record.mp4
        """.trimIndent()
    ),
    QuickRefSection(
        title = "Frida / Objection",
        content = """
# Frida — list processes
frida-ps -U
frida-ps -Uai          # all installed apps

# Attach to running process
frida -U -p <pid>
frida -U -n <process>
frida -U -f <pkg> --no-pause

# Frida-trace
frida-trace -U -f <pkg> -i "open"
frida-trace -U -f <pkg> -m "-[NSString *]"

# Codeshare scripts
frida -U -l script.js <pkg>
frida -U --codeshare mrmacete/objc-method-observer <pkg>

# Objection — explore
objection -g <pkg> explore
objection -g <pkg> run android hooking list classes

# Common Objection REPL commands
android hooking list classes
android hooking search classes <keyword>
android hooking search methods <class>
android hooking watch method <class>.<method> --dump-args --dump-return
android sslpinning disable
android root disable
android ui screenshot /sdcard/shot.png
memory list modules
memory dump all /tmp/memdump
        """.trimIndent()
    ),
    QuickRefSection(
        title = "nmap Flags",
        content = """
# Basic
nmap <target>
nmap -sS <target>        # TCP SYN (root)
nmap -sT <target>        # TCP connect (no root)
nmap -sU <target>        # UDP
nmap -sn <cidr>          # Ping sweep (no ports)

# Service / OS detection
nmap -sV <target>        # Service/version
nmap -O  <target>        # OS detection (root)
nmap -A  <target>        # Aggressive (-sV -O --script default)

# Port selection
nmap -p 22,80,443 <target>
nmap -p 1-1024 <target>
nmap -p- <target>        # All 65535 ports
nmap --top-ports 100 <target>

# Speed / timing
nmap -T0 ... -T5 <target>    # T4 = fast, T5 = insane

# Output
nmap -oN scan.txt <target>
nmap -oX scan.xml <target>
nmap -oG scan.grep <target>

# NSE Scripts
nmap --script vuln <target>
nmap --script http-enum <target>
nmap --script ssl-cert <target>
nmap --script smb-os-discovery <target>
        """.trimIndent()
    ),
    QuickRefSection(
        title = "Logcat Filters",
        content = """
# Priority levels (V D I W E F S)
adb logcat *:V           # Verbose and above
adb logcat *:D           # Debug and above
adb logcat *:I           # Info and above
adb logcat *:W           # Warn and above
adb logcat *:E           # Error only
adb logcat *:F           # Fatal only
adb logcat *:S           # Silence all

# Tag filter
adb logcat -s MyTag
adb logcat ActivityManager:I MyApp:D *:S

# Format modifiers
adb logcat -v brief       # Default
adb logcat -v time
adb logcat -v threadtime
adb logcat -v long
adb logcat -v json        # API 24+

# Grep / regex
adb logcat | grep -i "exception"
adb logcat | grep -E "ANR|crash"
adb logcat -e "NullPointer"

# Buffer selection
adb logcat -b main
adb logcat -b system
adb logcat -b crash
adb logcat -b all

# Clear / dump
adb logcat -c             # Clear buffer
adb logcat -d > log.txt   # Dump and exit
        """.trimIndent()
    ),
    QuickRefSection(
        title = "Crypto / Hashing",
        content = """
# File hashes
md5sum <file>
sha1sum <file>
sha256sum <file>
sha512sum <file>

openssl dgst -md5    <file>
openssl dgst -sha256 <file>

# Inline string
echo -n "text" | md5sum
echo -n "text" | sha256sum

# Base64
echo -n "text" | base64
echo -n "dGV4dA==" | base64 -d

# OpenSSL TLS inspection
openssl s_client -connect <host>:443
openssl s_client -connect <host>:443 -showcerts
openssl x509 -in cert.pem -text -noout
openssl x509 -in cert.pem -fingerprint -sha256

# Key generation
openssl genrsa -out key.pem 2048
openssl req -new -x509 -key key.pem -out cert.pem -days 365

# Android encryption props
adb shell getprop ro.crypto.state
adb shell getprop ro.crypto.type
adb shell getprop ro.crypto.fs_crypto_blkdev
        """.trimIndent()
    )
)

// ── Composables ────────────────────────────────────────────────────────────

@Composable
fun QuickRefScreen() {
    var query by rememberSaveable { mutableStateOf("") }

    val filtered = remember(query) {
        if (query.isBlank()) {
            SECTIONS
        } else {
            val q = query.trim().lowercase()
            SECTIONS.filter { s ->
                s.title.lowercase().contains(q) || s.content.lowercase().contains(q)
            }
        }
    }

    Column(modifier = Modifier.fillMaxSize()) {
        // Search bar
        OutlinedTextField(
            value = query,
            onValueChange = { query = it },
            label = { Text("Search") },
            leadingIcon = { Icon(Icons.Default.Search, contentDescription = "Search") },
            singleLine = true,
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 8.dp)
        )

        if (filtered.isEmpty()) {
            Text(
                text = "No results for \"$query\"",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(16.dp)
            )
        }

        LazyColumn(modifier = Modifier.fillMaxSize()) {
            items(filtered) { section ->
                QuickRefSectionCard(section = section)
                Spacer(modifier = Modifier.height(4.dp))
            }
            item { Spacer(modifier = Modifier.height(16.dp)) }
        }
    }
}

@Composable
private fun QuickRefSectionCard(section: QuickRefSection) {
    var expanded by remember { mutableStateOf(false) }

    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 4.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column {
            // Header row — click to expand/collapse
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 12.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = section.title,
                    style = MaterialTheme.typography.titleMedium,
                    modifier = Modifier.weight(1f)
                )
                IconButton(onClick = { expanded = !expanded }) {
                    Icon(
                        imageVector = if (expanded) Icons.Default.ExpandLess else Icons.Default.ExpandMore,
                        contentDescription = if (expanded) "Collapse" else "Expand"
                    )
                }
            }

            AnimatedVisibility(visible = expanded) {
                Column {
                    HorizontalDivider()
                    Surface(
                        color = MaterialTheme.colorScheme.surfaceVariant,
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        SelectionContainer {
                            Text(
                                text = section.content,
                                fontFamily = FontFamily.Monospace,
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                                modifier = Modifier.padding(12.dp)
                            )
                        }
                    }
                }
            }
        }
    }
}
