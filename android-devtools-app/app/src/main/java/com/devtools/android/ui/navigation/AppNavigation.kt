package com.devtools.android.ui.navigation

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.BugReport
import androidx.compose.material.icons.filled.Build
import androidx.compose.material.icons.filled.PhoneAndroid
import androidx.compose.material.icons.filled.Security
import androidx.compose.material.icons.filled.Wifi
import androidx.compose.ui.graphics.vector.ImageVector

sealed class Screen(
    val route: String,
    val label: String,
    val icon: ImageVector
) {
    object System : Screen(
        route = "system",
        label = "System",
        icon = Icons.Default.PhoneAndroid
    )

    object Network : Screen(
        route = "network",
        label = "Network",
        icon = Icons.Default.Wifi
    )

    object Security : Screen(
        route = "security",
        label = "Security",
        icon = Icons.Default.Security
    )

    object ApkLogs : Screen(
        route = "apk_logs",
        label = "APK & Logs",
        icon = Icons.Default.BugReport
    )

    object Tools : Screen(
        route = "tools",
        label = "Tools",
        icon = Icons.Default.Build
    )
}
