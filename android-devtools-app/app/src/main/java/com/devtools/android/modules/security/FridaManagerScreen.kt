package com.devtools.android.modules.security

import android.content.Context
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowDropDown
import androidx.compose.material.icons.filled.Circle
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.devtools.android.ui.components.ErrorCard

// ─────────────────────────────────────────────────────────────────────────────
// Built-in Frida script snippets
// ─────────────────────────────────────────────────────────────────────────────

private val SSL_PINNING_BYPASS = """
Java.perform(function() {
    var TrustManager = Java.registerClass({
        name: 'com.devtools.TrustAllManager',
        implements: [Java.use('javax.net.ssl.X509TrustManager')],
        methods: {
            checkClientTrusted: function(chain, authType) {},
            checkServerTrusted: function(chain, authType) {},
            getAcceptedIssuers: function() { return []; }
        }
    });
    var SSLContext = Java.use('javax.net.ssl.SSLContext');
    var ctx = SSLContext.getInstance('TLS');
    ctx.init(null, [TrustManager.${'$'}new()], null);
    SSLContext.setDefault(ctx);
    console.log('[*] SSL pinning bypassed');
});
""".trimIndent()

private val ROOT_DETECTION_BYPASS = """
Java.perform(function() {
    var RootBeer = null;
    try { RootBeer = Java.use('com.scottyab.rootbeer.RootBeer'); } catch(e) {}
    if (RootBeer) {
        RootBeer.isRooted.implementation = function() { return false; };
        RootBeer.isRootedWithBusyBoxCheck.implementation = function() { return false; };
        console.log('[*] RootBeer checks bypassed');
    }
    // Generic file existence spoofing
    var File = Java.use('java.io.File');
    File.exists.implementation = function() {
        var name = this.getAbsolutePath();
        if (name.indexOf('su') !== -1 || name.indexOf('Superuser') !== -1) {
            return false;
        }
        return this.exists.call(this);
    };
    console.log('[*] Root detection bypass applied');
});
""".trimIndent()

private enum class ScriptPreset(val label: String) {
    SSL_PINNING("SSL Pinning Bypass"),
    ROOT_DETECTION("Root Detection Bypass"),
    CUSTOM("Custom")
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

@Composable
fun FridaManagerScreen(vm: FridaManagerViewModel = viewModel()) {
    val context = LocalContext.current
    val state by vm.state.collectAsState()
    val processes by vm.processes.collectAsState()
    val injectLog by vm.injectLog.collectAsState()

    // Script panel state
    var selectedPreset by rememberSaveable { mutableStateOf(ScriptPreset.SSL_PINNING) }
    var customScript by rememberSaveable { mutableStateOf("") }
    var presetMenuExpanded by rememberSaveable { mutableStateOf(false) }
    var attachPid by rememberSaveable { mutableStateOf<Int?>(null) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        // ── Server status card ─────────────────────────────────────────────
        ServerStatusCard(
            state = state,
            onStart = { vm.startServer(context) },
            onStop = { vm.stopServer() },
            onRefresh = { vm.refreshProcesses() }
        )

        // ── Error card ─────────────────────────────────────────────────────
        if (state is FridaState.Error) {
            ErrorCard(
                message = (state as FridaState.Error).msg,
                onRetry = { vm.startServer(context) }
            )
        }

        // ── Process list ───────────────────────────────────────────────────
        Text(
            text = "Attached Processes (${processes.size})",
            style = MaterialTheme.typography.titleSmall
        )
        if (processes.isEmpty()) {
            Text(
                text = if (state is FridaState.Running) "No processes found — tap Refresh."
                else "Start the Frida server to list processes.",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        } else {
            LazyColumn(
                modifier = Modifier
                    .fillMaxWidth()
                    .weight(1f),
                verticalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                items(processes, key = { it.pid }) { proc ->
                    ProcessRow(
                        process = proc,
                        onAttach = { attachPid = proc.pid }
                    )
                }
            }
        }

        HorizontalDivider()

        // ── Script injection panel ─────────────────────────────────────────
        Text(text = "Script Injection", style = MaterialTheme.typography.titleSmall)

        // Target PID indicator
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(
                text = "Target PID: ",
                style = MaterialTheme.typography.bodySmall
            )
            Text(
                text = attachPid?.toString() ?: "— tap Attach on a process",
                style = MaterialTheme.typography.bodySmall,
                color = if (attachPid != null) MaterialTheme.colorScheme.primary
                else MaterialTheme.colorScheme.onSurfaceVariant
            )
            if (attachPid != null) {
                Spacer(Modifier.width(8.dp))
                TextButton(onClick = { attachPid = null }) {
                    Text("Clear", style = MaterialTheme.typography.labelSmall)
                }
            }
        }

        // Script preset selector
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(text = "Script: ", style = MaterialTheme.typography.bodySmall)
            OutlinedButton(onClick = { presetMenuExpanded = true }) {
                Text(selectedPreset.label, style = MaterialTheme.typography.bodySmall)
                Icon(Icons.Default.ArrowDropDown, contentDescription = null, modifier = Modifier.size(16.dp))
            }
            DropdownMenu(
                expanded = presetMenuExpanded,
                onDismissRequest = { presetMenuExpanded = false }
            ) {
                ScriptPreset.entries.forEach { preset ->
                    DropdownMenuItem(
                        text = { Text(preset.label) },
                        onClick = {
                            selectedPreset = preset
                            presetMenuExpanded = false
                        }
                    )
                }
            }
        }

        // Custom script editor (only visible for CUSTOM preset)
        if (selectedPreset == ScriptPreset.CUSTOM) {
            OutlinedTextField(
                value = customScript,
                onValueChange = { customScript = it },
                label = { Text("Frida JS script") },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(120.dp),
                textStyle = MaterialTheme.typography.bodySmall.copy(fontFamily = FontFamily.Monospace),
                maxLines = 8
            )
        }

        // Inject button
        Button(
            onClick = {
                val pid = attachPid ?: return@Button
                val script = when (selectedPreset) {
                    ScriptPreset.SSL_PINNING -> SSL_PINNING_BYPASS
                    ScriptPreset.ROOT_DETECTION -> ROOT_DETECTION_BYPASS
                    ScriptPreset.CUSTOM -> customScript
                }
                vm.injectScript(pid, script, context)
            },
            enabled = attachPid != null && (selectedPreset != ScriptPreset.CUSTOM || customScript.isNotBlank()),
            modifier = Modifier.fillMaxWidth()
        ) {
            Text("Inject Script into PID ${attachPid ?: "?"}")
        }

        // Injection result
        injectLog?.let { log ->
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.surfaceVariant
                )
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(12.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.Top
                ) {
                    Text(
                        text = log,
                        style = MaterialTheme.typography.bodySmall,
                        fontFamily = FontFamily.Monospace,
                        modifier = Modifier.weight(1f)
                    )
                    TextButton(onClick = { vm.clearInjectLog() }) {
                        Text("Dismiss", style = MaterialTheme.typography.labelSmall)
                    }
                }
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-composables
// ─────────────────────────────────────────────────────────────────────────────

@Composable
private fun ServerStatusCard(
    state: FridaState,
    onStart: () -> Unit,
    onStop: () -> Unit,
    onRefresh: () -> Unit
) {
    val statusColor = when (state) {
        FridaState.Idle -> Color.Gray
        FridaState.Starting -> Color(0xFFFFA000)
        is FridaState.Running -> Color(0xFF4CAF50)
        is FridaState.Error -> MaterialTheme.colorScheme.error
    }
    val statusLabel = when (state) {
        FridaState.Idle -> "Idle"
        FridaState.Starting -> "Starting…"
        is FridaState.Running -> "Running"
        is FridaState.Error -> "Error"
    }

    Card(modifier = Modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.Circle,
                        contentDescription = "Status",
                        tint = statusColor,
                        modifier = Modifier.size(12.dp)
                    )
                    Text(
                        text = "frida-server — $statusLabel",
                        style = MaterialTheme.typography.titleSmall
                    )
                }
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    if (state is FridaState.Running) {
                        OutlinedButton(onClick = onRefresh) { Text("Refresh") }
                        Button(
                            onClick = onStop,
                            colors = ButtonDefaults.buttonColors(
                                containerColor = MaterialTheme.colorScheme.error
                            )
                        ) { Text("Stop") }
                    } else {
                        Button(
                            onClick = onStart,
                            enabled = state !is FridaState.Starting
                        ) { Text("Start") }
                    }
                }
            }
        }
    }
}

@Composable
private fun ProcessRow(process: FridaProcess, onAttach: () -> Unit) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 12.dp, vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = process.name,
                    style = MaterialTheme.typography.bodyMedium
                )
                Text(
                    text = "PID ${process.pid}",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            OutlinedButton(onClick = onAttach) {
                Text("Attach", style = MaterialTheme.typography.labelMedium)
            }
        }
    }
}
