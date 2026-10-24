package com.devtools.android.modules.logcat

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
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
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Clear
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Save
import androidx.compose.material.icons.filled.Stop
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.devtools.android.ui.components.ErrorCard

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun LogcatScreen(
    vm: LogcatViewModel = viewModel()
) {
    val lines by vm.lines.collectAsState()
    val state by vm.state.collectAsState()
    val context = LocalContext.current

    var filter by rememberSaveable { mutableStateOf("") }
    val listState = rememberLazyListState()

    // Auto-scroll to bottom on new lines when running
    LaunchedEffect(lines.size) {
        if (lines.isNotEmpty() && state is LogcatState.Running) {
            listState.animateScrollToItem(lines.size - 1)
        }
    }

    Scaffold(
        floatingActionButton = {
            Row(verticalAlignment = Alignment.CenterVertically) {
                // Clear button
                FloatingActionButton(
                    onClick = { vm.clear() },
                    containerColor = MaterialTheme.colorScheme.secondaryContainer
                ) {
                    Icon(Icons.Default.Clear, contentDescription = "Clear logs")
                }
                Spacer(modifier = Modifier.width(8.dp))
                // Save button
                FloatingActionButton(
                    onClick = { vm.saveToFile(context) },
                    containerColor = MaterialTheme.colorScheme.tertiaryContainer
                ) {
                    Icon(Icons.Default.Save, contentDescription = "Save logs")
                }
                Spacer(modifier = Modifier.width(8.dp))
                // Start / Stop button
                FloatingActionButton(
                    onClick = {
                        if (state is LogcatState.Running) {
                            vm.stopCapture()
                        } else {
                            vm.startCapture(filter)
                        }
                    }
                ) {
                    if (state is LogcatState.Running) {
                        Icon(Icons.Default.Stop, contentDescription = "Stop capture")
                    } else {
                        Icon(Icons.Default.PlayArrow, contentDescription = "Start capture")
                    }
                }
            }
        }
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
        ) {
            // Filter field
            OutlinedTextField(
                value = filter,
                onValueChange = { filter = it },
                label = { Text("Filter (e.g. *:E or MyTag:D)") },
                singleLine = true,
                keyboardOptions = KeyboardOptions(imeAction = ImeAction.Done),
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 12.dp, vertical = 8.dp)
            )

            // Permission denied notice
            if (state is LogcatState.PermissionDenied) {
                ErrorCard(
                    message = "Logcat permission denied. Grant READ_LOGS via ADB:\n" +
                            "adb shell pm grant com.devtools.android android.permission.READ_LOGS",
                    onRetry = { vm.startCapture(filter) }
                )
            }

            // Log lines
            if (lines.isEmpty()) {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(16.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = if (state is LogcatState.Running) "Waiting for log output…"
                        else "Press ▶ to start capture",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            } else {
                LazyColumn(
                    state = listState,
                    modifier = Modifier
                        .fillMaxSize()
                        .background(MaterialTheme.colorScheme.surface)
                ) {
                    items(lines) { line ->
                        LogLineRow(line)
                    }
                }
            }
        }
    }
}

@Composable
private fun LogLineRow(line: LogLine) {
    val color = when (line.level) {
        LogLevel.ERROR   -> MaterialTheme.colorScheme.error
        LogLevel.WARN    -> Color(0xFFE6AC00) // amber
        LogLevel.INFO    -> Color(0xFF4CAF50) // green
        LogLevel.DEBUG   -> Color(0xFF00BCD4) // cyan
        LogLevel.VERBOSE -> MaterialTheme.colorScheme.onSurface
    }

    Text(
        text = buildString {
            if (line.timestamp.isNotEmpty()) append("${line.timestamp} ")
            if (line.tag.isNotEmpty()) append("[${line.tag}] ")
            append(line.message)
        },
        style = TextStyle(
            fontFamily = FontFamily.Monospace,
            fontSize = 11.sp,
            color = color
        ),
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 8.dp, vertical = 1.dp)
    )
}
