package com.devtools.android.modules.ssh

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
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.compose.ui.platform.LocalContext
import com.devtools.android.ui.components.ErrorCard

@Composable
fun SshClientScreen(
    vm: SshClientViewModel = viewModel(
        factory = SshClientViewModel.Factory(LocalContext.current)
    )
) {
    val state by vm.state.collectAsState()
    val commandOutput by vm.commandOutput.collectAsState()
    val lastProfile by vm.lastProfile.collectAsState()

    var host by rememberSaveable { mutableStateOf("") }
    var port by rememberSaveable { mutableStateOf("22") }
    var username by rememberSaveable { mutableStateOf("") }
    var password by rememberSaveable { mutableStateOf("") }
    var useKeyAuth by rememberSaveable { mutableStateOf(false) }
    var keyPath by rememberSaveable { mutableStateOf("") }
    var commandInput by rememberSaveable { mutableStateOf("") }

    val isConnected = state is SshState.Connected
    val isConnecting = state is SshState.Connecting
    val listState = rememberLazyListState()

    // Populate fields from last saved profile on first load
    LaunchedEffect(lastProfile) {
        lastProfile?.let { profile ->
            if (host.isBlank()) host = profile.host
            if (port == "22") port = profile.port.toString()
            if (username.isBlank()) username = profile.username
        }
    }

    LaunchedEffect(commandOutput.size) {
        if (commandOutput.isNotEmpty()) {
            listState.animateScrollToItem(commandOutput.size - 1)
        }
    }

    Column(modifier = Modifier.fillMaxSize()) {
        LazyColumn(
            state = listState,
            modifier = Modifier
                .weight(1f)
                .fillMaxWidth()
                .padding(horizontal = 16.dp)
        ) {
            item {
                Spacer(modifier = Modifier.height(16.dp))

                OutlinedTextField(
                    value = host,
                    onValueChange = { host = it },
                    label = { Text("Host") },
                    singleLine = true,
                    enabled = !isConnected && !isConnecting,
                    modifier = Modifier.fillMaxWidth(),
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Uri)
                )

                Spacer(modifier = Modifier.height(8.dp))

                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    OutlinedTextField(
                        value = port,
                        onValueChange = { port = it.filter(Char::isDigit) },
                        label = { Text("Port") },
                        singleLine = true,
                        enabled = !isConnected && !isConnecting,
                        modifier = Modifier.weight(1f),
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number)
                    )
                    OutlinedTextField(
                        value = username,
                        onValueChange = { username = it },
                        label = { Text("Username") },
                        singleLine = true,
                        enabled = !isConnected && !isConnecting,
                        modifier = Modifier.weight(2f)
                    )
                }

                Spacer(modifier = Modifier.height(8.dp))

                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Text("Password", style = MaterialTheme.typography.bodyMedium)
                    Switch(
                        checked = useKeyAuth,
                        onCheckedChange = { useKeyAuth = it },
                        enabled = !isConnected && !isConnecting
                    )
                    Text("Key Auth", style = MaterialTheme.typography.bodyMedium)
                }

                Spacer(modifier = Modifier.height(8.dp))

                if (useKeyAuth) {
                    OutlinedTextField(
                        value = keyPath,
                        onValueChange = { keyPath = it },
                        label = { Text("Private Key Path") },
                        singleLine = true,
                        enabled = !isConnected && !isConnecting,
                        modifier = Modifier.fillMaxWidth()
                    )
                } else {
                    OutlinedTextField(
                        value = password,
                        onValueChange = { password = it },
                        label = { Text("Password") },
                        singleLine = true,
                        enabled = !isConnected && !isConnecting,
                        visualTransformation = PasswordVisualTransformation(),
                        modifier = Modifier.fillMaxWidth()
                    )
                }

                Spacer(modifier = Modifier.height(12.dp))

                Button(
                    onClick = {
                        if (isConnected) {
                            vm.disconnect()
                        } else {
                            val authMethod: SshAuthMethod = if (useKeyAuth) {
                                SshAuthMethod.KeyPath(keyPath.trim())
                            } else {
                                SshAuthMethod.Password(password)
                            }
                            vm.connect(
                                SshProfile(
                                    host = host.trim(),
                                    port = port.toIntOrNull() ?: 22,
                                    username = username.trim(),
                                    authMethod = authMethod
                                )
                            )
                        }
                    },
                    enabled = !isConnecting,
                    modifier = Modifier.fillMaxWidth(),
                    colors = if (isConnected) {
                        ButtonDefaults.buttonColors(
                            containerColor = MaterialTheme.colorScheme.error
                        )
                    } else {
                        ButtonDefaults.buttonColors()
                    }
                ) {
                    when {
                        isConnecting -> {
                            CircularProgressIndicator(
                                modifier = Modifier.size(16.dp),
                                strokeWidth = 2.dp,
                                color = MaterialTheme.colorScheme.onPrimary
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text("Connecting…")
                        }
                        isConnected -> Text("Disconnect")
                        else -> Text("Connect")
                    }
                }

                Spacer(modifier = Modifier.height(8.dp))
            }

            // Error state
            if (state is SshState.Error) {
                item {
                    ErrorCard(message = (state as SshState.Error).msg)
                    Spacer(modifier = Modifier.height(8.dp))
                }
            }

            // Terminal output
            if (commandOutput.isNotEmpty()) {
                item {
                    Surface(
                        color = MaterialTheme.colorScheme.surfaceVariant,
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Column(modifier = Modifier.padding(horizontal = 8.dp, vertical = 8.dp)) {
                            commandOutput.forEach { line ->
                                Text(
                                    text = line,
                                    fontFamily = FontFamily.Monospace,
                                    style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }
                        }
                    }
                    Spacer(modifier = Modifier.height(8.dp))
                }
            }

            item { Spacer(modifier = Modifier.height(8.dp)) }
        }

        // Command input row — shown only when connected
        if (isConnected) {
            HorizontalDivider()
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 8.dp, vertical = 4.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                OutlinedTextField(
                    value = commandInput,
                    onValueChange = { commandInput = it },
                    label = { Text("Command") },
                    singleLine = true,
                    modifier = Modifier.weight(1f)
                )
                Spacer(modifier = Modifier.width(8.dp))
                Button(
                    onClick = {
                        val cmd = commandInput.trim()
                        if (cmd.isNotBlank()) {
                            commandInput = ""
                            vm.runCommand(cmd)
                        }
                    }
                ) {
                    Text("Send")
                }
            }
        }
    }
}
