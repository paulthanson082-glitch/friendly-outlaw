package com.devtools.android.modules.files

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Folder
import androidx.compose.material.icons.filled.InsertDriveFile
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Badge
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ListItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.devtools.android.core.RootDetector
import com.devtools.android.ui.components.ErrorCard
import kotlinx.coroutines.launch
import java.io.File

@OptIn(ExperimentalFoundationApi::class)
@Composable
fun FileBrowserScreen(vm: FileBrowserViewModel = viewModel()) {
    val entries by vm.entries.collectAsState()
    val currentPath by vm.currentPath.collectAsState()
    val error by vm.error.collectAsState()
    val scope = rememberCoroutineScope()
    val clipboardManager = LocalClipboardManager.current

    var selectedEntry by remember { mutableStateOf<FileEntry?>(null) }
    var showActionSheet by remember { mutableStateOf(false) }
    var checksumResult by remember { mutableStateOf<String?>(null) }
    var fileTextContent by remember { mutableStateOf<String?>(null) }

    // Action sheet
    if (showActionSheet && selectedEntry != null) {
        val entry = selectedEntry!!
        AlertDialog(
            onDismissRequest = {
                showActionSheet = false
                checksumResult = null
                fileTextContent = null
            },
            title = { Text(entry.name, maxLines = 1) },
            text = {
                Column {
                    checksumResult?.let { cs ->
                        Text(
                            text = cs,
                            style = MaterialTheme.typography.bodySmall,
                            fontFamily = FontFamily.Monospace
                        )
                    }
                    fileTextContent?.let { txt ->
                        Text(
                            text = txt,
                            style = MaterialTheme.typography.bodySmall,
                            fontFamily = FontFamily.Monospace
                        )
                    }
                }
            },
            confirmButton = {
                Column {
                    TextButton(onClick = {
                        clipboardManager.setText(AnnotatedString(entry.path))
                        showActionSheet = false
                    }) { Text("Copy Path") }

                    if (!entry.isDir) {
                        TextButton(onClick = {
                            checksumResult = "Computing md5…"
                            scope.launch {
                                vm.checksum(entry.path, "md5").collect { result ->
                                    checksumResult = result
                                }
                            }
                        }) { Text("MD5 Checksum") }

                        TextButton(onClick = {
                            scope.launch {
                                try {
                                    fileTextContent = File(entry.path).readText().take(4096)
                                } catch (e: Exception) {
                                    fileTextContent = "Error: ${e.message}"
                                }
                            }
                        }) { Text("View as Text") }
                    }

                    TextButton(onClick = {
                        showActionSheet = false
                        checksumResult = null
                        fileTextContent = null
                    }) { Text("Close") }
                }
            },
            dismissButton = null
        )
    }

    Column(modifier = Modifier.fillMaxSize()) {
        // Breadcrumb path bar
        Surface(
            color = MaterialTheme.colorScheme.surfaceVariant,
            modifier = Modifier.fillMaxWidth()
        ) {
            Row(
                modifier = Modifier.padding(horizontal = 4.dp, vertical = 2.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                IconButton(
                    onClick = { vm.navigateUp() },
                    modifier = Modifier.size(36.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.ArrowBack,
                        contentDescription = "Navigate up"
                    )
                }

                val scrollState = rememberScrollState()
                Row(
                    modifier = Modifier
                        .weight(1f)
                        .horizontalScroll(scrollState),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    val segments = currentPath.split("/").filter { it.isNotEmpty() }
                    TextButton(
                        onClick = { vm.navigate("/") },
                        contentPadding = PaddingValues(horizontal = 4.dp)
                    ) {
                        Text("/", style = MaterialTheme.typography.bodySmall)
                    }
                    segments.forEachIndexed { i, segment ->
                        val segPath = "/" + segments.take(i + 1).joinToString("/")
                        Text(
                            text = ">",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        TextButton(
                            onClick = { vm.navigate(segPath) },
                            contentPadding = PaddingValues(horizontal = 4.dp)
                        ) {
                            Text(segment, style = MaterialTheme.typography.bodySmall)
                        }
                    }
                }

                if (RootDetector.isRooted) {
                    Badge(modifier = Modifier.padding(end = 8.dp)) {
                        Text("ROOT", style = MaterialTheme.typography.labelSmall)
                    }
                }
            }
        }

        // Error
        error?.let { msg ->
            ErrorCard(message = msg, onRetry = { vm.navigate(currentPath) })
        }

        // Empty state
        if (entries.isEmpty() && error == null) {
            Box(
                modifier = Modifier.fillMaxSize(),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "Empty directory",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }

        // File list
        LazyColumn(modifier = Modifier.fillMaxSize()) {
            items(entries, key = { it.path }) { entry ->
                ListItem(
                    headlineContent = {
                        Text(text = entry.name)
                    },
                    supportingContent = {
                        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            Text(
                                text = entry.permissions,
                                style = MaterialTheme.typography.bodySmall,
                                fontFamily = FontFamily.Monospace,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                            if (!entry.isDir) {
                                Text(
                                    text = formatSize(entry.sizeBytes),
                                    style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }
                        }
                    },
                    leadingContent = {
                        Icon(
                            imageVector = if (entry.isDir) Icons.Default.Folder else Icons.Default.InsertDriveFile,
                            contentDescription = if (entry.isDir) "Folder" else "File",
                            tint = if (entry.isDir) MaterialTheme.colorScheme.primary
                            else MaterialTheme.colorScheme.onSurface
                        )
                    },
                    modifier = Modifier.combinedClickable(
                        onClick = {
                            if (entry.isDir) vm.navigate(entry.path)
                        },
                        onLongClick = {
                            selectedEntry = entry
                            checksumResult = null
                            fileTextContent = null
                            showActionSheet = true
                        }
                    )
                )
                HorizontalDivider()
            }
        }
    }
}

private fun formatSize(bytes: Long): String = when {
    bytes < 1_024L -> "${bytes}B"
    bytes < 1_024L * 1_024L -> "${bytes / 1_024L}KB"
    bytes < 1_024L * 1_024L * 1_024L -> "${bytes / (1_024L * 1_024L)}MB"
    else -> "${bytes / (1_024L * 1_024L * 1_024L)}GB"
}
