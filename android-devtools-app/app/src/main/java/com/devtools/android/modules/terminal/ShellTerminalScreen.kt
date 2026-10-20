package com.devtools.android.modules.terminal

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Clear
import androidx.compose.material.icons.filled.Send
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.devtools.android.core.RootDetector

private val TERMINAL_BG = Color(0xFF1A1A1A)
private val TERMINAL_TEXT = Color(0xFF00FF00)

@Composable
fun ShellTerminalScreen(vm: ShellTerminalViewModel = viewModel()) {
    val outputLines by vm.outputLines.collectAsState()
    val isRootMode by vm.isRootMode.collectAsState()

    var commandInput by rememberSaveable { mutableStateOf("") }
    val listState = rememberLazyListState()

    // Auto-scroll to latest line
    LaunchedEffect(outputLines.size) {
        if (outputLines.isNotEmpty()) {
            listState.animateScrollToItem(outputLines.size - 1)
        }
    }

    Column(modifier = Modifier.fillMaxSize()) {
        // Root mode toolbar (only when device is rooted)
        if (RootDetector.isRooted) {
            Surface(color = MaterialTheme.colorScheme.surfaceVariant) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 4.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Text(
                            text = "Root Shell",
                            style = MaterialTheme.typography.bodyMedium,
                            color = if (isRootMode) MaterialTheme.colorScheme.error
                            else MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Switch(
                            checked = isRootMode,
                            onCheckedChange = { vm.setRootMode(it) }
                        )
                    }
                    IconButton(onClick = { vm.clearOutput() }) {
                        Icon(
                            imageVector = Icons.Default.Clear,
                            contentDescription = "Clear output"
                        )
                    }
                }
            }
            HorizontalDivider()
        }

        // Terminal output — dark background, monospace green text
        LazyColumn(
            state = listState,
            modifier = Modifier
                .weight(1f)
                .fillMaxWidth()
                .background(TERMINAL_BG)
                .padding(horizontal = 8.dp, vertical = 8.dp),
            verticalArrangement = Arrangement.spacedBy(1.dp)
        ) {
            items(outputLines) { line ->
                Text(
                    text = line,
                    fontFamily = FontFamily.Monospace,
                    style = MaterialTheme.typography.bodySmall,
                    color = TERMINAL_TEXT
                )
            }
        }

        // Command input
        HorizontalDivider()
        Surface(color = MaterialTheme.colorScheme.surface) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 8.dp, vertical = 4.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                OutlinedTextField(
                    value = commandInput,
                    onValueChange = { commandInput = it },
                    placeholder = {
                        Text(
                            text = if (isRootMode) "# Enter root command…" else "$ Enter command…",
                            style = MaterialTheme.typography.bodySmall
                        )
                    },
                    singleLine = true,
                    textStyle = MaterialTheme.typography.bodySmall.copy(
                        fontFamily = FontFamily.Monospace
                    ),
                    modifier = Modifier.weight(1f)
                )
                Spacer(modifier = Modifier.width(4.dp))
                IconButton(
                    onClick = {
                        val cmd = commandInput.trim()
                        if (cmd.isNotBlank()) {
                            vm.sendCommand(cmd)
                            commandInput = ""
                        }
                    }
                ) {
                    Icon(
                        imageVector = Icons.Default.Send,
                        contentDescription = "Send command",
                        tint = MaterialTheme.colorScheme.primary
                    )
                }
            }
        }
    }
}
