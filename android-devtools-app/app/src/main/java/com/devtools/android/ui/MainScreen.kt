package com.devtools.android.ui

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Badge
import androidx.compose.material3.BadgedBox
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.devtools.android.ui.navigation.Screen
import com.devtools.android.ui.system.SystemScreen

@Composable
fun MainScreen(isRooted: Boolean) {
    val navController = rememberNavController()
    val screens = listOf(
        Screen.System,
        Screen.Network,
        Screen.Security,
        Screen.ApkLogs,
        Screen.Tools
    )

    Scaffold(
        bottomBar = {
            NavigationBar {
                val navBackStackEntry by navController.currentBackStackEntryAsState()
                val currentDestination = navBackStackEntry?.destination

                screens.forEach { screen ->
                    val selected = currentDestination?.hierarchy?.any {
                        it.route == screen.route
                    } == true

                    NavigationBarItem(
                        icon = {
                            if (screen is Screen.Security && !isRooted) {
                                BadgedBox(
                                    badge = { Badge() }
                                ) {
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
    ) { innerPadding ->
        NavHost(
            navController = navController,
            startDestination = Screen.System.route,
            modifier = Modifier.padding(innerPadding)
        ) {
            composable(Screen.System.route) {
                SystemScreen()
            }
            screens.filter { it != Screen.System }.forEach { screen ->
                composable(screen.route) {
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(text = "Coming soon — ${screen.label}")
                    }
                }
            }
        }
    }
}
