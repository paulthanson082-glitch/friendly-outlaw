package com.devtools.android.modules.packages

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
import androidx.compose.material.icons.filled.GetApp
import androidx.compose.material.icons.filled.Launch
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.Stop
import androidx.compose.material3.Card
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Snackbar
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.devtools.android.modules.apktools.AppInfo
import com.devtools.android.ui.components.ErrorCard
import com.devtools.android.ui.components.RootRequiredCard

@Composable
fun PackageManagerScreen(
    vm: PackageManagerViewModel = viewModel(
        factory = PackageManagerViewModel.Factory(LocalContext.current)
    )
) {
    val context = LocalContext.current
    val apps by vm.filteredApps.collectAsState()
    val pmState by vm.pmState.collectAsState()
    val operationResult by vm.operationResult.collectAsState()

    var query by rememberSaveable { mutableStateOf("") }
    val snackbarHostState = remember { SnackbarHostState() }

    // Show snackbar for operation results
    LaunchedEffect(operationResult) {
        operationResult?.let { result ->
            snackbarHostState.showSnackbar(result.message)
            vm.clearOperationResult()
        }
    }

    Box(modifier = Modifier.fillMaxSize()) {
        Column(modifier = Modifier.fillMaxSize()) {
            OutlinedTextField(
                value = query,
                onValueChange = {
                    query = it
                    vm.filterBy(it)
                },
                label = { Text("Search packages") },
                singleLine = true,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 12.dp, vertical = 8.dp)
            )

            when (pmState) {
                is PackageManagerState.Loading -> {
                    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                        CircularProgressIndicator()
                    }
                }

                is PackageManagerState.Error -> {
                    ErrorCard(message = (pmState as PackageManagerState.Error).message)
                }

                is PackageManagerState.Ready -> {
                    // Root-only section hint
                    if (!vm.isRooted) {
                        RootRequiredCard(feature = "system app uninstall")
                    }

                    if (apps.isEmpty()) {
                        Box(
                            modifier = Modifier.fillMaxSize(),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = "No packages found",
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    } else {
                        LazyColumn(modifier = Modifier.fillMaxSize()) {
                            items(apps, key = { it.packageName }) { app ->
                                PackageRow(
                                    app = app,
                                    isRooted = vm.isRooted,
                                    onLaunch = { vm.launch(app.packageName) },
                                    onSettings = { vm.openSettings(app.packageName) },
                                    onForceStop = { vm.forceStop(app.packageName) },
                                    onExtract = { vm.extractApk(app, context) },
                                    onUninstallSystem = { vm.uninstallSystem(app.packageName) }
                                )
                                HorizontalDivider()
                            }
                        }
                    }
                }
            }
        }

        SnackbarHost(
            hostState = snackbarHostState,
            modifier = Modifier.align(Alignment.BottomCenter)
        )
    }
}

@Composable
private fun PackageRow(
    app: AppInfo,
    isRooted: Boolean,
    onLaunch: () -> Unit,
    onSettings: () -> Unit,
    onForceStop: () -> Unit,
    onExtract: () -> Unit,
    onUninstallSystem: () -> Unit
) {
    Column(modifier = Modifier.fillMaxWidth()) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(start = 16.dp, top = 8.dp, end = 4.dp, bottom = 0.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = app.appName,
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.Medium
                )
                Text(
                    text = app.packageName,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Text(
                    text = "v${app.versionName} · ${app.apkSizeKb} KB",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            // Launch
            IconButton(onClick = onLaunch) {
                Icon(
                    imageVector = Icons.Default.Launch,
                    contentDescription = "Launch ${app.appName}"
                )
            }

            // Settings
            IconButton(onClick = onSettings) {
                Icon(
                    imageVector = Icons.Default.Settings,
                    contentDescription = "Open settings for ${app.appName}"
                )
            }

            // Force stop (root → direct; non-root → opens settings)
            IconButton(onClick = onForceStop) {
                Icon(
                    imageVector = Icons.Default.Stop,
                    contentDescription = "Force-stop ${app.appName}",
                    tint = MaterialTheme.colorScheme.error
                )
            }

            // Extract APK
            IconButton(onClick = onExtract) {
                Icon(
                    imageVector = Icons.Default.GetApp,
                    contentDescription = "Extract APK for ${app.appName}"
                )
            }
        }

        // Root-gated uninstall system app row
        if (isRooted) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(start = 16.dp, end = 16.dp, bottom = 4.dp),
                horizontalArrangement = Arrangement.End
            ) {
                TextButton(onClick = onUninstallSystem) {
                    Text(
                        text = "Uninstall (system)",
                        color = MaterialTheme.colorScheme.error,
                        style = MaterialTheme.typography.labelSmall
                    )
                }
            }
        }
    }
}
