package com.devtools.android.modules.apktools

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ContentCopy
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ListItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.ClipboardManager
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.compose.ui.platform.LocalContext
import com.devtools.android.ui.components.ErrorCard

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ApkAnalyzerScreen(
    vm: ApkAnalyzerViewModel = viewModel(
        factory = ApkAnalyzerViewModel.Factory(LocalContext.current)
    )
) {
    val apps by vm.filteredApps.collectAsState()
    val analyzerState by vm.analyzerState.collectAsState()

    var query by rememberSaveable { mutableStateOf("") }
    var selectedApp by rememberSaveable { mutableStateOf<AppInfo?>(null) }
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    val clipboard: ClipboardManager = LocalClipboardManager.current

    Column(modifier = Modifier.fillMaxSize()) {
        OutlinedTextField(
            value = query,
            onValueChange = {
                query = it
                vm.filterBy(it)
            },
            label = { Text("Search apps or packages") },
            singleLine = true,
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 12.dp, vertical = 8.dp)
        )

        when (analyzerState) {
            is ApkAnalyzerState.Loading -> {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    CircularProgressIndicator()
                }
            }
            is ApkAnalyzerState.Error -> {
                ErrorCard(message = (analyzerState as ApkAnalyzerState.Error).message)
            }
            is ApkAnalyzerState.Ready -> {
                if (apps.isEmpty()) {
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = "No apps found",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                } else {
                    LazyColumn(modifier = Modifier.fillMaxSize()) {
                        items(apps, key = { it.packageName }) { app ->
                            ListItem(
                                headlineContent = { Text(app.appName, fontWeight = FontWeight.Medium) },
                                supportingContent = { Text(app.packageName) },
                                trailingContent = {
                                    Text(
                                        text = "${app.apkSizeKb} KB",
                                        style = MaterialTheme.typography.labelSmall,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                },
                                modifier = Modifier.clickable { selectedApp = app }
                            )
                            HorizontalDivider()
                        }
                    }
                }
            }
        }
    }

    // Detail bottom sheet
    if (selectedApp != null) {
        ModalBottomSheet(
            onDismissRequest = { selectedApp = null },
            sheetState = sheetState
        ) {
            val app = selectedApp!!
            AppDetailSheet(
                app = app,
                onCopyApkPath = {
                    clipboard.setText(AnnotatedString(app.apkPath))
                }
            )
        }
    }
}

@Composable
private fun AppDetailSheet(app: AppInfo, onCopyApkPath: () -> Unit) {
    LazyColumn(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp)
    ) {
        item {
            Text(
                text = app.appName,
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold
            )
            Text(
                text = app.packageName,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Spacer(modifier = Modifier.height(16.dp))
        }

        item { DetailSectionHeader("Version") }
        item { DetailRow(label = "Version Name", value = app.versionName) }
        item { DetailRow(label = "Version Code", value = app.versionCode.toString()) }

        item { DetailSectionHeader("SDK") }
        item { DetailRow(label = "Min SDK", value = app.minSdk.toString()) }
        item { DetailRow(label = "Target SDK", value = app.targetSdk.toString()) }

        item { DetailSectionHeader("APK") }
        item {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = "APK Path",
                        style = MaterialTheme.typography.labelMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Text(
                        text = app.apkPath,
                        style = MaterialTheme.typography.bodySmall
                    )
                }
                IconButton(onClick = onCopyApkPath) {
                    Icon(Icons.Default.ContentCopy, contentDescription = "Copy APK path")
                }
            }
        }
        item { DetailRow(label = "APK Size", value = "${app.apkSizeKb} KB") }

        if (app.permissions.isNotEmpty()) {
            item { DetailSectionHeader("Permissions (${app.permissions.size})") }
            items(app.permissions.sorted()) { perm ->
                Text(
                    text = perm.substringAfterLast('.'),
                    style = MaterialTheme.typography.bodySmall,
                    modifier = Modifier.padding(vertical = 2.dp)
                )
            }
        }

        if (app.activities.isNotEmpty()) {
            item { DetailSectionHeader("Activities (${app.activities.size})") }
            items(app.activities) { activity ->
                Text(
                    text = activity.substringAfterLast('.'),
                    style = MaterialTheme.typography.bodySmall,
                    modifier = Modifier.padding(vertical = 2.dp)
                )
            }
        }

        if (app.services.isNotEmpty()) {
            item { DetailSectionHeader("Services (${app.services.size})") }
            items(app.services) { service ->
                Text(
                    text = service.substringAfterLast('.'),
                    style = MaterialTheme.typography.bodySmall,
                    modifier = Modifier.padding(vertical = 2.dp)
                )
            }
        }

        item { Spacer(modifier = Modifier.height(32.dp)) }
    }
}

@Composable
private fun DetailSectionHeader(title: String) {
    Column {
        Spacer(modifier = Modifier.height(12.dp))
        Text(
            text = title,
            style = MaterialTheme.typography.titleSmall,
            fontWeight = FontWeight.Bold,
            color = MaterialTheme.colorScheme.primary
        )
        HorizontalDivider()
        Spacer(modifier = Modifier.height(4.dp))
    }
}

@Composable
private fun DetailRow(label: String, value: String) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(
            text = label,
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Text(
            text = value,
            style = MaterialTheme.typography.bodyMedium
        )
    }
}
