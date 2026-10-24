package com.devtools.android.modules.network

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Slider
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.devtools.android.ui.components.ErrorCard

private const val DEFAULT_HOST = "192.168.1.1"
private const val DEFAULT_START_PORT = "1"
private const val DEFAULT_END_PORT = "1024"
private const val TIMEOUT_MIN = 50f
private const val TIMEOUT_MAX = 2000f
private const val TIMEOUT_DEFAULT = 500f

@Composable
fun PortScannerScreen(
    vm: PortScannerViewModel = viewModel(
        factory = PortScannerViewModel.Factory(LocalContext.current)
    )
) {
    val state by vm.state.collectAsState()

    var host by rememberSaveable { mutableStateOf(DEFAULT_HOST) }
    var startPort by rememberSaveable { mutableStateOf(DEFAULT_START_PORT) }
    var endPort by rememberSaveable { mutableStateOf(DEFAULT_END_PORT) }
    var timeoutSlider by rememberSaveable { mutableFloatStateOf(TIMEOUT_DEFAULT) }

    val isScanning = state is PortScanState.Scanning

    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 16.dp),
    ) {
        item {
            Spacer(modifier = Modifier.height(16.dp))
            OutlinedTextField(
                value = host,
                onValueChange = { host = it },
                label = { Text("Host / IP") },
                singleLine = true,
                modifier = Modifier.fillMaxWidth(),
                enabled = !isScanning,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Uri),
            )
        }

        item {
            Spacer(modifier = Modifier.height(8.dp))
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                OutlinedTextField(
                    value = startPort,
                    onValueChange = { startPort = it.filter(Char::isDigit) },
                    label = { Text("Start Port") },
                    singleLine = true,
                    modifier = Modifier.weight(1f),
                    enabled = !isScanning,
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                )
                OutlinedTextField(
                    value = endPort,
                    onValueChange = { endPort = it.filter(Char::isDigit) },
                    label = { Text("End Port") },
                    singleLine = true,
                    modifier = Modifier.weight(1f),
                    enabled = !isScanning,
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                )
            }
        }

        item {
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = "Timeout: ${timeoutSlider.toInt()} ms",
                style = MaterialTheme.typography.bodyMedium,
            )
            Slider(
                value = timeoutSlider,
                onValueChange = { timeoutSlider = it },
                valueRange = TIMEOUT_MIN..TIMEOUT_MAX,
                enabled = !isScanning,
            )
        }

        item {
            Spacer(modifier = Modifier.height(8.dp))
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                if (isScanning) {
                    OutlinedButton(
                        onClick = { vm.cancel() },
                        colors = ButtonDefaults.outlinedButtonColors(
                            contentColor = MaterialTheme.colorScheme.error
                        ),
                        modifier = Modifier.weight(1f),
                    ) {
                        Text("Cancel")
                    }
                } else {
                    Button(
                        onClick = {
                            val s = startPort.toIntOrNull() ?: 1
                            val e = endPort.toIntOrNull() ?: 1024
                            if (s in 1..65535 && e in s..65535 && host.isNotBlank()) {
                                vm.scan(host.trim(), s..e, timeoutSlider.toInt())
                            }
                        },
                        modifier = Modifier.weight(1f),
                    ) {
                        Text("Start Scan")
                    }
                    if (state !is PortScanState.Idle) {
                        OutlinedButton(
                            onClick = { vm.reset() },
                            modifier = Modifier.weight(1f),
                        ) {
                            Text("Reset")
                        }
                    }
                }
            }
        }

        // Progress
        if (isScanning) {
            item {
                Spacer(modifier = Modifier.height(12.dp))
                val scanning = state as PortScanState.Scanning
                LinearProgressIndicator(
                    progress = { scanning.progress },
                    modifier = Modifier.fillMaxWidth(),
                )
                Text(
                    text = "${(scanning.progress * 100).toInt()}%  —  ${scanning.openPorts.size} open port(s) found so far",
                    style = MaterialTheme.typography.bodySmall,
                    modifier = Modifier.padding(top = 4.dp),
                )
            }
        }

        // Error
        if (state is PortScanState.Error) {
            item {
                Spacer(modifier = Modifier.height(8.dp))
                ErrorCard(message = (state as PortScanState.Error).message)
            }
        }

        // Results
        val openPorts: List<Int>? = when (val s = state) {
            is PortScanState.Done -> s.openPorts
            is PortScanState.Scanning -> s.openPorts.takeIf { it.isNotEmpty() }
            else -> null
        }
        if (openPorts != null) {
            item {
                Spacer(modifier = Modifier.height(16.dp))
                Text(
                    text = "Open Ports",
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.padding(bottom = 4.dp),
                )
                HorizontalDivider()
            }
            if (openPorts.isEmpty()) {
                item {
                    Text(
                        text = "No open ports found yet",
                        style = MaterialTheme.typography.bodyMedium,
                        modifier = Modifier.padding(vertical = 8.dp),
                    )
                }
            } else {
                items(openPorts) { port ->
                    Card(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 2.dp),
                    ) {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(horizontal = 16.dp, vertical = 8.dp),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Text(
                                text = "Port $port",
                                fontWeight = FontWeight.Medium,
                            )
                            Text(
                                text = commonPortName(port),
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                            )
                        }
                    }
                }
            }
        }

        if (state is PortScanState.Done) {
            item {
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = "Scan complete — ${(state as PortScanState.Done).openPorts.size} open port(s)",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        }

        item { Spacer(modifier = Modifier.height(16.dp)) }
    }
}

/** Returns a human-readable service name for well-known ports. */
private fun commonPortName(port: Int): String = when (port) {
    21 -> "FTP"
    22 -> "SSH"
    23 -> "Telnet"
    25 -> "SMTP"
    53 -> "DNS"
    80 -> "HTTP"
    110 -> "POP3"
    143 -> "IMAP"
    443 -> "HTTPS"
    445 -> "SMB"
    3306 -> "MySQL"
    3389 -> "RDP"
    5432 -> "PostgreSQL"
    6379 -> "Redis"
    8080 -> "HTTP-alt"
    8443 -> "HTTPS-alt"
    27017 -> "MongoDB"
    else -> ""
}
