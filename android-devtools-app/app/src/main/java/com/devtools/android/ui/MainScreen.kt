package com.devtools.android.ui

import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Settings
import androidx.compose.ui.graphics.Color
import androidx.compose.material3.AssistChip
import androidx.compose.material3.AssistChipDefaults
import androidx.compose.material3.Badge
import androidx.compose.material3.BadgedBox
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.devtools.android.ui.apklogs.ApkLogsScreen
import com.devtools.android.ui.navigation.Screen
import com.devtools.android.ui.network.NetworkScreen
import com.devtools.android.ui.security.SecurityScreen
import com.devtools.android.ui.settings.SettingsScreen
import com.devtools.android.ui.system.SystemScreen
import com.devtools.android.ui.tools.ToolsScreen

private const val SETTINGS_ROUTE = "settings"

/**
 * Root composable that hosts the 5-tab bottom navigation and an optional settings screen.
 *
 * The [TopAppBar] shows:
 * - A green "Rooted" chip or grey "No Root" chip reflecting device root state.
 * - A settings gear icon that navigates to [SettingsScreen].
 *
 * While on the settings screen the top bar switches to a back-arrow bar and the
 * bottom navigation bar is hidden.
 *
 * @param isRooted      Whether the device is rooted (from [com.devtools.android.core.RootDetector]).
 * @param currentTheme  Active theme key passed through to [SettingsScreen].
 * @param onThemeChange Writes the chosen theme key to DataStore (handled in MainActivity).
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MainScreen(
    isRooted: Boolean,
    currentTheme: String,
    onThemeChange: (String) -> Unit
) {
    val navController = rememberNavController()
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentRoute = navBackStackEntry?.destination?.route
    val isOnSettings = currentRoute == SETTINGS_ROUTE

    val screens = listOf(
        Screen.System,
        Screen.Network,
        Screen.Security,
        Screen.ApkLogs,
        Screen.Tools
    )

    Scaffold(
        topBar = {
            if (isOnSettings) {
                TopAppBar(
                    title = { Text("Settings") },
                    navigationIcon = {
                        IconButton(onClick = { navController.popBackStack() }) {
                            Icon(
                                imageVector = Icons.Default.ArrowBack,
                                contentDescription = "Back"
                            )
                        }
                    }
                )
            } else {
                val rootChipColor = if (isRooted) Color(0xFF4CAF50)
                                    else MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f)
                TopAppBar(
                    title = { Text("DevTools") },
                    actions = {
                        AssistChip(
                            onClick = {},
                            label = { Text(if (isRooted) "Rooted" else "No Root") },
                            modifier = Modifier.padding(end = 4.dp),
                            colors = AssistChipDefaults.assistChipColors(
                                containerColor = rootChipColor.copy(alpha = 0.15f),
                                labelColor = rootChipColor
                            )
                        )
                        IconButton(onClick = { navController.navigate(SETTINGS_ROUTE) }) {
                            Icon(
                                imageVector = Icons.Default.Settings,
                                contentDescription = "Settings"
                            )
                        }
                    }
                )
            }
        },
        bottomBar = {
            if (!isOnSettings) {
                NavigationBar {
                    val currentDestination = navBackStackEntry?.destination
                    screens.forEach { screen ->
                        val selected = currentDestination?.hierarchy?.any {
                            it.route == screen.route
                        } == true

                        NavigationBarItem(
                            icon = {
                                if (screen is Screen.Security && !isRooted) {
                                    // Lock badge on Security tab when not rooted
                                    BadgedBox(badge = {
                                        Badge {
                                            Icon(
                                                imageVector = Icons.Default.Lock,
                                                contentDescription = "Requires root",
                                                modifier = Modifier.size(8.dp)
                                            )
                                        }
                                    }) {
                                        Icon(
                                            imageVector = screen.icon,
                                            contentDescription = screen.label
                                        )
                                    }
                                } else {
                                    Icon(
                                        imageVector = screen.icon,
                                        contentDescription = screen.label
                                    )
                                }
                            },
                            label = { Text(screen.label) },
                            selected = selected,
                            onClick = {
                                navController.navigate(screen.route) {
                                    popUpTo(navController.graph.findStartDestination().id) {
                                        saveState = true
                                    }
                                    launchSingleTop = true
                                    restoreState = true
                                }
                            }
                        )
                    }
                }
            }
        }
    ) { innerPadding ->
        NavHost(
            navController = navController,
            startDestination = Screen.System.route,
            modifier = Modifier.padding(innerPadding)
        ) {
            composable(Screen.System.route) { SystemScreen() }
            composable(Screen.Network.route) { NetworkScreen() }
            composable(Screen.Security.route) { SecurityScreen(isRooted = isRooted) }
            composable(Screen.ApkLogs.route) { ApkLogsScreen() }
            composable(Screen.Tools.route) { ToolsScreen() }
            composable(SETTINGS_ROUTE) {
                SettingsScreen(
                    currentTheme = currentTheme,
                    onThemeChange = onThemeChange
                )
            }
        }
    }
}
